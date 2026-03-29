import SwiftUI

struct SessionRecap: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let recordedAt: Date
    let heroValue: String
    let heroLabel: String
    let metrics: [SessionRecapMetric]
    let highlights: [String]
    let footer: String

    var shareTitle: String {
        "\(title) • Rower Game Center"
    }

    var fileName: String {
        let sanitizedTitle = title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        return "rower-game-center-\(sanitizedTitle)-\(id.uuidString.lowercased()).png"
    }
}

struct SessionRecapMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String?
}
