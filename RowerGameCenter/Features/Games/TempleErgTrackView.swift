import SwiftUI

struct TempleErgTrackView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let obstacles: [TempleErgObstacle]
    let currentReading: TempleErgActionReading
    let lives: Int

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                TempleErgSceneBackdrop(currentReading: currentReading, size: size)

                ForEach(obstacles) { obstacle in
                    obstacleView(obstacle, in: size)
                }

                playerView(size: size)

                topHUD
            }
            .clipped()
        }
    }

    private func obstacleView(_ obstacle: TempleErgObstacle, in size: CGSize) -> some View {
        let progress = obstacleProgress(for: obstacle)
        let scale = 0.52 + (progress * 0.82)
        let opacity = obstacle.isResolved ? 0.34 : min(1, 0.38 + (progress * 0.72))

        return TempleErgObstacleSprite(obstacle: obstacle)
            .frame(width: 160, height: 160)
            .scaleEffect(scale)
            .position(
                x: obstacleX(for: obstacle, width: size.width),
                y: obstacleY(for: obstacle, height: size.height)
            )
            .opacity(opacity)
            .shadow(color: obstacle.action.tint.opacity(0.28), radius: 24, y: 12)
            .animation(reduceMotion ? nil : .linear(duration: 0.12), value: obstacle.position)
    }

    private func playerView(size: CGSize) -> some View {
        VStack {
            Spacer()

            TempleErgRunnerSprite(currentReading: currentReading)
                .frame(width: 160, height: 190)
                .offset(y: playerOffsetY)
                .padding(.leading, size.width * 0.09)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 52)
                .animation(reduceMotion ? nil : .spring(duration: 0.32, bounce: 0.34), value: currentReading.title)
        }
    }

    private var topHUD: some View {
        VStack {
            HStack(spacing: 10) {
                ForEach(0 ..< 3, id: \.self) { index in
                    Image(systemName: index < lives ? "heart.fill" : "heart.slash.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(index < lives ? Color(red: 1.00, green: 0.62, blue: 0.46) : Color.white.opacity(0.30))
                        .padding(10)
                        .background(.thinMaterial, in: Circle())
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 72)

            Spacer()
        }
    }

    private func obstacleProgress(for obstacle: TempleErgObstacle) -> CGFloat {
        let travel = TempleErgScene.spawnPosition - TempleErgScene.playerZonePosition
        let normalized = (TempleErgScene.spawnPosition - obstacle.position) / travel
        return CGFloat(max(0, min(normalized, 1.2)))
    }

    private func obstacleX(for obstacle: TempleErgObstacle, width: CGFloat) -> CGFloat {
        let progress = obstacleProgress(for: obstacle)
        let startX = width * 0.92
        let playerX = width * 0.34
        return startX - ((startX - playerX) * progress)
    }

    private func obstacleY(for obstacle: TempleErgObstacle, height: CGFloat) -> CGFloat {
        switch obstacle.action {
        case .jump:
            height * 0.77
        case .duck:
            height * 0.57
        case .smash:
            height * 0.68
        }
    }

    private var playerOffsetY: CGFloat {
        switch currentReading {
        case .neutral: 0
        case .action(.jump): -58
        case .action(.duck): 36
        case .action(.smash): -8
        }
    }
}
