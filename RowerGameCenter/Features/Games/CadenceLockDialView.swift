import SwiftUI

struct CadenceLockDialView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let strokeRate: Int?
    let targetRate: Int
    let tolerance: Int
    let targetRates: [Int]

    private let arcStart = 0.13
    private let arcEnd = 0.87

    private var floorRate: Int {
        targetRates.min() ?? targetRate
    }

    private var ceilingRate: Int {
        targetRates.max() ?? targetRate
    }

    private var minRate: Double {
        Double(floorRate - tolerance - 1)
    }

    private var maxRate: Double {
        Double(ceilingRate + tolerance + 1)
    }

    private var markerRates: [Int] {
        [floorRate, Int(round(Double(floorRate + ceilingRate) / 2.0)), ceilingRate]
    }

    private var clampedRate: Double {
        let rawRate = Double(strokeRate ?? targetRate)
        return min(max(rawRate, minRate), maxRate)
    }

    private var isLocked: Bool {
        guard let strokeRate else { return false }
        return abs(strokeRate - targetRate) <= tolerance
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.secondaryGroupedBackground, AppTheme.tertiaryGroupedBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .stroke(AppTheme.tertiaryGroupedBackground, lineWidth: 30)
                    .padding(size * 0.12)

                ringArc(from: minRate, to: maxRate, color: AppTheme.trackLane.opacity(0.4), lineWidth: 26)

                ringArc(
                    from: Double(targetRate - tolerance),
                    to: Double(targetRate + tolerance),
                    color: AppTheme.success,
                    lineWidth: 28
                )

                indicatorNeedle
                    .frame(width: size * 0.68, height: size * 0.68)
                    .rotationEffect(angle(for: clampedRate))
                    .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: clampedRate)

                VStack(spacing: 10) {
                    Text(AppFormatters.strokeRate(strokeRate))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Text(isLocked ? "Inside target band" : "Move into the green band")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isLocked ? AppTheme.success : .secondary)

                    Text("Target \(targetRate) spm")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                rateMarkers
            }
        }
    }

    private var indicatorNeedle: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppTheme.tint)
                .frame(width: 10, height: 82)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            Spacer()
        }
    }

    private var rateMarkers: some View {
        VStack {
            Spacer()

            HStack {
                Text("\(markerRates[0])")
                Spacer()
                Text("\(markerRates[1])")
                Spacer()
                Text("\(markerRates[2])")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 34)
            .padding(.bottom, 18)
        }
    }

    private func ringArc(from startRate: Double, to endRate: Double, color: Color, lineWidth: CGFloat) -> some View {
        Circle()
            .trim(from: progress(for: startRate), to: progress(for: endRate))
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-180))
            .padding(42)
    }

    private func progress(for rate: Double) -> Double {
        let normalized = (rate - minRate) / (maxRate - minRate)
        return arcStart + normalized * (arcEnd - arcStart)
    }

    private func angle(for rate: Double) -> Angle {
        let normalized = (rate - minRate) / (maxRate - minRate)
        return .degrees(-133 + normalized * 266)
    }
}
