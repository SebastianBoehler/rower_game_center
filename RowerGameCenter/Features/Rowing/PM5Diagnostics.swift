import Foundation

enum PM5DiagnosticLevel: String {
    case info
    case notice
    case error
}

struct PM5DiagnosticEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let level: PM5DiagnosticLevel
    let category: String
    let message: String

    var consoleLine: String {
        "[\(timestamp.formatted(PM5DiagnosticsFormatter.consoleTimestamp))] [\(level.rawValue.uppercased())] [\(category)] \(message)"
    }
}

private enum PM5DiagnosticsFormatter {
    static let consoleTimestamp =
        Date.FormatStyle()
            .year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
            .hour(.twoDigits(amPM: .omitted))
            .minute(.twoDigits)
            .second(.twoDigits)
            .secondFraction(.fractional(3))
}
