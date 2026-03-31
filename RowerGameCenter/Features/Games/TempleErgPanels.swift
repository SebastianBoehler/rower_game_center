import SwiftUI

struct TempleErgHeaderCard: View {
    let currentReading: TempleErgActionReading
    let hint: String
    let isConnected: Bool
    let restartGame: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TEMPLE ERG")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white.opacity(0.72))
                        .tracking(1.6)

                    Text("Escape The Ruins")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 12)

                Button("Restart Run", action: restartGame)
                    .buttonStyle(.glass)
            }

            HStack(alignment: .top, spacing: 12) {
                StatusBadge(
                    title: isConnected ? currentReading.title : "Waiting for PM5",
                    systemImage: currentReading.systemImage,
                    tint: currentReading.tint
                )

                Text(hint)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            TempleErgActionLegend()
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.38), Color(red: 0.20, green: 0.13, blue: 0.10).opacity(0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.20), radius: 18, y: 8)
    }
}

struct TempleErgActionLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            ForEach(TempleErgAction.allCases) { action in
                HStack(spacing: 6) {
                    Image(systemName: action.systemImage)
                    Text(action.title)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(action.tint.opacity(0.26), in: Capsule())
            }
        }
    }
}

struct TempleErgHUDBar: View {
    let score: Int
    let combo: Int
    let clearedObstacles: Int
    let distance: Double
    let pace: TimeInterval?

    var body: some View {
        HStack(spacing: 0) {
            metric(title: "Score", value: "\(score)")
            Divider().frame(height: 34)
            metric(title: "Combo", value: "\(combo)x")
            Divider().frame(height: 34)
            metric(title: "Clears", value: "\(clearedObstacles)")
            Divider().frame(height: 34)
            metric(title: "Distance", value: AppFormatters.distance(distance))
            Divider().frame(height: 34)
            metric(title: "Pace", value: AppFormatters.pace(pace))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.40), Color(red: 0.23, green: 0.14, blue: 0.10).opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.weight(.semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TempleErgUnavailableOverlay: View {
    let isScanning: Bool
    let startScan: () -> Void
    let stopScan: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("TEMPLE ERG")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
                .tracking(2)

            Text("Connect A PM5 To Open The Gate")
                .font(.title2.weight(.black))
                .multilineTextAlignment(.center)

            Text("Strong bursts jump. Long recoveries duck. Heavy hits smash the barricades.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TempleErgActionLegend()

            Button(isScanning ? "Stop Scan" : "Scan for PM5") {
                if isScanning {
                    stopScan()
                } else {
                    startScan()
                }
            }
            .buttonStyle(.glassProminent)
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
        .padding(.horizontal, 24)
    }
}

struct TempleErgGameOverOverlay: View {
    let score: Int
    let clearedObstacles: Int
    let bestCombo: Int
    let restartGame: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text("Run Over")
                .font(.largeTitle.weight(.bold))

            Text("You cleared \(clearedObstacles) obstacles, stacked a \(bestCombo)x best combo, and finished with \(score) points.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Restart Run", action: restartGame)
                .buttonStyle(.glassProminent)
                .controlSize(.large)

            Button("Done") { dismiss() }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
        .padding(.horizontal, 40)
    }
}
