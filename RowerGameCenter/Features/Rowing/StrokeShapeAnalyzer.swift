import Foundation

enum StrokeShapeAnalyzer {
    static let displaySampleCount = 32

    static func referenceCurve(sampleCount: Int = displaySampleCount) -> [Double] {
        guard sampleCount > 1 else { return [] }

        let rawValues = (0 ..< sampleCount).map { index in
            let x = Double(index) / Double(sampleCount - 1)
            return pow(x, 1.3) * pow(1 - x, 1.8)
        }

        return normalize(rawValues)
    }

    static func normalizedCurve(
        from samples: [Double],
        sampleCount: Int = displaySampleCount
    ) -> [Double] {
        guard samples.count >= 2, sampleCount > 1 else { return [] }

        let resampled = (0 ..< sampleCount).map { index in
            let progress = Double(index) / Double(sampleCount - 1)
            return interpolatedValue(in: samples, progress: progress)
        }

        return normalize(resampled)
    }

    static func averageCurve(
        from strokes: [ForceCurveStroke],
        sampleCount: Int = displaySampleCount
    ) -> [Double]? {
        let normalizedStrokes = strokes
            .map { normalizedCurve(from: $0.samples, sampleCount: sampleCount) }
            .filter { !$0.isEmpty }

        guard !normalizedStrokes.isEmpty else { return nil }

        return (0 ..< sampleCount).map { index in
            normalizedStrokes
                .map { $0[index] }
                .reduce(0, +) / Double(normalizedStrokes.count)
        }
    }

    static func assessment(for stroke: ForceCurveStroke?) -> StrokeShapeAssessment? {
        guard let stroke else { return nil }

        let normalized = normalizedCurve(from: stroke.samples)
        guard !normalized.isEmpty else { return nil }

        let reference = referenceCurve()
        let peakIndex = normalized.indices.max(by: { normalized[$0] < normalized[$1] }) ?? 0
        let peakProgress = Double(peakIndex) / Double(max(normalized.count - 1, 1))
        let referencePeak = reference.indices.max(by: { reference[$0] < reference[$1] }).map {
            Double($0) / Double(max(reference.count - 1, 1))
        } ?? 0.38

        let rootMeanSquareError = sqrt(
            zip(normalized, reference)
                .map { pow($0 - $1, 2) }
                .reduce(0, +) / Double(normalized.count)
        )

        let slopeChanges = directionalChanges(in: normalized)
        let area = normalized.reduce(0, +) / Double(normalized.count)
        let smoothness = max(0, 1 - (Double(max(0, slopeChanges - 2)) / 6))

        let feedback: StrokeShapeFeedback
        if peakProgress < referencePeak - 0.09 {
            feedback = .earlyPeak
        } else if peakProgress > referencePeak + 0.10 {
            feedback = .latePeak
        } else if slopeChanges > 5 {
            feedback = .spikyDrive
        } else if area < 0.32 {
            feedback = .flatDrive
        } else {
            feedback = .balanced
        }

        let peakPenalty = abs(peakProgress - referencePeak) * 55
        let smoothnessBonus = smoothness * 12
        let score = Int(
            min(
                max(
                    round((1 - rootMeanSquareError) * 100 - peakPenalty + smoothnessBonus),
                    0
                ),
                100
            )
        )

        return StrokeShapeAssessment(
            score: score,
            feedback: feedback,
            peakProgress: peakProgress,
            smoothness: smoothness
        )
    }

    private static func interpolatedValue(in samples: [Double], progress: Double) -> Double {
        let scaledIndex = progress * Double(samples.count - 1)
        let lowerIndex = Int(floor(scaledIndex))
        let upperIndex = min(lowerIndex + 1, samples.count - 1)
        let fraction = scaledIndex - Double(lowerIndex)

        return samples[lowerIndex] + ((samples[upperIndex] - samples[lowerIndex]) * fraction)
    }

    private static func normalize(_ values: [Double]) -> [Double] {
        guard let peak = values.max(), peak > 0 else { return values.map { _ in 0 } }
        return values.map { $0 / peak }
    }

    private static func directionalChanges(in samples: [Double]) -> Int {
        let deltas = zip(samples.dropFirst(), samples).map { next, current in
            next - current
        }
        let directions = deltas.compactMap { delta -> Int? in
            guard abs(delta) > 0.015 else { return nil }
            return delta > 0 ? 1 : -1
        }

        return zip(directions.dropFirst(), directions)
            .filter { current, previous in current != previous }
            .count
    }
}
