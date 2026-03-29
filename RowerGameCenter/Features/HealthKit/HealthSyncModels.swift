import Foundation

enum HealthAuthorizationState {
    case unavailable
    case notDetermined
    case denied
    case authorized
}

enum HealthWorkoutSyncState {
    case idle
    case requestingAuthorization
    case ready
    case syncing
    case saving
    case saved
    case failed
}

struct HealthSyncedWorkoutSummary {
    let endDate: Date
    let energyKilocalories: Double?
    let distanceMeters: Double?
}

struct HealthWorkoutSummary: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let energyKilocalories: Double?
    let distanceMeters: Double?
}

enum HealthSyncError: LocalizedError {
    case unsuccessfulWrite
    case missingWorkout

    var errorDescription: String? {
        switch self {
        case .unsuccessfulWrite:
            "Apple Health did not confirm the workout update."
        case .missingWorkout:
            "The Apple Health workout session is no longer available."
        }
    }
}
