import Foundation

enum PM5CSafeProtocol {
    private static let frameStart: UInt8 = 0xF1
    private static let frameEnd: UInt8 = 0xF2
    private static let stuffMarker: UInt8 = 0xF3
    private static let pmWrapperCommand: UInt8 = 0x1A
    private static let getForcePlotDataCommand: UInt8 = 0x6B

    static func forceCurveRequest(bytesToRead: UInt8 = 20) -> Data {
        let payload = [
            pmWrapperCommand,
            0x03,
            getForcePlotDataCommand,
            0x01,
            bytesToRead,
        ]

        let checksum = payload.reduce(0, ^)
        let framedBytes = [frameStart] + stuff(bytes: payload + [checksum]) + [frameEnd]
        return Data(framedBytes)
    }

    static func parseForceCurveResponse(from frame: [UInt8]) -> PM5CSafeForceCurveChunk? {
        guard frame.count >= 8,
              frame.first == frameStart,
              frame.last == frameEnd else {
            return nil
        }

        let payload = unstuff(bytes: Array(frame.dropFirst().dropLast()))
        guard payload.count >= 6 else { return nil }

        let checksum = payload.last!
        let commandBytes = Array(payload.dropLast())
        let calculatedChecksum = commandBytes.reduce(0, ^)

        guard checksum == calculatedChecksum,
              commandBytes[1] == pmWrapperCommand,
              commandBytes[3] == getForcePlotDataCommand else {
            return nil
        }

        let detailLength = Int(commandBytes[4])
        let dataStartIndex = 5
        let dataEndIndex = dataStartIndex + detailLength

        guard commandBytes.count >= dataEndIndex else { return nil }

        let dataBytes = Array(commandBytes[dataStartIndex ..< dataEndIndex])
        guard let bytesReturned = dataBytes.first else { return nil }

        let sampleBytes = Array(dataBytes.dropFirst().prefix(Int(bytesReturned)))
        let samples = stride(from: 0, to: sampleBytes.count - (sampleBytes.count % 2), by: 2).map { index in
            Double(UInt16(sampleBytes[index]) | (UInt16(sampleBytes[index + 1]) << 8))
        }

        return PM5CSafeForceCurveChunk(
            bytesReturned: Int(bytesReturned),
            samples: samples
        )
    }

    private static func stuff(bytes: [UInt8]) -> [UInt8] {
        bytes.flatMap { value -> [UInt8] in
            if (0xF0 ... 0xF3).contains(value) {
                return [stuffMarker, value - 0xF0]
            }

            return [value]
        }
    }

    private static func unstuff(bytes: [UInt8]) -> [UInt8] {
        var result: [UInt8] = []
        var index = 0

        while index < bytes.count {
            let value = bytes[index]

            if value == stuffMarker, index + 1 < bytes.count {
                result.append(0xF0 + bytes[index + 1])
                index += 2
            } else {
                result.append(value)
                index += 1
            }
        }

        return result
    }
}

struct PM5CSafeForceCurveChunk {
    let bytesReturned: Int
    let samples: [Double]
}
