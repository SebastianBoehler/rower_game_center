import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthSyncManager {
    var authorizationState: HealthAuthorizationState
    var syncState: HealthWorkoutSyncState = .idle
    var errorMessage: String?
    var historyErrorMessage: String?
    var lastSavedWorkout: HealthSyncedWorkoutSummary?
    var recentWorkouts: [HealthWorkoutSummary] = []
    var workoutHistory: [HealthWorkoutSummary] = []
    var trainingOverview: TrainingOverview?
    var trainingChallenges: [TrainingChallengeProgress] = []
    var trainingBadges: [TrainingBadgeStatus] = []
    var ghostBenchmarks: [TrainingBenchmark] = []
    var personalBestBoard: [TrainingLeaderboardEntry] = []
    var isLoadingRecentWorkouts = false

    @ObservationIgnored let healthStore: HKHealthStore
    @ObservationIgnored let recapManager: SessionRecapManager?
    @ObservationIgnored var activeWorkout: ActiveWorkoutSession?
    @ObservationIgnored var pendingEvents: [HealthSyncEvent] = []
    @ObservationIgnored var isProcessingQueue = false

    init(
        healthStore: HKHealthStore = HKHealthStore(),
        recapManager: SessionRecapManager? = nil
    ) {
        self.healthStore = healthStore
        self.recapManager = recapManager
        authorizationState = Self.resolveAuthorizationState(using: healthStore)
        if authorizationState == .authorized {
            syncState = .ready
        }
    }

    var canRequestAuthorization: Bool {
        authorizationState != .unavailable && syncState != .requestingAuthorization
    }

    var statusTitle: String {
        switch authorizationState {
        case .unavailable:
            "Unavailable on this device"
        case .notDetermined:
            "Health access required"
        case .denied:
            "Health access is disabled"
        case .authorized:
            switch syncState {
            case .idle, .ready:
                "Ready to sync"
            case .requestingAuthorization:
                "Requesting access"
            case .syncing:
                "Syncing current workout"
            case .saving:
                "Saving workout"
            case .saved:
                "Saved to Apple Health"
            case .failed:
                "Sync failed"
            }
        }
    }

    var statusDetail: String {
        switch authorizationState {
        case .unavailable:
            "Apple Health is not available here. Use a physical iPhone to write rowing workouts."
        case .notDetermined:
            "Allow workout, calorie, distance, and heart-rate writes so PM5 sessions can land in Apple Health."
        case .denied:
            "Re-enable Health access for Rower Game Center in the Health app to resume workout syncing."
        case .authorized:
            switch syncState {
            case .saved:
                "The latest PM5 workout was written to Apple Health with rowing distance and active calories."
            case .failed:
                errorMessage ?? "Apple Health rejected the last workout write."
            default:
                "Indoor rowing workouts now stream into Apple Health while the PM5 feed is live."
            }
        }
    }

    func requestAuthorization() {
        guard canRequestAuthorization else { return }

        syncState = .requestingAuthorization
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                try await healthStore.requestAuthorization(
                    toShare: HealthKitTypes.shareTypes,
                    read: HealthKitTypes.readTypes
                )
                refreshAuthorizationState()
                if authorizationState == .authorized {
                    syncState = .ready
                    refreshTrainingInsights()
                } else {
                    syncState = .idle
                }
            } catch {
                syncState = .failed
                errorMessage = error.localizedDescription
            }
        }
    }

    func refreshAuthorizationState() {
        authorizationState = Self.resolveAuthorizationState(using: healthStore)
    }

    func enqueueMetrics(_ metrics: RowingMetrics, connectedDeviceName: String?) {
        guard authorizationState == .authorized else { return }

        if case .sync = pendingEvents.last {
            pendingEvents[pendingEvents.count - 1] = .sync(metrics, connectedDeviceName)
        } else {
            pendingEvents.append(.sync(metrics, connectedDeviceName))
        }

        processQueueIfNeeded()
    }

    func finishWorkout(with metrics: RowingMetrics) {
        guard authorizationState == .authorized else { return }

        pendingEvents.append(.finish(metrics))
        processQueueIfNeeded()
    }

    private func processQueueIfNeeded() {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true

        Task { [weak self] in
            await self?.drainQueue()
        }
    }

    private func drainQueue() async {
        while !pendingEvents.isEmpty {
            let event = pendingEvents.removeFirst()

            do {
                switch event {
                case .sync(let metrics, let connectedDeviceName):
                    try await sync(metrics: metrics, connectedDeviceName: connectedDeviceName)
                case .finish(let metrics):
                    try await finishActiveWorkout(with: metrics)
                }
            } catch {
                activeWorkout = nil
                syncState = .failed
                errorMessage = error.localizedDescription
            }
        }

        isProcessingQueue = false
    }
}
