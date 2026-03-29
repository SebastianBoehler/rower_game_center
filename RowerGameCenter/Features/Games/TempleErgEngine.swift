import Foundation

enum TempleErgEngine {
    private static let playerZone = 0.22
    private static let obstacleStart = 1.12
    private static let obstacleRemoval = -0.20
    private static let maximumTickDelta: TimeInterval = 0.28

    static func makeInitialState() -> TempleErgState {
        TempleErgState()
    }

    static func advance(
        state: inout TempleErgState,
        metrics: RowingMetrics,
        now: Date
    ) -> TempleErgRunSummary? {
        guard !state.isGameOver else { return nil }

        guard let previousTickDate = state.lastTickDate else {
            state.lastTickDate = now
            updateInputProfile(for: &state, metrics: metrics)
            applyReading(for: &state, metrics: metrics)
            return nil
        }

        let delta = min(now.timeIntervalSince(previousTickDate), maximumTickDelta)
        state.lastTickDate = now

        updateInputProfile(for: &state, metrics: metrics)
        applyReading(for: &state, metrics: metrics)

        let worldSpeed = laneSpeed(for: metrics)
        moveObstacles(for: &state, delta: delta, worldSpeed: worldSpeed)
        spawnObstacleIfNeeded(for: &state, delta: delta, worldSpeed: worldSpeed)

        if state.lives <= 0 {
            state.isGameOver = true
            return TempleErgRunSummary(
                score: state.score,
                clearedObstacles: state.clearedObstacles,
                bestCombo: state.bestCombo,
                dominantAction: dominantAction(from: state)
            )
        }

        return nil
    }

    private static func laneSpeed(for metrics: RowingMetrics) -> Double {
        guard let pace = metrics.pace, pace > 0 else { return 0.42 }
        let normalized = 120 / pace
        return min(max(normalized * 0.52, 0.36), 0.94)
    }

    private static func moveObstacles(
        for state: inout TempleErgState,
        delta: TimeInterval,
        worldSpeed: Double
    ) {
        for index in state.obstacles.indices {
            state.obstacles[index].position -= worldSpeed * delta
        }

        let currentAction = resolvedAction(from: state.currentReading)

        for index in state.obstacles.indices where !state.obstacles[index].isResolved {
            if state.obstacles[index].position <= playerZone {
                state.obstacles[index].isResolved = true

                if state.obstacles[index].action == currentAction {
                    state.obstacles[index].wasSuccessful = true
                    state.combo += 1
                    state.bestCombo = max(state.bestCombo, state.combo)
                    state.clearedObstacles += 1
                    state.score += 140 + min(state.combo, 12) * 22
                    state.currentHint = "\(state.obstacles[index].action.title) nailed. Keep the combo alive."
                } else {
                    state.combo = 0
                    state.lives -= 1
                    state.currentHint = missHint(for: state.obstacles[index].action)
                }
            }
        }

        state.obstacles.removeAll { $0.position < obstacleRemoval }
    }

    private static func spawnObstacleIfNeeded(
        for state: inout TempleErgState,
        delta: TimeInterval,
        worldSpeed: Double
    ) {
        state.spawnCooldown -= delta * max(worldSpeed, 0.35)
        guard state.spawnCooldown <= 0 else { return }

        let action = nextObstacleAction(after: state.lastSpawnedAction)
        state.lastSpawnedAction = action
        state.obstacles.append(
            TempleErgObstacle(
                action: action,
                position: obstacleStart + Double.random(in: 0.02...0.12)
            )
        )
        state.spawnCooldown = Double.random(in: 1.05...1.55)
    }

    private static func updateInputProfile(
        for state: inout TempleErgState,
        metrics: RowingMetrics
    ) {
        if let power = metrics.powerWatts {
            append(power, to: &state.recentPowers)
        }

        if let strokeRate = metrics.strokeRate {
            append(strokeRate, to: &state.recentStrokeRates)
        }

        if let driveTime = metrics.driveTime,
           let recoveryTime = metrics.recoveryTime,
           driveTime > 0 {
            append(recoveryTime / driveTime, to: &state.recentRecoveryRatios)
        }
    }

    private static func applyReading(
        for state: inout TempleErgState,
        metrics: RowingMetrics
    ) {
        let baselinePower = average(of: state.recentPowers) ?? 165
        let baselineStrokeRate = average(of: state.recentStrokeRates) ?? 22
        let recoveryRatio = metrics.driveTime.flatMap { driveTime -> Double? in
            guard let recoveryTime = metrics.recoveryTime, driveTime > 0 else { return nil }
            return recoveryTime / driveTime
        }

        if let power = metrics.powerWatts,
           let workPerStroke = metrics.workPerStrokeJoules,
           power >= max(baselinePower + 95, 310) || workPerStroke >= 700 {
            state.currentReading = .action(.smash)
            state.currentHint = "Heavy hit detected. Smash gates will break."
            return
        }

        if let power = metrics.powerWatts,
           power >= max(baselinePower + 34, 215) {
            state.currentReading = .action(.jump)
            state.currentHint = "Explosive stroke detected. Clear the high gap."
            return
        }

        if let strokeRate = metrics.strokeRate,
           strokeRate <= max(baselineStrokeRate - 4, 18) || (recoveryRatio ?? 0) >= 2.1 {
            state.currentReading = .action(.duck)
            state.currentHint = "Long recovery detected. Slide under the arch."
            return
        }

        state.currentReading = .neutral
        state.currentHint = "Cruise, then react. Burst jumps, settle ducks, hammer smashes."
    }

    private static func nextObstacleAction(after previousAction: TempleErgAction?) -> TempleErgAction {
        let candidates = TempleErgAction.allCases.filter { $0 != previousAction }
        return candidates.randomElement() ?? .jump
    }

    private static func dominantAction(from state: TempleErgState) -> TempleErgAction? {
        if let currentAction = resolvedAction(from: state.currentReading) {
            return currentAction
        }

        return state.lastSpawnedAction
    }

    private static func missHint(for action: TempleErgAction) -> String {
        switch action {
        case .jump:
            "Missed the jump. Hit a stronger burst when the next gap arrives."
        case .duck:
            "Too high through the arch. Relax the rate and lengthen the recovery."
        case .smash:
            "The gate held. Drive harder for a heavier smash window."
        }
    }

    private static func resolvedAction(from reading: TempleErgActionReading) -> TempleErgAction? {
        switch reading {
        case .neutral:
            nil
        case .action(let action):
            action
        }
    }

    private static func append(_ value: Int, to array: inout [Int]) {
        array.append(value)
        if array.count > 12 {
            array.removeFirst(array.count - 12)
        }
    }

    private static func append(_ value: Double, to array: inout [Double]) {
        array.append(value)
        if array.count > 12 {
            array.removeFirst(array.count - 12)
        }
    }

    private static func average(of values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / values.count
    }
}
