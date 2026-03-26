import Foundation

extension Data {
    func byte(at offset: Int) -> UInt8 {
        self[startIndex.advanced(by: offset)]
    }

    func uint16LE(at offset: Int) -> UInt16 {
        UInt16(byte(at: offset)) | (UInt16(byte(at: offset + 1)) << 8)
    }

    func uint24LE(at offset: Int) -> UInt32 {
        UInt32(byte(at: offset))
            | (UInt32(byte(at: offset + 1)) << 8)
            | (UInt32(byte(at: offset + 2)) << 16)
    }
}
