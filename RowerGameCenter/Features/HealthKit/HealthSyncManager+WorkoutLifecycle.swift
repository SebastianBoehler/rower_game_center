import Foundation
import HealthKit

extension HealthSyncManager {
    func sync(
        metrics: RowingMetrics,
        connectedDeviceName: String?
    ) async throws {
        let sampleDate = metrics.lastUpdatedAt ?? .now

        if shouldRestartWorkout(for: metrics) {
            try await finishActiveWorkout(with: metrics, endDate: sampleDate)
        }

        if activeWorkout == nil, shouldStartWorkout(for: metrics) {
            try await startWorkout(
                with: metrics,
                connectedDeviceName: connectedDeviceName,
                sampleDate: sampleDate
            )
        }

        guard var activeWorkout else {
            syncState = .ready
            return
        }

        let samples = makeSamples(
            for: metrics,
            session: &activeWorkout,
            sampleDate: sampleDate
        )

        try await activeWorkout.builder.addSamples(samples)
        activeWorkout.lastSampleDate = sampleDate
        self.activeWorkout = activeWorkout
        errorMessage = nil
        syncState = .syncing
    }

    func finishActiveWorkout(
        with metrics: RowingMetrics,
        endDate: Date? = nil
    ) async throws {
        guard var activeWorkout else {
            syncState = authorizationState == .authorized ? .ready : .idle
            return
        }

        let sampleDate = endDate ?? metrics.lastUpdatedAt ?? .now
        let finalSamples = makeSamples(
            for: metrics,
            session: &activeWorkout,
            sampleDate: sampleDate
        )

        syncState = .saving
        try await activeWorkout.builder.addSamples(finalSamples)
        try await activeWorkout.builder.endCollection(at: sampleDate)
        _ = try await activeWorkout.builder.finishWorkoutAsync()

        lastSavedWorkout = HealthSyncedWorkoutSummary(
            endDate: sampleDate,
            energyKilocalories: Double(metrics.calories ?? Int(activeWorkout.lastEnergyKilocalories ?? 0)),
            distanceMeters: metrics.distance ?? activeWorkout.lastDistanceMeters
        )
        recapManager?.present(
            SessionRecapBuilder.workout(
                metrics: metrics,
                savedToHealth: true
            )
        )
        refreshTrainingInsights()
        self.activeWorkout = nil
        errorMessage = nil
        syncState = .saved
    }

    private func startWorkout(
        with metrics: RowingMetrics,
        connectedDeviceName: String?,
        sampleDate: Date
    ) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .rowing
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: .local()
        )

        let startDate = resolvedStartDate(for: metrics, sampleDate: sampleDate)
        let externalUUID = UUID()
        let metadata = workoutMetadata(
            externalUUID: externalUUID,
            connectedDeviceName: connectedDeviceName
        )

        try await builder.beginCollection(at: startDate)
        try await builder.addMetadataValues(metadata)

        activeWorkout = ActiveWorkoutSession(
            builder: builder,
            startDate: startDate,
            lastSampleDate: startDate,
            lastElapsedTime: metrics.elapsedTime,
            lastEnergyKilocalories: nil,
            lastDistanceMeters: nil,
            lastHeartRate: nil,
            lastHeartRateSampleDate: nil
        )

        syncState = .syncing
    }

    private func makeSamples(
        for metrics: RowingMetrics,
        session: inout ActiveWorkoutSession,
        sampleDate: Date
    ) -> [HKSample] {
        var samples: [HKSample] = []

        // PM5 values are cumulative, so HealthKit writes use deltas between snapshots.
        if let calories = metrics.calories.map(Double.init) {
            let quantity = deltaQuantity(
                current: calories,
                previous: session.lastEnergyKilocalories,
                startDate: session.lastEnergyKilocalories == nil ? session.startDate : session.lastSampleDate,
                endDate: sampleDate,
                unit: HealthKitTypes.energyUnit,
                type: HealthKitTypes.activeEnergy
            )

            if let quantity {
                samples.append(quantity)
            }

            session.lastEnergyKilocalories = calories
        }

        if let distance = metrics.distance {
            let quantity = deltaQuantity(
                current: distance,
                previous: session.lastDistanceMeters,
                startDate: session.lastDistanceMeters == nil ? session.startDate : session.lastSampleDate,
                endDate: sampleDate,
                unit: HealthKitTypes.distanceUnit,
                type: HealthKitTypes.distanceRowing
            )

            if let quantity {
                samples.append(quantity)
            }

            session.lastDistanceMeters = distance
        }

        if let heartRate = metrics.heartRate,
           shouldWriteHeartRate(
               current: heartRate,
               lastHeartRate: session.lastHeartRate,
               lastSampleDate: session.lastHeartRateSampleDate,
               sampleDate: sampleDate
           ) {
            samples.append(
                HKQuantitySample(
                    type: HealthKitTypes.heartRate,
                    quantity: HKQuantity(
                        unit: HealthKitTypes.heartRateUnit,
                        doubleValue: Double(heartRate)
                    ),
                    start: sampleDate,
                    end: sampleDate
                )
            )
            session.lastHeartRate = heartRate
            session.lastHeartRateSampleDate = sampleDate
        }

        session.lastElapsedTime = metrics.elapsedTime
        return samples
    }

    private func deltaQuantity(
        current: Double,
        previous: Double?,
        startDate: Date,
        endDate: Date,
        unit: HKUnit,
        type: HKQuantityType
    ) -> HKQuantitySample? {
        let delta = current - (previous ?? 0)
        guard delta > 0, endDate >= startDate else { return nil }

        return HKQuantitySample(
            type: type,
            quantity: HKQuantity(unit: unit, doubleValue: delta),
            start: startDate,
            end: endDate
        )
    }

    private func shouldWriteHeartRate(
        current: Int,
        lastHeartRate: Int?,
        lastSampleDate: Date?,
        sampleDate: Date
    ) -> Bool {
        if lastHeartRate == nil {
            return true
        }

        if current != lastHeartRate {
            return true
        }

        return sampleDate.timeIntervalSince(lastSampleDate ?? .distantPast) >= 15
    }

    private func shouldStartWorkout(for metrics: RowingMetrics) -> Bool {
        metrics.elapsedTime != nil
            || metrics.distance != nil
            || metrics.calories != nil
            || metrics.strokeCount != nil
            || metrics.powerWatts != nil
    }

    private func shouldRestartWorkout(for metrics: RowingMetrics) -> Bool {
        guard let activeWorkout else { return false }

        if let elapsedTime = metrics.elapsedTime,
           let previousElapsedTime = activeWorkout.lastElapsedTime,
           elapsedTime + 5 < previousElapsedTime {
            return true
        }

        if let distance = metrics.distance,
           let previousDistance = activeWorkout.lastDistanceMeters,
           distance + 1 < previousDistance {
            return true
        }

        if let calories = metrics.calories.map(Double.init),
           let previousCalories = activeWorkout.lastEnergyKilocalories,
           calories + 1 < previousCalories {
            return true
        }

        return false
    }

    private func resolvedStartDate(for metrics: RowingMetrics, sampleDate: Date) -> Date {
        guard let elapsedTime = metrics.elapsedTime, elapsedTime > 0 else {
            return sampleDate
        }

        return sampleDate.addingTimeInterval(-elapsedTime)
    }

    private func workoutMetadata(
        externalUUID: UUID,
        connectedDeviceName: String?
    ) -> [String: Any] {
        var metadata: [String: Any] = [
            HKMetadataKeyIndoorWorkout: true,
            HKMetadataKeyExternalUUID: externalUUID.uuidString,
        ]

        if let connectedDeviceName {
            metadata["RowerGameCenterDeviceName"] = connectedDeviceName
        }

        return metadata
    }
}
