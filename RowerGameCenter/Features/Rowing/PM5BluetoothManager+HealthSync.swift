import Foundation

extension PM5BluetoothManager {
    func syncHealthMetricsIfNeeded() {
        healthSyncManager?.enqueueMetrics(metrics, connectedDeviceName: connectedDeviceName)
        scheduleHealthWorkoutAutoFinishIfNeeded()
    }

    func finishHealthWorkoutIfNeeded() {
        cancelHealthWorkoutAutoFinish()
        healthSyncManager?.finishWorkout(with: metrics)
    }

    func cancelHealthWorkoutAutoFinish() {
        healthWorkoutInactivityTask?.cancel()
        healthWorkoutInactivityTask = nil
    }

    private func scheduleHealthWorkoutAutoFinishIfNeeded() {
        guard let healthSyncManager,
              healthSyncManager.isWorkoutActive,
              let expectedTimestamp = metrics.lastUpdatedAt else {
            cancelHealthWorkoutAutoFinish()
            return
        }

        healthWorkoutInactivityTask?.cancel()
        healthWorkoutInactivityTask = Task { [weak self, expectedTimestamp] in
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                return
            }

            self?.finishHealthWorkoutAfterInactivity(expectedTimestamp: expectedTimestamp)
        }
    }

    @MainActor
    private func finishHealthWorkoutAfterInactivity(expectedTimestamp: Date) {
        defer { healthWorkoutInactivityTask = nil }

        guard let healthSyncManager,
              healthSyncManager.isWorkoutActive,
              metrics.lastUpdatedAt == expectedTimestamp else {
            return
        }

        healthSyncManager.finishWorkout(with: metrics)
    }
}
