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
