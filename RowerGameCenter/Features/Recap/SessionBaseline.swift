import Foundation

struct SessionBaseline {
    var distanceMeters: Double?
    var elapsedTime: TimeInterval?

    var isCaptured: Bool {
        distanceMeters != nil || elapsedTime != nil
    }

    mutating func captureIfNeeded(from metrics: RowingMetrics) {
        if distanceMeters == nil {
            distanceMeters = metrics.distance ?? 0
        }

        if elapsedTime == nil {
            elapsedTime = metrics.elapsedTime ?? 0
        }
    }

    mutating func reset() {
        distanceMeters = nil
        elapsedTime = nil
    }

    func distanceDelta(for metrics: RowingMetrics) -> Double? {
        guard let currentDistance = metrics.distance else { return nil }
        return max(currentDistance - (distanceMeters ?? currentDistance), 0)
    }

    func elapsedDelta(for metrics: RowingMetrics) -> TimeInterval? {
        guard let currentElapsed = metrics.elapsedTime else { return nil }
        return max(currentElapsed - (elapsedTime ?? currentElapsed), 0)
    }
}
