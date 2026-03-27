import Foundation

struct RowingMetrics {
    var connected = false
    var deviceName: String?
    var elapsedTime: TimeInterval?
    var distance: Double?
    var strokeRate: Int?
    var pace: TimeInterval?
    var powerWatts: Int?
    var calories: Int?
    var heartRate: Int?
    var lastUpdatedAt: Date?
}

struct RowingMetricsPatch {
    var elapsedTime: TimeInterval?
    var distance: Double?
    var strokeRate: Int?
    var pace: TimeInterval?
    var powerWatts: Int?
    var calories: Int?
    var heartRate: Int?
}

extension RowingMetrics {
    mutating func apply(_ patch: RowingMetricsPatch) {
        connected = true
        elapsedTime = patch.elapsedTime ?? elapsedTime
        distance = patch.distance ?? distance
        strokeRate = patch.strokeRate ?? strokeRate
        pace = patch.pace ?? pace
        powerWatts = patch.powerWatts ?? powerWatts
        calories = patch.calories ?? calories
        heartRate = patch.heartRate ?? heartRate
        lastUpdatedAt = .now
    }
}

enum RowingConnectionPhase: String {
    case idle
    case scanning
    case connecting
    case connected
    case disconnecting
    case error
}

extension RowingConnectionPhase {
    var title: String {
        switch self {
        case .idle:
            "Ready"
        case .scanning:
            "Scanning"
        case .connecting:
            "Connecting"
        case .connected:
            "Connected"
        case .disconnecting:
            "Disconnecting"
        case .error:
            "Attention"
        }
    }

    var systemImage: String {
        switch self {
        case .idle:
            "pause.circle.fill"
        case .scanning:
            "dot.radiowaves.left.and.right"
        case .connecting:
            "link.circle.fill"
        case .connected:
            "checkmark.circle.fill"
        case .disconnecting:
            "xmark.circle.fill"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }
}

struct PM5DeviceSummary: Identifiable, Equatable {
    let id: UUID
    let name: String
    let localName: String?
    let rssi: Int
    let serviceUUIDs: [String]
}

struct PM5DiscoveredServiceSnapshot: Identifiable, Equatable {
    let uuid: String
    let characteristics: [String]

    var id: String { uuid }
}
