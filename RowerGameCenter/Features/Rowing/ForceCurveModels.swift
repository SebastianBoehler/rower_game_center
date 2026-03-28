import Foundation

struct PM5ForceCurvePacket {
    let totalPackets: Int
    let sequenceNumber: Int
    let samples: [Double]
}

struct ForceCurveStroke {
    let capturedAt: Date
    let samples: [Double]

    var sampleCount: Int {
        samples.count
    }
}

enum StrokeShapeFeedback: String {
    case balanced
    case earlyPeak
    case latePeak
    case spikyDrive
    case flatDrive
}

struct StrokeShapeAssessment {
    let score: Int
    let feedback: StrokeShapeFeedback
    let peakProgress: Double
    let smoothness: Double
}
