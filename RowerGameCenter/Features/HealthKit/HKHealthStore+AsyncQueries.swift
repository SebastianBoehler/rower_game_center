import HealthKit

extension HKHealthStore {
    func fetchRowingWorkouts(
        limit: Int = HKObjectQueryNoLimit,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [HKWorkout] {
        let sortDescriptors = [
            NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false),
        ]
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .rowing)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: []
        )
        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [workoutPredicate, datePredicate]
        )

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
                }
            }

            execute(query)
        }
    }

    func fetchRecentRowingWorkouts(limit: Int) async throws -> [HKWorkout] {
        try await fetchRowingWorkouts(limit: limit)
    }
}
