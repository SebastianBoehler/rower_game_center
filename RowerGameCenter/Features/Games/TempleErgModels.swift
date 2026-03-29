import SwiftUI

enum TempleErgAction: String, CaseIterable, Identifiable, Equatable {
    case jump
    case duck
    case smash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .jump:
            "Jump"
        case .duck:
            "Duck"
        case .smash:
            "Smash"
        }
    }

    var caption: String {
        switch self {
        case .jump:
            "Explosive stroke"
        case .duck:
            "Longer recovery"
        case .smash:
            "Heavy hit"
        }
    }

    var systemImage: String {
        switch self {
        case .jump:
            "arrow.up.circle.fill"
        case .duck:
            "arrow.down.circle.fill"
        case .smash:
            "burst.fill"
        }
    }

    var tint: Color {
        switch self {
        case .jump:
            .cyan
        case .duck:
            .orange
        case .smash:
            .pink
        }
    }
}

enum TempleErgActionReading: Equatable {
    case neutral
    case action(TempleErgAction)

    var title: String {
        switch self {
        case .neutral:
            "Cruise"
        case .action(let action):
            action.title
        }
    }

    var systemImage: String {
        switch self {
        case .neutral:
            "figure.rower"
        case .action(let action):
            action.systemImage
        }
    }

    var tint: Color {
        switch self {
        case .neutral:
            AppTheme.tint
        case .action(let action):
            action.tint
        }
    }
}

struct TempleErgObstacle: Identifiable {
    let id = UUID()
    let action: TempleErgAction
    var position: Double
    var isResolved = false
    var wasSuccessful = false
}

struct TempleErgState {
    var obstacles: [TempleErgObstacle] = []
    var score = 0
    var combo = 0
    var bestCombo = 0
    var lives = 3
    var clearedObstacles = 0
    var lastTickDate: Date?
    var spawnCooldown: TimeInterval = 1.6
    var recentPowers: [Int] = []
    var recentStrokeRates: [Int] = []
    var recentRecoveryRatios: [Double] = []
    var lastSpawnedAction: TempleErgAction?
    var lastSuccessfulAction: TempleErgAction?
    var currentReading: TempleErgActionReading = .neutral
    var currentHint = "Find a steady rhythm to keep the run alive."
    var isGameOver = false
}

struct TempleErgRunSummary {
    let score: Int
    let clearedObstacles: Int
    let bestCombo: Int
    let dominantAction: TempleErgAction?
}
