import Foundation

enum TrainingGhostEngine {
    static func makeBenchmarks(from workouts: [HealthWorkoutSummary]) -> [TrainingBenchmark] {
        StandardRaceDistance.allCases.map { distance in
            guard let bestMatch = bestMatch(for: distance, in: workouts) else {
                return TrainingBenchmark(
                    distance: distance,
                    bestTime: nil,
                    sourceSummary: "Finish a synced rowing workout to generate this ghost.",
                    sourceDate: nil
                )
            }

            return TrainingBenchmark(
                distance: distance,
                bestTime: bestProjectedTime(for: distance, workout: bestMatch),
                sourceSummary: sourceSummary(for: distance, workout: bestMatch),
                sourceDate: bestMatch.endDate
            )
        }
    }

    static func makePersonalBestBoard(
        from workouts: [HealthWorkoutSummary],
        benchmarks: [TrainingBenchmark]
    ) -> [TrainingLeaderboardEntry] {
        var entries = benchmarks.compactMap { benchmark -> TrainingLeaderboardEntry? in
            guard let bestTime = benchmark.bestTime else { return nil }
            return TrainingLeaderboardEntry(
                id: benchmark.id,
                title: benchmark.distance.title,
                metric: AppFormatters.duration(bestTime),
                detail: benchmark.sourceSummary,
                systemImage: "flag.checkered.circle.fill"
            )
        }

        if let longestRow = workouts.max(by: { ($0.distanceMeters ?? 0) < ($1.distanceMeters ?? 0) }) {
            entries.append(
                TrainingLeaderboardEntry(
                    id: "longest-row",
                    title: "Longest row",
                    metric: AppFormatters.distance(longestRow.distanceMeters),
                    detail: AppFormatters.workoutDay(longestRow.endDate),
                    systemImage: "road.lanes"
                )
            )
        }

        if let hottestRow = workouts.max(by: { ($0.energyKilocalories ?? 0) < ($1.energyKilocalories ?? 0) }) {
            entries.append(
                TrainingLeaderboardEntry(
                    id: "highest-burn",
                    title: "Highest burn",
                    metric: AppFormatters.calories(hottestRow.energyKilocalories),
                    detail: AppFormatters.workoutDay(hottestRow.endDate),
                    systemImage: "flame.fill"
                )
            )
        }

        return entries
    }

    private static func bestMatch(
        for distance: StandardRaceDistance,
        in workouts: [HealthWorkoutSummary]
    ) -> HealthWorkoutSummary? {
        workouts
            .filter {
                guard let workoutDistance = $0.distanceMeters else { return false }
                return workoutDistance >= distance.meters * 0.8
            }
            .min { lhs, rhs in
                bestProjectedTime(for: distance, workout: lhs) < bestProjectedTime(for: distance, workout: rhs)
            }
    }

    private static func bestProjectedTime(
        for distance: StandardRaceDistance,
        workout: HealthWorkoutSummary
    ) -> TimeInterval {
        let workoutDistance = max(workout.distanceMeters ?? 1, 1)
        return workout.duration * distance.meters / workoutDistance
    }

    private static func sourceSummary(
        for distance: StandardRaceDistance,
        workout: HealthWorkoutSummary
    ) -> String {
        let workoutDistance = workout.distanceMeters ?? 0
        if abs(workoutDistance - distance.meters) <= max(100, distance.meters * 0.08) {
            return "Matched from your \(distance.title.lowercased()) effort on \(AppFormatters.workoutDay(workout.endDate))."
        }

        return "Projected from your \(AppFormatters.distance(workout.distanceMeters)) row on \(AppFormatters.workoutDay(workout.endDate))."
    }
}
