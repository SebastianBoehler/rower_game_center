@preconcurrency import CoreBluetooth
import Foundation

enum PM5Parsers {
    static func patch(
        for characteristicUUID: CBUUID,
        data: Data
    ) -> RowingMetricsPatch? {
        switch characteristicUUID.uuidString.uppercased() {
        case PM5UUIDs.rowingStatus:
            return parseRowingStatus(data)
        case PM5UUIDs.extraStatus1:
            return parseExtraStatus1(data)
        case PM5UUIDs.extraStatus2:
            return parseExtraStatus2(data)
        case PM5UUIDs.extraStrokeData:
            return parseExtraStrokeData(data)
        default:
            return nil
        }
    }

    private static func parseRowingStatus(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 6 else { return nil }

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            distance: Double(data.uint24LE(at: 3)) / 10
        )
    }

    private static func parseExtraStatus1(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 11 else { return nil }

        let heartRate = Int(data.byte(at: 6))

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            strokeRate: Int(data.byte(at: 5)),
            pace: Double(data.uint16LE(at: 7)) / 100,
            heartRate: heartRate == 255 ? nil : heartRate
        )
    }

    private static func parseExtraStatus2(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 8 else { return nil }

        let averagePower = data.count >= 20 ? Int(data.uint16LE(at: 4)) : nil

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            powerWatts: averagePower,
            calories: Int(data.uint16LE(at: 6))
        )
    }

    private static func parseExtraStrokeData(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 5 else { return nil }

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            powerWatts: Int(data.uint16LE(at: 3))
        )
    }
}
