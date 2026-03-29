import Foundation

enum WorkoutFocus: String {
    case race
    case threshold
    case base
    case technique

    var title: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .race: "flag.checkered.2.crossed"
        case .threshold: "gauge.with.dots.needle.67percent"
        case .base: "figure.rower"
        case .technique: "waveform.path.ecg.rectangle"
        }
    }
}

struct StructuredWorkoutStep: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let duration: TimeInterval
}

struct StructuredWorkoutTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let focus: WorkoutFocus
    let expectedOutcome: String
    let steps: [StructuredWorkoutStep]

    var totalDuration: TimeInterval {
        steps.reduce(0) { $0 + $1.duration }
    }
}

enum StructuredWorkoutLibrary {
    static let templates: [StructuredWorkoutTemplate] = [
        StructuredWorkoutTemplate(
            id: "race-primer",
            title: "Race Primer",
            summary: "Short sharpening session that readies you for a 500 m or 1 k effort.",
            focus: .race,
            expectedOutcome: "Wake up power, lift stroke intent, and arrive ready for Ghost Race.",
            steps: [
                StructuredWorkoutStep(id: "warmup", title: "Warm up", detail: "Easy paddle and loosen the slide.", duration: 8 * 60),
                StructuredWorkoutStep(id: "builds", title: "Builds", detail: "Three 45-second pushes with easy paddling between them.", duration: 6 * 60),
                StructuredWorkoutStep(id: "settle", title: "Settle", detail: "Return to controlled rhythm before the last push.", duration: 4 * 60),
                StructuredWorkoutStep(id: "launch", title: "Launch piece", detail: "Row hard with crisp catches for the final block.", duration: 3 * 60),
            ]
        ),
        StructuredWorkoutTemplate(
            id: "threshold-ladder",
            title: "Threshold Ladder",
            summary: "Controlled work blocks that raise sustainable pace without spiking the session.",
            focus: .threshold,
            expectedOutcome: "Build confidence holding pressure for longer benchmark pieces.",
            steps: [
                StructuredWorkoutStep(id: "easy-open", title: "Open", detail: "10 minutes easy with rate cap around 20 spm.", duration: 10 * 60),
                StructuredWorkoutStep(id: "threshold-1", title: "6 min on", detail: "Hold your strong sustainable pace.", duration: 6 * 60),
                StructuredWorkoutStep(id: "float-1", title: "2 min easy", detail: "Paddle light and recover.", duration: 2 * 60),
                StructuredWorkoutStep(id: "threshold-2", title: "8 min on", detail: "Hold form while pressure stays on.", duration: 8 * 60),
                StructuredWorkoutStep(id: "float-2", title: "2 min easy", detail: "Reset breathing and prepare for one more block.", duration: 2 * 60),
                StructuredWorkoutStep(id: "threshold-3", title: "6 min on", detail: "Finish with the cleanest technique of the day.", duration: 6 * 60),
            ]
        ),
        StructuredWorkoutTemplate(
            id: "base-builder",
            title: "Base Builder",
            summary: "Steady aerobic volume with just enough structure to stay engaged.",
            focus: .base,
            expectedOutcome: "Accumulate meters, streak days, and easy XP without frying the legs.",
            steps: [
                StructuredWorkoutStep(id: "steady-1", title: "10 min steady", detail: "Easy-to-moderate pressure at conversational effort.", duration: 10 * 60),
                StructuredWorkoutStep(id: "reset-1", title: "2 min reset", detail: "Paddle easy and lengthen the stroke.", duration: 2 * 60),
                StructuredWorkoutStep(id: "steady-2", title: "10 min steady", detail: "Repeat the same pace with slightly cleaner rhythm.", duration: 10 * 60),
                StructuredWorkoutStep(id: "reset-2", title: "2 min reset", detail: "Easy paddle and sit tall.", duration: 2 * 60),
                StructuredWorkoutStep(id: "steady-3", title: "8 min steady", detail: "Close the session with relaxed consistency.", duration: 8 * 60),
            ]
        ),
        StructuredWorkoutTemplate(
            id: "shape-and-rate",
            title: "Shape + Rate",
            summary: "Technique session pairing force-curve awareness with rate changes.",
            focus: .technique,
            expectedOutcome: "Improve stroke shape while rehearsing clean transitions in cadence.",
            steps: [
                StructuredWorkoutStep(id: "prep", title: "Prep", detail: "Easy row and focus on a long drive.", duration: 8 * 60),
                StructuredWorkoutStep(id: "tech-1", title: "4 min @ 20", detail: "Smooth force curve and even pressure.", duration: 4 * 60),
                StructuredWorkoutStep(id: "tech-2", title: "4 min @ 24", detail: "Keep the curve broad while the rate rises.", duration: 4 * 60),
                StructuredWorkoutStep(id: "recover", title: "3 min easy", detail: "Loose paddle and reset timing.", duration: 3 * 60),
                StructuredWorkoutStep(id: "tech-3", title: "4 min @ 22", detail: "Blend force quality with steady cadence.", duration: 4 * 60),
                StructuredWorkoutStep(id: "tech-4", title: "4 min @ 26", detail: "Stay relaxed and keep pressure connected.", duration: 4 * 60),
            ]
        ),
    ]
}
