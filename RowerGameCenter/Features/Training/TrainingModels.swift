import Foundation

enum StandardRaceDistance: String, CaseIterable, Identifiable {
    case sprint500
    case kilo1000
    case classic2000

    var id: String { rawValue }

    var meters: Double {
        switch self {
        case .sprint500: 500
        case .kilo1000: 1_000
        case .classic2000: 2_000
        }
    }

    var title: String {
        switch self {
        case .sprint500: "500 m"
        case .kilo1000: "1 k"
        case .classic2000: "2 k"
        }
    }

    var ghostTitle: String {
        "\(title) ghost"
    }
}

struct TrainingOverview {
    let totalWorkouts: Int
    let totalDistanceMeters: Double
    let totalDuration: TimeInterval
    let totalEnergyKilocalories: Double
    let currentStreakDays: Int
    let longestStreakDays: Int
    let workoutsThisWeek: Int
    let workoutsThisMonth: Int
    let distanceThisWeekMeters: Double
    let distanceThisMonthMeters: Double
    let lastWorkoutDate: Date?
    let xp: Int
    let level: Int
    let xpIntoCurrentLevel: Int
    let xpForNextLevel: Int

    var progressToNextLevel: Double {
        guard xpForNextLevel > 0 else { return 0 }
        return min(Double(xpIntoCurrentLevel) / Double(xpForNextLevel), 1)
    }
}

struct TrainingChallengeProgress: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let rewardXP: Int
    let progress: Double
    let progressLabel: String

    var isCompleted: Bool {
        progress >= 1
    }
}

struct TrainingBadgeStatus: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let progress: Double
    let progressLabel: String
    let isUnlocked: Bool
}

struct TrainingBenchmark: Identifiable {
    let distance: StandardRaceDistance
    let bestTime: TimeInterval?
    let sourceSummary: String
    let sourceDate: Date?

    var id: String { distance.id }

    var pace: TimeInterval? {
        guard let bestTime else { return nil }
        return bestTime / distance.meters * 500
    }
}

struct TrainingLeaderboardEntry: Identifiable {
    let id: String
    let title: String
    let metric: String
    let detail: String
    let systemImage: String
}
