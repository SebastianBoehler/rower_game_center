import Foundation

struct PM5ForceCurveAssembler {
    private var expectedPacketCount: Int?
    private var packets: [Int: [Double]] = [:]

    mutating func ingest(
        _ packet: PM5ForceCurvePacket,
        capturedAt: Date = .now
    ) -> ForceCurveStroke? {
        guard !packet.samples.isEmpty else { return nil }

        if packet.totalPackets <= 1 {
            reset()
            return ForceCurveStroke(capturedAt: capturedAt, samples: packet.samples)
        }

        if expectedPacketCount != packet.totalPackets {
            expectedPacketCount = packet.totalPackets
            packets = [:]
        }

        packets[packet.sequenceNumber] = packet.samples

        guard let orderedPackets = assembledPackets(total: packet.totalPackets) else {
            return nil
        }

        reset()
        return ForceCurveStroke(
            capturedAt: capturedAt,
            samples: orderedPackets.flatMap { $0 }
        )
    }

    mutating func reset() {
        expectedPacketCount = nil
        packets = [:]
    }

    private func assembledPackets(total: Int) -> [[Double]]? {
        let zeroBasedOrder = Array(0 ..< total)
        if zeroBasedOrder.allSatisfy({ packets[$0] != nil }) {
            return zeroBasedOrder.compactMap { packets[$0] }
        }

        let oneBasedOrder = Array(1 ... total)
        if oneBasedOrder.allSatisfy({ packets[$0] != nil }) {
            return oneBasedOrder.compactMap { packets[$0] }
        }

        return nil
    }
}
