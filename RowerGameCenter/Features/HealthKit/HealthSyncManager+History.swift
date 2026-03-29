import HealthKit

extension HealthSyncManager {
    func refreshRecentWorkouts() {
        refreshTrainingInsights()
    }

    func refreshTrainingInsights() {
        guard authorizationState == .authorized else {
            isLoadingRecentWorkouts = false
            historyErrorMessage = nil
            recentWorkouts = []
            workoutHistory = []
            trainingOverview = nil
            trainingChallenges = []
            trainingBadges = []
            ghostBenchmarks = []
            personalBestBoard = []
            return
        }

        isLoadingRecentWorkouts = true
        historyErrorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                let workouts = try await healthStore.fetchRowingWorkouts()
                let summaries = workouts.map(Self.makeWorkoutSummary(from:))
                let overview = TrainingInsightEngine.makeOverview(from: summaries)
                let challenges = TrainingInsightEngine.makeChallenges(from: summaries, overview: overview)
                let badges = TrainingInsightEngine.makeBadges(from: overview)
                let benchmarks = TrainingGhostEngine.makeBenchmarks(from: summaries)

                workoutHistory = summaries
                recentWorkouts = Array(summaries.prefix(8))
                trainingOverview = overview
                trainingChallenges = challenges
                trainingBadges = badges
                ghostBenchmarks = benchmarks
                personalBestBoard = TrainingGhostEngine.makePersonalBestBoard(
                    from: summaries,
                    benchmarks: benchmarks
                )
                isLoadingRecentWorkouts = false
            } catch {
                workoutHistory = []
                recentWorkouts = []
                trainingOverview = nil
                trainingChallenges = []
                trainingBadges = []
                ghostBenchmarks = []
                personalBestBoard = []
                isLoadingRecentWorkouts = false
                historyErrorMessage = error.localizedDescription
            }
        }
    }

    private static func makeWorkoutSummary(from workout: HKWorkout) -> HealthWorkoutSummary {
        HealthWorkoutSummary(
            id: workout.uuid,
            startDate: workout.startDate,
            endDate: workout.endDate,
            duration: workout.duration,
            energyKilocalories: workout
                .statistics(for: HealthKitTypes.activeEnergy)?
                .sumQuantity()?
                .doubleValue(for: HealthKitTypes.energyUnit),
            distanceMeters: workout.totalDistance?.doubleValue(for: HealthKitTypes.distanceUnit)
        )
    }
}
