import Foundation

struct PM5CSafeFrameDecoder {
    private var buffer: [UInt8] = []

    mutating func append(_ data: Data) -> [[UInt8]] {
        buffer.append(contentsOf: data)

        var frames: [[UInt8]] = []

        while let startIndex = buffer.firstIndex(of: 0xF1) {
            if startIndex > 0 {
                buffer.removeFirst(startIndex)
            }

            guard let endIndex = buffer.dropFirst().firstIndex(of: 0xF2) else {
                break
            }

            frames.append(Array(buffer[0 ... endIndex]))
            buffer.removeFirst(endIndex + 1)
        }

        if let lastStart = buffer.lastIndex(of: 0xF1), lastStart > 0 {
            buffer.removeFirst(lastStart)
        }

        return frames
    }

    mutating func reset() {
        buffer = []
    }
}
