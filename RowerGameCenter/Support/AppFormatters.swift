import Foundation

enum AppFormatters {
    static func distance(_ value: Double?) -> String {
        guard let value else { return "--" }
        return "\(Int(value.rounded())) m"
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

    static func strokeRate(_ value: Int?) -> String {
        guard let value else { return "--" }
        return "\(value) spm"
    }
}
