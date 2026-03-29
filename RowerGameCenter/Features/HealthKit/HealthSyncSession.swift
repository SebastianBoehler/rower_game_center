import Foundation
import HealthKit

enum HealthSyncEvent {
    case sync(RowingMetrics, String?)
    case finish(RowingMetrics)
}

struct ActiveWorkoutSession {
    let builder: HKWorkoutBuilder
    let startDate: Date
    var lastSampleDate: Date
    var lastElapsedTime: TimeInterval?
    var lastEnergyKilocalories: Double?
    var lastDistanceMeters: Double?
    var lastHeartRate: Int?
    var lastHeartRateSampleDate: Date?
}

extension HealthSyncManager {
    static func resolveAuthorizationState(using healthStore: HKHealthStore) -> HealthAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }

        let statuses = HealthKitTypes.authorizationTypes.map(healthStore.authorizationStatus(for:))

        if statuses.allSatisfy({ $0 == .sharingAuthorized }) {
            return .authorized
        }

        if statuses.contains(.sharingDenied) {
            return .denied
        }

        return .notDetermined
    }
}
