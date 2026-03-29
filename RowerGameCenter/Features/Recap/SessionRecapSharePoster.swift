import SwiftUI

struct SessionRecapSharePoster: View {
    let recap: SessionRecap

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    recap.tint.opacity(0.88),
                    Color.black.opacity(0.94),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 36) {
                topBar
                heroSection
                metricsSection
                highlightsSection
                Spacer()
                footer
            }
            .padding(64)
        }
        .frame(width: 1080, height: 1350)
    }

    private var topBar: some View {
        HStack {
            Label(recap.category, systemImage: recap.systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 26)
                .padding(.vertical, 16)
                .background(.white.opacity(0.12), in: Capsule())

            Spacer()

            Text("Rower Game Center")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(recap.title)
                .font(.system(size: 82, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(recap.subtitle)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))

            VStack(alignment: .leading, spacing: 6) {
                Text(recap.heroValue)
                    .font(.system(size: 110, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text(recap.heroLabel.uppercased())
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    private var metricsSection: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(recap.metrics.prefix(4)) { metric in
                VStack(alignment: .leading, spacing: 12) {
                    Text(metric.title.uppercased())
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.68))

                    Text(metric.value)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    if let detail = metric.detail {
                        Text(detail)
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
        }
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Highlights")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            ForEach(recap.highlights, id: \.self) { highlight in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.white.opacity(0.84))
                        .frame(width: 10, height: 10)
                        .padding(.top, 12)

                    Text(highlight)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recap.footer)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))

            Text(recap.recordedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
    }
}
