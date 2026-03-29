import SwiftUI

struct SessionRecapView: View {
    @Environment(SessionRecapManager.self) private var recapManager

    let recap: SessionRecap

    @State private var shareURL: URL?
    @State private var shareErrorMessage: String?
    @State private var isRenderingShareImage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                posterPreview
                metricsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Share Recap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    recapManager.dismissActiveRecap()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            shareBar
        }
        .task(id: recap.id) {
            renderShareAsset()
        }
    }

    private var summaryCard: some View {
        PanelCard(title: recap.category, subtitle: recap.subtitle) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Label(recap.title, systemImage: recap.systemImage)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(recap.tint)

                    Spacer(minLength: 12)

                    Text(recap.recordedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(recap.heroValue)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()

                Text(recap.heroLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var posterPreview: some View {
        PanelCard(title: "Share Image", subtitle: "A branded image is generated automatically so the result is ready for Instagram, Messages, or any share target.") {
            SessionRecapSharePoster(recap: recap)
                .aspectRatio(1080.0 / 1350.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(AppTheme.separator.opacity(0.12), lineWidth: 1)
                }
        }
    }

    private var metricsCard: some View {
        PanelCard(title: "What to Share", subtitle: "Keep the best numbers and the narrative visible so the post does real promotional work.") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(recap.metrics) { metric in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(metric.title)
                                .font(.subheadline.weight(.semibold))

                            Spacer(minLength: 12)

                            Text(metric.value)
                                .font(.subheadline.weight(.bold))
                                .monospacedDigit()
                        }

                        if let detail = metric.detail {
                            Text(detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !recap.highlights.isEmpty {
                    Divider()

                    ForEach(recap.highlights, id: \.self) { highlight in
                        Label(highlight, systemImage: "sparkles")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var shareBar: some View {
        VStack(spacing: 10) {
            if let shareErrorMessage {
                Label(shareErrorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                if let shareURL {
                    ShareLink(item: shareURL) {
                        Label("Share Image", systemImage: "square.and.arrow.up.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .modifier(RecapPrimaryButtonStyle())
                } else if isRenderingShareImage {
                    ProgressView("Preparing share image…")
                        .frame(maxWidth: .infinity)
                } else {
                    Button("Retry Image Export", action: renderShareAsset)
                        .modifier(RecapPrimaryButtonStyle())
                }

                Button("Done") {
                    recapManager.dismissActiveRecap()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }

    private func renderShareAsset() {
        shareURL = nil
        shareErrorMessage = nil
        isRenderingShareImage = true

        do {
            shareURL = try SessionRecapShareExporter.exportImage(for: recap)
            isRenderingShareImage = false
        } catch {
            shareURL = nil
            shareErrorMessage = error.localizedDescription
            isRenderingShareImage = false
        }
    }
}

private struct RecapPrimaryButtonStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .buttonStyle(.glassProminent)
                .controlSize(.large)
        } else {
            content
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
