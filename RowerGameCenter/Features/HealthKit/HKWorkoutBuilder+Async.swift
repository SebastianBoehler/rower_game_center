import Foundation
import HealthKit

@MainActor
extension HKWorkoutBuilder {
    func addSamples(_ samples: [HKSample]) async throws {
        guard !samples.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(samples) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: HealthSyncError.unsuccessfulWrite)
                }
            }
        }
    }

    func addMetadataValues(_ metadata: [String: Any]) async throws {
        guard !metadata.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            addMetadata(metadata) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: HealthSyncError.unsuccessfulWrite)
                }
            }
        }
    }

    func finishWorkoutAsync() async throws -> HKWorkout {
        try await withCheckedThrowingContinuation { continuation in
            finishWorkout { workout, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let workout {
                    continuation.resume(returning: workout)
                } else {
                    continuation.resume(throwing: HealthSyncError.missingWorkout)
                }
            }
        }
    }
}
