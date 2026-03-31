import SwiftUI

struct GhostRaceTrackView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let playerProgress: Double
    let ghostProgress: Double
    let gapMeters: Double
    let distanceTitle: String
    let ghostReady: Bool
    let isConnected: Bool

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                arenaBackground

                VStack(spacing: max(16, size.height * 0.055)) {
                    GhostRaceGapBanner(
                        title: bannerTitle,
                        tint: bannerTint
                    )

                    lane(
                        title: "YOU",
                        systemImage: "figure.rower",
                        tint: AppTheme.tint,
                        progress: playerProgress,
                        width: size.width,
                        isGhost: false,
                        dimmed: !isConnected
                    )

                    lane(
                        title: ghostReady ? "GHOST" : "GHOST LOCKED",
                        systemImage: "hare.fill",
                        tint: AppTheme.success,
                        progress: ghostReady ? ghostProgress : 0,
                        width: size.width,
                        isGhost: true,
                        dimmed: !ghostReady
                    )

                    footer
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
        }
    }

    private var arenaBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.17),
                    Color(red: 0.05, green: 0.16, blue: 0.22),
                    Color(red: 0.03, green: 0.10, blue: 0.16),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.tint.opacity(0.20))
                .frame(width: 240, height: 240)
                .blur(radius: 36)
                .offset(x: 120, y: -140)

            Circle()
                .fill(AppTheme.success.opacity(0.12))
                .frame(width: 210, height: 210)
                .blur(radius: 42)
                .offset(x: -110, y: 120)

            VStack(spacing: 14) {
                ForEach(0 ..< 6, id: \.self) { _ in
                    Capsule()
                        .fill(.white.opacity(0.04))
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func lane(
        title: String,
        systemImage: String,
        tint: Color,
        progress: Double,
        width: CGFloat,
        isGhost: Bool,
        dimmed: Bool
    ) -> some View {
        let clampedProgress = CGFloat(min(max(progress, 0), 1))
        let usableWidth = max(width - 158, 0)
        let leadingInset: CGFloat = 84
        let wakeWidth = max(22, usableWidth * clampedProgress)
        let laneTint = dimmed ? .white.opacity(0.30) : tint

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.10), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 104)

            Capsule()
                .fill(.white.opacity(0.08))
                .frame(height: 8)
                .padding(.horizontal, 24)

            Capsule()
                .fill(laneTint.opacity(dimmed ? 0.14 : 0.30))
                .frame(width: wakeWidth, height: 10)
                .offset(x: leadingInset)

            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption.weight(.black))
            .foregroundStyle(.white.opacity(dimmed ? 0.54 : 0.84))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.24), in: Capsule())
            .padding(.leading, 14)

            GhostRaceBoatSprite(
                systemImage: systemImage,
                tint: laneTint,
                isGhost: isGhost,
                dimmed: dimmed
            )
            .offset(x: leadingInset + (usableWidth * clampedProgress))
            .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: clampedProgress)

            GhostRaceFinishGate()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
        }
    }

    private var footer: some View {
        HStack {
            Text("START")
            Spacer()
            Text(distanceTitle.uppercased())
        }
        .font(.caption2.weight(.black))
        .foregroundStyle(.white.opacity(0.52))
        .padding(.horizontal, 6)
    }

    private var bannerTitle: String {
        if !ghostReady {
            return "Unlock a benchmark ghost"
        }

        if !isConnected {
            return "PM5 connection needed to launch"
        }

        let roundedGap = Int(abs(gapMeters).rounded())
        if roundedGap == 0 {
            return "Level race"
        }

        return gapMeters >= 0 ? "Ahead by \(roundedGap) m" : "Behind by \(roundedGap) m"
    }

    private var bannerTint: Color {
        if !ghostReady || !isConnected {
            return .white.opacity(0.82)
        }

        if abs(gapMeters) < 1 {
            return .white
        }

        return gapMeters >= 0 ? AppTheme.success : Color.orange
    }
}

private struct GhostRaceGapBanner: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .tracking(1.2)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(tint.opacity(0.20), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

private struct GhostRaceBoatSprite: View {
    let systemImage: String
    let tint: Color
    let isGhost: Bool
    let dimmed: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.black.opacity(0.22))
                .frame(width: 66, height: 26)
                .offset(x: 4, y: 8)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(dimmed ? 0.34 : 0.90))
                    .frame(width: 74, height: 30)

                Circle()
                    .fill(.white.opacity(dimmed ? 0.10 : 0.18))
                    .frame(width: 24, height: 24)
                    .padding(.leading, 8)

                Image(systemName: systemImage)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(dimmed ? 0.54 : 0.92))
                    .padding(.leading, 14)

                if isGhost {
                    Image(systemName: "sparkles")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(dimmed ? 0.30 : 0.64))
                        .padding(.leading, 50)
                }
            }
        }
    }
}

private struct GhostRaceFinishGate: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.white.opacity(0.10))
                .frame(width: 18, height: 74)

            VStack(spacing: 3) {
                ForEach(0 ..< 8, id: \.self) { index in
                    Rectangle()
                        .fill(index.isMultiple(of: 2) ? AppTheme.success : .white.opacity(0.88))
                        .frame(width: 10, height: 6)
                }
            }
        }
    }
}
