import SwiftUI

struct TempleErgObstacleSprite: View {
    let obstacle: TempleErgObstacle

    var body: some View {
        ZStack {
            obstacleBody

            if obstacle.wasSuccessful {
                Image(systemName: "sparkles")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .offset(y: -54)
            }
        }
        .opacity(obstacle.isResolved ? 0.55 : 1)
    }

    @ViewBuilder
    private var obstacleBody: some View {
        switch obstacle.action {
        case .jump:
            VStack(spacing: 0) {
                TempleErgSpikeField()
                    .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top))
                    .frame(width: 120, height: 56)
                Capsule()
                    .fill(.black.opacity(0.22))
                    .frame(width: 132, height: 18)
            }
        case .duck:
            ZStack(alignment: .bottom) {
                HStack(spacing: 32) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.47, green: 0.36, blue: 0.24))
                        .frame(width: 28, height: 120)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.47, green: 0.36, blue: 0.24))
                        .frame(width: 28, height: 120)
                }

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.61, green: 0.48, blue: 0.30))
                    .frame(width: 138, height: 34)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    }
                    .offset(y: -38)
            }
        case .smash:
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.74, green: 0.28, blue: 0.22), Color(red: 0.45, green: 0.13, blue: 0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(spacing: 12) {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 110, height: 12)
                    }
                }

                Image(systemName: "burst.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .frame(width: 132, height: 112)
        }
    }
}

struct TempleErgRunnerSprite: View {
    let currentReading: TempleErgActionReading

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.22))
                .frame(width: 118, height: 24)
                .offset(y: 72)

            if currentReading == .action(.smash) {
                Capsule()
                    .fill(currentReading.tint.opacity(0.46))
                    .frame(width: 74, height: 18)
                    .rotationEffect(.degrees(-32))
                    .offset(x: 56, y: -4)
                    .blur(radius: 4)
            }

            Capsule()
                .fill(Color(red: 0.90, green: 0.60, blue: 0.34))
                .frame(width: 18, height: 66)
                .rotationEffect(.degrees(torsoAngle))
                .offset(x: 4, y: -2)

            Capsule().fill(Color(red: 0.16, green: 0.24, blue: 0.33)).frame(width: 28, height: 82).rotationEffect(.degrees(torsoAngle)).offset(y: -6)
            Capsule().fill(currentReading.tint.opacity(0.94)).frame(width: 14, height: 64).rotationEffect(.degrees(-34)).offset(x: 36, y: -18)
            Capsule().fill(.white.opacity(0.92)).frame(width: 14, height: 64).rotationEffect(.degrees(leftArmAngle)).offset(x: -28, y: -12)
            Capsule().fill(Color(red: 0.09, green: 0.11, blue: 0.14)).frame(width: 15, height: 76).rotationEffect(.degrees(leftLegAngle)).offset(x: -16, y: 56)
            Capsule().fill(Color(red: 0.09, green: 0.11, blue: 0.14)).frame(width: 15, height: 76).rotationEffect(.degrees(rightLegAngle)).offset(x: 18, y: 58)

            Circle()
                .fill(Color(red: 0.95, green: 0.78, blue: 0.60))
                .frame(width: 28, height: 28)
                .offset(x: 10, y: -64)

            Circle()
                .fill(.black.opacity(0.18))
                .frame(width: 12, height: 12)
                .offset(x: 12, y: -72)
        }
    }

    private var torsoAngle: Double {
        switch currentReading {
        case .neutral, .action(.jump): -4
        case .action(.duck): 18
        case .action(.smash): -20
        }
    }

    private var leftArmAngle: Double {
        switch currentReading {
        case .neutral: 18
        case .action(.jump): -14
        case .action(.duck): 52
        case .action(.smash): 64
        }
    }

    private var leftLegAngle: Double {
        switch currentReading {
        case .neutral: 16
        case .action(.jump): -24
        case .action(.duck): 72
        case .action(.smash): 28
        }
    }

    private var rightLegAngle: Double {
        switch currentReading {
        case .neutral: -12
        case .action(.jump): 34
        case .action(.duck): 16
        case .action(.smash): -36
        }
    }
}

struct TempleErgSpikeField: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let spikeCount = 6
            let spikeWidth = rect.width / CGFloat(spikeCount)

            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))

            for index in 0 ..< spikeCount {
                let startX = rect.minX + CGFloat(index) * spikeWidth
                path.addLine(to: CGPoint(x: startX + (spikeWidth / 2), y: rect.minY))
                path.addLine(to: CGPoint(x: startX + spikeWidth, y: rect.maxY))
            }

            path.closeSubpath()
        }
    }
}
