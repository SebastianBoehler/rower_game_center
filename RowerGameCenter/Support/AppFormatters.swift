import Foundation

enum AppFormatters {
    static func distance(_ value: Double?) -> String {
        guard let value else { return "--" }
        return "\(Int(value.rounded())) m"
    }

    static func kilometers(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f km", value / 1_000)
    }

    static func duration(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        let totalSeconds = Int(value.rounded(.down))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    static func pace(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        let totalSeconds = Int(value.rounded(.down))
        return String(format: "%d:%02d /500m", totalSeconds / 60, totalSeconds % 60)
    }

    static func watts(_ value: Int?) -> String {
        guard let value else { return "--" }
        return "\(value) W"
    }

    static func heartRate(_ value: Int?) -> String {
        guard let value else { return "--" }
        return "\(value) bpm"
    }

    static func calories(_ value: Int?) -> String {
        guard let value else { return "--" }
        return "\(value) cal"
    }

    static func calories(_ value: Double?) -> String {
        guard let value else { return "--" }
        return "\(Int(value.rounded())) cal"
    }

    static func strokeRate(_ value: Int?) -> String {
        guard let value else { return "--" }
        return "\(value) spm"
    }

    static func shortSeconds(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        return String(format: "%.2f s", value)
    }

    static func force(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.0f lb", value)
    }

    static func energy(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f J", value)
    }

    static func totalDuration(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        let totalMinutes = Int(value.rounded(.down) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    static func relativeTimestamp(_ value: Date?) -> String {
        guard let value else { return "Waiting for live data" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: value, relativeTo: .now)
    }

    static func workoutDay(_ value: Date) -> String {
        value.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    static func workoutTime(_ value: Date) -> String {
        value.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute(.twoDigits))
    }

    static func gapMeters(_ value: Double) -> String {
        let rounded = Int(abs(value).rounded())
        if rounded == 0 { return "Level" }
        return value >= 0 ? "+\(rounded) m" : "-\(rounded) m"
    }
}
