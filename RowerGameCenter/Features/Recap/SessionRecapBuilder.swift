import SwiftUI

enum SessionRecapBuilder {
    static func workout(metrics: RowingMetrics, savedToHealth: Bool) -> SessionRecap {
        SessionRecap(
            category: savedToHealth ? "Workout Saved" : "Workout Complete",
            title: "Rowing Workout",
            subtitle: savedToHealth
                ? "Your PM5 session is saved to Apple Health and ready to share."
                : "Your PM5 session is ready to share.",
            systemImage: "figure.rower",
            tint: AppTheme.success,
            recordedAt: .now,
            heroValue: AppFormatters.distance(metrics.distance),
            heroLabel: "Total distance",
            metrics: workoutMetrics(from: metrics),
            highlights: workoutHighlights(savedToHealth: savedToHealth),
            footer: "Tracked with live PM5 data in Rower Game Center."
        )
    }

    static func laneSprint(metrics: RowingMetrics, elapsedTime: TimeInterval?, distanceMeters: Double) -> SessionRecap {
        SessionRecap(
            category: "Game Finish",
            title: "Lane Sprint",
            subtitle: "500 m cleared. Clean finish, ready to post.",
            systemImage: "flag.checkered.circle.fill",
            tint: AppTheme.success,
            recordedAt: .now,
            heroValue: AppFormatters.duration(elapsedTime),
            heroLabel: "Finish time",
            metrics: [
                SessionRecapMetric(title: "Distance", value: AppFormatters.distance(distanceMeters), detail: "Goal distance"),
                SessionRecapMetric(title: "Pace", value: paceString(distanceMeters: distanceMeters, elapsedTime: elapsedTime), detail: "Projected /500m"),
                SessionRecapMetric(title: "Power", value: AppFormatters.watts(metrics.powerWatts), detail: "Live finish wattage"),
                SessionRecapMetric(title: "Rate", value: AppFormatters.strokeRate(metrics.strokeRate), detail: "Stroke rate at finish"),
            ],
            highlights: [
                "A focused 500 m race driven only by your live PM5 distance.",
                "Share the finish card to spark competition and rematches.",
            ],
            footer: "Built in Rower Game Center."
        )
    }

    static func templeErg(
        score: Int,
        clearedObstacles: Int,
        bestCombo: Int,
        distanceMeters: Double,
        elapsedTime: TimeInterval?,
        dominantAction: TempleErgAction?
    ) -> SessionRecap {
        SessionRecap(
            category: "Game Finish",
            title: "Temple Erg",
            subtitle: "Fast obstacle rush complete. Post the score and pull in the rematches.",
            systemImage: "bolt.horizontal.circle.fill",
            tint: .orange,
            recordedAt: .now,
            heroValue: "\(score)",
            heroLabel: "Score",
            metrics: [
                SessionRecapMetric(title: "Distance", value: AppFormatters.distance(distanceMeters), detail: "Meters rowed during the run"),
                SessionRecapMetric(title: "Time", value: AppFormatters.duration(elapsedTime), detail: "Run duration"),
                SessionRecapMetric(title: "Clears", value: "\(clearedObstacles)", detail: "Obstacles cleared"),
                SessionRecapMetric(title: "Best Combo", value: "\(bestCombo)x", detail: dominantAction.map { "\($0.title) was your best read." }),
            ],
            highlights: [
                "Burst strokes jumped the gaps, long recoveries ducked the arches, and heavy hits smashed the gates.",
                "This is built to be shared because competitive clips and score cards create the awareness loop for the game.",
            ],
            footer: "Temple Erg powered by Rower Game Center."
        )
    }

    static func ghostRace(
        distance: StandardRaceDistance,
        elapsedTime: TimeInterval?,
        gapMeters: Double,
        didBeatGhost: Bool,
        benchmark: TrainingBenchmark?
    ) -> SessionRecap {
        SessionRecap(
            category: "Game Finish",
            title: "Ghost Race",
            subtitle: didBeatGhost
                ? "You beat your \(distance.title) ghost."
                : "Your \(distance.title) ghost held on this round.",
            systemImage: "hare.fill",
            tint: AppTheme.tint,
            recordedAt: .now,
            heroValue: AppFormatters.duration(elapsedTime),
            heroLabel: distance.title,
            metrics: [
                SessionRecapMetric(title: "Gap", value: AppFormatters.gapMeters(gapMeters), detail: "Ahead or behind at the line"),
                SessionRecapMetric(title: "Ghost", value: AppFormatters.duration(benchmark?.bestTime), detail: "Benchmark target"),
                SessionRecapMetric(title: "Ghost Pace", value: AppFormatters.pace(benchmark?.pace), detail: "Target split"),
                SessionRecapMetric(title: "Result", value: didBeatGhost ? "Beat it" : "Chasing", detail: "Head-to-head verdict"),
            ],
            highlights: [
                benchmark?.sourceSummary ?? "Built from your synced rowing history.",
                "A shareable finish card turns personal benchmarks into social fuel.",
            ],
            footer: "Race your own history with Rower Game Center."
        )
    }

    static func structuredWorkout(
        template: StructuredWorkoutTemplate,
        metrics: RowingMetrics,
        elapsedTime: TimeInterval?
    ) -> SessionRecap {
        SessionRecap(
            category: "Plan Complete",
            title: template.title,
            subtitle: "Structured workout complete. Post the result and keep the streak moving.",
            systemImage: template.focus.systemImage,
            tint: template.focus.tint,
            recordedAt: .now,
            heroValue: AppFormatters.totalDuration(elapsedTime),
            heroLabel: "Elapsed",
            metrics: [
                SessionRecapMetric(title: "Distance", value: AppFormatters.distance(metrics.distance), detail: "Meters rowed during the plan"),
                SessionRecapMetric(title: "Pace", value: AppFormatters.pace(metrics.pace), detail: "Finish pace"),
                SessionRecapMetric(title: "Rate", value: AppFormatters.strokeRate(metrics.strokeRate), detail: "Finish stroke rate"),
                SessionRecapMetric(title: "Focus", value: template.focus.title, detail: template.expectedOutcome),
            ],
            highlights: [
                template.summary,
                "Structured rows are easier to share when the recap is already designed for it.",
            ],
            footer: "Guided by Rower Game Center."
        )
    }

    private static func workoutMetrics(from metrics: RowingMetrics) -> [SessionRecapMetric] {
        [
            SessionRecapMetric(title: "Time", value: AppFormatters.duration(metrics.elapsedTime), detail: "PM5 elapsed time"),
            SessionRecapMetric(title: "Pace", value: AppFormatters.pace(metrics.pace), detail: "Latest /500m"),
            SessionRecapMetric(title: "Calories", value: AppFormatters.calories(metrics.calories), detail: "Active calories"),
            SessionRecapMetric(title: "Rate", value: AppFormatters.strokeRate(metrics.strokeRate), detail: "Current stroke rate"),
        ]
    }

    private static func workoutHighlights(savedToHealth: Bool) -> [String] {
        var highlights = ["Live PM5 telemetry captured the session metrics in real time."]
        if savedToHealth {
            highlights.append("This workout was synced into Apple Health before the recap was generated.")
        }
        highlights.append("Post the card to spread the row and drive organic challenge traffic.")
        return highlights
    }

    private static func paceString(distanceMeters: Double, elapsedTime: TimeInterval?) -> String {
        guard let elapsedTime, distanceMeters > 0 else { return "--" }
        return AppFormatters.pace(elapsedTime / distanceMeters * 500)
    }
}
