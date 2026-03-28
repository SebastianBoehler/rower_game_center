import SwiftUI

struct LaneSprintTrackView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let distance: Double?
    let goalDistance: Double

    private var progress: Double {
        min((distance ?? 0) / goalDistance, 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.secondaryGroupedBackground, AppTheme.tertiaryGroupedBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.trackFill)
                    .padding(20)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppTheme.trackLane)
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                    .frame(maxHeight: .infinity)

                finishLine
                    .padding(.trailing, 30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

                boat
                    .offset(x: boatOffset(for: geometry.size.width))
                    .padding(.leading, 28)
                    .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: progress)

                distanceMarkers
            }
        }
    }

    private var boat: some View {
        Circle()
            .fill(AppTheme.tint)
            .frame(width: 50, height: 50)
            .overlay {
                Image(systemName: "figure.rower")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            .accessibilityHidden(true)
    }

    private var finishLine: some View {
        VStack(spacing: 6) {
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(index.isMultiple(of: 2) ? AppTheme.tint : AppTheme.trackLane)
                    .frame(width: 8, height: 14)
            }
        }
        .padding(.vertical, 28)
    }

    private var distanceMarkers: some View {
        VStack {
            Spacer()

            HStack {
                Text("0 m")
                Spacer()
                Text("250")
                Spacer()
                Text("500")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 34)
            .padding(.bottom, 18)
        }
    }

    private func boatOffset(for totalWidth: CGFloat) -> CGFloat {
        let usableWidth = max(totalWidth - 120, 0)
        return usableWidth * progress
    }
}
