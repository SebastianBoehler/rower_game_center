import SwiftUI

struct TempleErgTrackView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let obstacles: [TempleErgObstacle]
    let currentReading: TempleErgActionReading
    let lives: Int

    private let laneShape = RoundedRectangle(cornerRadius: 34, style: .continuous)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background

                templeSilhouette

                lane

                actionZone
                    .frame(width: geometry.size.width * 0.18)
                    .padding(.leading, geometry.size.width * 0.08)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(obstacles) { obstacle in
                    obstacleView(obstacle, width: geometry.size.width)
                }

                playerView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, geometry.size.width * 0.12)

                topHUD
            }
            .clipShape(laneShape)
            .overlay {
                laneShape
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.17, green: 0.10, blue: 0.06),
                Color(red: 0.42, green: 0.22, blue: 0.10),
                Color(red: 0.83, green: 0.48, blue: 0.18),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var templeSilhouette: some View {
        VStack {
            HStack(spacing: 18) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .frame(width: 38, height: 150)
                }
            }
            .padding(.top, 42)

            Spacer()
        }
    }

    private var lane: some View {
        VStack {
            Spacer()

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.black.opacity(0.18))
                .frame(height: 168)
                .padding(.horizontal, 26)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.12))
                        .frame(height: 5)
                        .padding(.horizontal, 70)
                }
                .padding(.bottom, 24)
        }
    }

    private var actionZone: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(currentReading.tint.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(currentReading.tint.opacity(0.42), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
            }
            .padding(.vertical, 28)
    }

    private var playerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            TempleErgActionChip(currentReading: currentReading)
                .padding(.leading, 4)

            ZStack {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: currentReading.systemImage)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(currentReading == .neutral ? 1 : 1.08)
                    .offset(y: playerOffsetY)
                    .shadow(color: currentReading.tint.opacity(0.42), radius: 16, y: 6)
                    .animation(reduceMotion ? nil : .spring(duration: 0.28, bounce: 0.38), value: currentReading.title)
            }

            Text(currentReading.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.bottom, 58)
    }

    private var topHUD: some View {
        VStack {
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < lives ? "shield.fill" : "shield.slash.fill")
                        .font(.headline)
                        .foregroundStyle(index < lives ? Color.white : Color.white.opacity(0.28))
                }

                Spacer()
            }
            .padding(20)

            Spacer()
        }
    }

    private func obstacleView(_ obstacle: TempleErgObstacle, width: CGFloat) -> some View {
        let horizontalInset = width * obstacle.position
        return TempleErgObstacleGlyph(obstacle: obstacle)
            .padding(.trailing, horizontalInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .animation(reduceMotion ? nil : .linear(duration: 0.12), value: obstacle.position)
    }

    private var playerOffsetY: CGFloat {
        switch currentReading {
        case .neutral:
            0
        case .action(.jump):
            -52
        case .action(.duck):
            34
        case .action(.smash):
            -10
        }
    }
}

private struct TempleErgActionChip: View {
    let currentReading: TempleErgActionReading

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: currentReading.systemImage)
            Text(currentReading.title.uppercased())
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(currentReading.tint.opacity(0.34), in: Capsule())
    }
}

private struct TempleErgObstacleGlyph: View {
    let obstacle: TempleErgObstacle

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: obstacle.action.systemImage)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            Text(obstacle.action.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(width: 118, height: 118)
        .background(obstacleBackground)
        .overlay(alignment: .bottom) {
            Text(obstacle.action.caption)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.bottom, 10)
        }
        .padding(.bottom, verticalOffset)
    }

    @ViewBuilder
    private var obstacleBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(obstacle.action.tint.opacity(obstacle.isResolved ? 0.22 : 0.72))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }
    }

    private var verticalOffset: CGFloat {
        switch obstacle.action {
        case .jump:
            138
        case .duck:
            40
        case .smash:
            96
        }
    }
}
