import Foundation

enum TrainingInsightEngine {
    static func makeOverview(from workouts: [HealthWorkoutSummary], now: Date = .now) -> TrainingOverview {
        let calendar = Calendar.current
        let totalDistanceMeters = workouts.reduce(0) { $0 + ($1.distanceMeters ?? 0) }
        let totalDuration = workouts.reduce(0) { $0 + $1.duration }
        let totalEnergyKilocalories = workouts.reduce(0) { $0 + ($1.energyKilocalories ?? 0) }
        let totalWorkouts = workouts.count

        let workoutsThisWeek = workouts.filter { calendar.isDate($0.endDate, equalTo: now, toGranularity: .weekOfYear) }.count
        let workoutsThisMonth = workouts.filter { calendar.isDate($0.endDate, equalTo: now, toGranularity: .month) }.count
        let distanceThisWeekMeters = workouts
            .filter { calendar.isDate($0.endDate, equalTo: now, toGranularity: .weekOfYear) }
            .reduce(0) { $0 + ($1.distanceMeters ?? 0) }
        let distanceThisMonthMeters = workouts
            .filter { calendar.isDate($0.endDate, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + ($1.distanceMeters ?? 0) }

        let currentStreakDays = currentStreak(for: workouts, calendar: calendar, now: now)
        let longestStreakDays = longestStreak(for: workouts, calendar: calendar)
        let xp = totalXP(
            totalWorkouts: totalWorkouts,
            totalDistanceMeters: totalDistanceMeters,
            totalDuration: totalDuration,
            currentStreakDays: currentStreakDays
        )
        let levelProgress = levelProgress(for: xp)

        return TrainingOverview(
            totalWorkouts: totalWorkouts,
            totalDistanceMeters: totalDistanceMeters,
            totalDuration: totalDuration,
            totalEnergyKilocalories: totalEnergyKilocalories,
            currentStreakDays: currentStreakDays,
            longestStreakDays: longestStreakDays,
            workoutsThisWeek: workoutsThisWeek,
            workoutsThisMonth: workoutsThisMonth,
            distanceThisWeekMeters: distanceThisWeekMeters,
            distanceThisMonthMeters: distanceThisMonthMeters,
            lastWorkoutDate: workouts.first?.endDate,
            xp: xp,
            level: levelProgress.level,
            xpIntoCurrentLevel: levelProgress.progress,
            xpForNextLevel: levelProgress.goal
        )
    }

    static func makeChallenges(
        from workouts: [HealthWorkoutSummary],
        overview: TrainingOverview,
        now: Date = .now
    ) -> [TrainingChallengeProgress] {
        let calendar = Calendar.current
        let todaysDistance = workouts
            .filter { calendar.isDate($0.endDate, inSameDayAs: now) }
            .reduce(0) { $0 + ($1.distanceMeters ?? 0) }

        return [
            TrainingChallengeProgress(
                id: "today-distance",
                title: "Daily Spark",
                subtitle: "Row 2.5 km today to keep the streak engine moving.",
                systemImage: "sun.max.fill",
                rewardXP: 120,
                progress: normalizedProgress(current: todaysDistance, goal: 2_500),
                progressLabel: "\(Int(todaysDistance.rounded())) / 2500 m"
            ),
            TrainingChallengeProgress(
                id: "week-sessions",
                title: "Three Touches",
                subtitle: "Log three sessions this week for consistency XP.",
                systemImage: "calendar.badge.clock",
                rewardXP: 220,
                progress: normalizedProgress(current: Double(overview.workoutsThisWeek), goal: 3),
                progressLabel: "\(overview.workoutsThisWeek) / 3 sessions"
            ),
            TrainingChallengeProgress(
                id: "week-distance",
                title: "10K Builder",
                subtitle: "Accumulate 10 km this week across any mix of pieces.",
                systemImage: "figure.rower",
                rewardXP: 320,
                progress: normalizedProgress(current: overview.distanceThisWeekMeters, goal: 10_000),
                progressLabel: "\(Int(overview.distanceThisWeekMeters.rounded())) / 10000 m"
            ),
        ]
    }

    static func makeBadges(from overview: TrainingOverview) -> [TrainingBadgeStatus] {
        [
            badge(
                id: "five-workouts",
                title: "Warm Engine",
                subtitle: "Finish five synced rowing workouts.",
                systemImage: "flame.fill",
                current: Double(overview.totalWorkouts),
                goal: 5,
                progressLabel: "\(overview.totalWorkouts) / 5 rows"
            ),
            badge(
                id: "fifty-km",
                title: "50 km Club",
                subtitle: "Bank your first fifty kilometers.",
                systemImage: "road.lanes",
                current: overview.totalDistanceMeters,
                goal: 50_000,
                progressLabel: "\(Int(overview.totalDistanceMeters.rounded())) / 50000 m"
            ),
            badge(
                id: "seven-day-streak",
                title: "Seven-Day Rhythm",
                subtitle: "Keep a seven-day rowing streak alive.",
                systemImage: "bolt.heart.fill",
                current: Double(overview.currentStreakDays),
                goal: 7,
                progressLabel: "\(overview.currentStreakDays) / 7 days"
            ),
            badge(
                id: "level-five",
                title: "Level Five",
                subtitle: "Reach training level five.",
                systemImage: "medal.star.fill",
                current: Double(overview.level),
                goal: 5,
                progressLabel: "Level \(overview.level) / 5"
            ),
        ]
    }

    private static func currentStreak(
        for workouts: [HealthWorkoutSummary],
        calendar: Calendar,
        now: Date
    ) -> Int {
        let days = uniqueWorkoutDays(from: workouts, calendar: calendar)
        guard let latestDay = days.first else { return 0 }

        let today = calendar.startOfDay(for: now)
        let dayGap = calendar.dateComponents([.day], from: latestDay, to: today).day ?? 0
        guard dayGap <= 1 else { return 0 }

        return streakLength(from: days, calendar: calendar)
    }

    private static func longestStreak(for workouts: [HealthWorkoutSummary], calendar: Calendar) -> Int {
        let days = uniqueWorkoutDays(from: workouts, calendar: calendar)
        guard !days.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for index in 1..<days.count {
            let dayGap = calendar.dateComponents([.day], from: days[index], to: days[index - 1]).day ?? 0
            if dayGap == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    private static func streakLength(from days: [Date], calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }

        var streak = 1

        for index in 1..<days.count {
            let dayGap = calendar.dateComponents([.day], from: days[index], to: days[index - 1]).day ?? 0
            if dayGap == 1 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    private static func uniqueWorkoutDays(from workouts: [HealthWorkoutSummary], calendar: Calendar) -> [Date] {
        let days = Set(workouts.map { calendar.startOfDay(for: $0.endDate) })
        return days.sorted(by: >)
    }

    private static func totalXP(
        totalWorkouts: Int,
        totalDistanceMeters: Double,
        totalDuration: TimeInterval,
        currentStreakDays: Int
    ) -> Int {
        totalWorkouts * 120
            + Int(totalDistanceMeters / 100)
            + Int(totalDuration / 60)
            + currentStreakDays * 35
    }

    private static func levelProgress(for xp: Int) -> (level: Int, progress: Int, goal: Int) {
        var level = 1
        var remainingXP = xp
        var nextGoal = 500

        while remainingXP >= nextGoal {
            remainingXP -= nextGoal
            level += 1
            nextGoal = 500 + (level - 1) * 140
        }

        return (level, remainingXP, nextGoal)
    }

    private static func badge(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String,
        current: Double,
        goal: Double,
        progressLabel: String
    ) -> TrainingBadgeStatus {
        let progress = normalizedProgress(current: current, goal: goal)
        return TrainingBadgeStatus(
            id: id,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            progress: progress,
            progressLabel: progressLabel,
            isUnlocked: progress >= 1
        )
    }

    private static func normalizedProgress(current: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(max(current / goal, 0), 1)
    }
}
