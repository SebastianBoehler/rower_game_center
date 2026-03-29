import SwiftUI

struct GhostRaceTrackView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let playerProgress: Double
    let ghostProgress: Double
    let distanceTitle: String

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                raceLane(
                    title: "You",
                    systemImage: "figure.rower",
                    tint: AppTheme.tint,
                    progress: playerProgress,
                    width: geometry.size.width
                )

                raceLane(
                    title: "Ghost",
                    systemImage: "hare.fill",
                    tint: AppTheme.success,
                    progress: ghostProgress,
                    width: geometry.size.width
                )

                HStack {
                    Text("0 m")
                    Spacer()
                    Text(distanceTitle)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
            }
        }
    }

    private func raceLane(
        title: String,
        systemImage: String,
        tint: Color,
        progress: Double,
        width: CGFloat
    ) -> some View {
        let clampedProgress = min(max(progress, 0), 1)
        let usableWidth = max(width - 106, 0)

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.trackFill)
                .frame(height: 64)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.trackLane)
                .frame(height: 4)
                .padding(.horizontal, 22)

            finishLine
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 20)

            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(tint)
            .padding(.leading, 16)

            Circle()
                .fill(tint)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .offset(x: 74 + usableWidth * clampedProgress)
                .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: clampedProgress)
        }
    }

    private var finishLine: some View {
        VStack(spacing: 4) {
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(index.isMultiple(of: 2) ? AppTheme.tint : AppTheme.trackLane)
                    .frame(width: 7, height: 8)
            }
        }
    }
}
