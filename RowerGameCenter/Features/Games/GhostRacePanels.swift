import SwiftUI

struct GhostRaceStatusStyle {
    let title: String
    let systemImage: String
    let tint: Color
}

struct GhostRaceOverlayContent {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color
    let actionTitle: String?
}

struct GhostRaceControlStrip: View {
    @Binding var selectedDistance: StandardRaceDistance

    let status: GhostRaceStatusStyle
    let benchmark: TrainingBenchmark?
    let primaryActionTitle: String?
    let primaryActionTint: Color
    let primaryAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Picker("Distance", selection: $selectedDistance) {
                ForEach(StandardRaceDistance.allCases) { distance in
                    Text(distance.title).tag(distance)
                }
            }
            .pickerStyle(.segmented)

            ViewThatFits {
                HStack(spacing: 10) {
                    statusPill

                    if let benchmark {
                        benchmarkPill(benchmark)
                    }

                    Spacer(minLength: 0)

                    if let primaryActionTitle {
                        actionButton(primaryActionTitle)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        statusPill

                        if let benchmark {
                            benchmarkPill(benchmark)
                        }
                    }

                    if let primaryActionTitle {
                        HStack {
                            Spacer()
                            actionButton(primaryActionTitle)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.34), Color(red: 0.07, green: 0.16, blue: 0.22).opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.20), radius: 18, y: 8)
    }

    private var statusPill: some View {
        Label(status.title, systemImage: status.systemImage)
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(status.tint.opacity(0.28), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
    }

    private func benchmarkPill(_ benchmark: TrainingBenchmark) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PB \(AppFormatters.duration(benchmark.bestTime))")
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text(AppFormatters.pace(benchmark.pace))
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.66))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func actionButton(_ title: String) -> some View {
        Button(title, action: primaryAction)
            .font(.subheadline.weight(.black))
            .buttonStyle(.borderedProminent)
            .tint(primaryActionTint)
    }
}

struct GhostRaceMetricBar: View {
    let elapsed: TimeInterval?
    let gapMeters: Double
    let pace: TimeInterval?
    let strokeRate: Int?

    var body: some View {
        HStack(spacing: 0) {
            metric(title: "Elapsed", value: AppFormatters.duration(elapsed))
            Divider().frame(height: 34).overlay(.white.opacity(0.08))
            metric(title: "Gap", value: AppFormatters.gapMeters(gapMeters))
            Divider().frame(height: 34).overlay(.white.opacity(0.08))
            metric(title: "Pace", value: AppFormatters.pace(pace))
            Divider().frame(height: 34).overlay(.white.opacity(0.08))
            metric(title: "Rate", value: AppFormatters.strokeRate(strokeRate))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.34), Color(red: 0.06, green: 0.12, blue: 0.18).opacity(0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))

            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GhostRaceSetupOverlay: View {
    let content: GhostRaceOverlayContent
    let primaryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(content.tint.opacity(0.22))
                    .frame(width: 62, height: 62)

                Image(systemName: content.systemImage)
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text(content.title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(content.message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let title = content.actionTitle, let primaryAction {
                Button(title, action: primaryAction)
                    .font(.headline.weight(.black))
                    .buttonStyle(.borderedProminent)
                    .tint(content.tint)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 20, y: 8)
    }
}
