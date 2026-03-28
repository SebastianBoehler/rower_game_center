@preconcurrency import CoreBluetooth
import Foundation

enum PM5ParsedNotification {
    case metrics(RowingMetricsPatch)
    case forceCurve(PM5ForceCurvePacket)
}

enum PM5Parsers {
    static func notification(
        for characteristicUUID: CBUUID,
        data: Data
    ) -> PM5ParsedNotification? {
        switch characteristicUUID.uuidString.uppercased() {
        case PM5UUIDs.rowingStatus:
            return parseRowingStatus(data).map(PM5ParsedNotification.metrics)
        case PM5UUIDs.extraStatus1:
            return parseExtraStatus1(data).map(PM5ParsedNotification.metrics)
        case PM5UUIDs.extraStatus2:
            return parseExtraStatus2(data).map(PM5ParsedNotification.metrics)
        case PM5UUIDs.rowingStrokeData:
            return parseRowingStrokeData(data).map(PM5ParsedNotification.metrics)
        case PM5UUIDs.extraStrokeData:
            return parseExtraStrokeData(data).map(PM5ParsedNotification.metrics)
        case PM5UUIDs.forceCurveData:
            return parseForceCurveData(data).map(PM5ParsedNotification.forceCurve)
        default:
            return nil
        }
    }

    private static func parseRowingStatus(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 19 else { return nil }

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            distance: Double(data.uint24LE(at: 3)) / 10,
            strokeState: Int(data.byte(at: 10))
        )
    }

    private static func parseExtraStatus1(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 17 else { return nil }

        let heartRate = Int(data.byte(at: 6))

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            strokeRate: Int(data.byte(at: 5)),
            pace: Double(data.uint16LE(at: 7)) / 100,
            averagePace: Double(data.uint16LE(at: 9)) / 100,
            heartRate: heartRate == 255 ? nil : heartRate
        )
    }

    private static func parseExtraStatus2(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 20 else { return nil }

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            averagePowerWatts: Int(data.uint16LE(at: 4)),
            calories: Int(data.uint16LE(at: 6))
        )
    }

    private static func parseRowingStrokeData(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 18 else { return nil }

        let hasDirectPayload = data.count >= 20

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            distance: Double(data.uint24LE(at: 3)) / 10,
            strokeCount: Int(data.uint16LE(at: hasDirectPayload ? 18 : 16)),
            driveLengthMeters: Double(data.byte(at: 6)) / 100,
            driveTime: Double(data.byte(at: 7)) / 100,
            recoveryTime: Double(data.uint16LE(at: 8)) / 100,
            strokeDistanceMeters: Double(data.uint16LE(at: 10)) / 100,
            peakDriveForcePounds: Double(data.uint16LE(at: 12)) / 10,
            averageDriveForcePounds: Double(data.uint16LE(at: 14)) / 10,
            workPerStrokeJoules: hasDirectPayload ? Double(data.uint16LE(at: 16)) / 10 : nil
        )
    }

    private static func parseExtraStrokeData(_ data: Data) -> RowingMetricsPatch? {
        guard data.count >= 15 else { return nil }

        return RowingMetricsPatch(
            elapsedTime: Double(data.uint24LE(at: 0)) / 100,
            powerWatts: Int(data.uint16LE(at: 3)),
            strokeCount: Int(data.uint16LE(at: 7)),
            projectedWorkTime: Double(data.uint24LE(at: 9)),
            projectedWorkDistanceMeters: Double(data.uint24LE(at: 12)),
            workPerStrokeJoules: data.count >= 17 ? Double(data.uint16LE(at: 15)) / 10 : nil
        )
    }

    private static func parseForceCurveData(_ data: Data) -> PM5ForceCurvePacket? {
        guard data.count >= 2 else { return nil }

        let header = data.byte(at: 0)
        let rawPacketCount = Int(header >> 4)
        let packetCount = rawPacketCount == 0 ? 16 : rawPacketCount
        let wordCount = Int(header & 0x0F)
        let expectedLength = 2 + (wordCount * 2)

        guard data.count >= expectedLength else { return nil }

        let samples = data
            .uint16WordsLE(startingAt: 2, count: wordCount)
            .map(Double.init)

        return PM5ForceCurvePacket(
            totalPackets: packetCount,
            sequenceNumber: Int(data.byte(at: 1)),
            samples: samples
        )
    }
}
