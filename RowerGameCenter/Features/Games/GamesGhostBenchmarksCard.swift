import SwiftUI

struct GamesGhostBenchmarksCard: View {
    @Environment(HealthSyncManager.self) private var healthSyncManager

    var body: some View {
        PanelCard(
            title: "Ghosts + Benchmarks",
            subtitle: "Your synced workouts generate local ghosts, segment targets, and a personal best board."
        ) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch healthSyncManager.authorizationState {
        case .unavailable:
            Text("Apple Health is unavailable here, so Ghost Race cannot build personal targets on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .notDetermined, .denied:
            Text("Enable Apple Health to build benchmark ghosts from your own rowing history.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .authorized:
            authorizedContent
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        if healthSyncManager.isLoadingRecentWorkouts, healthSyncManager.ghostBenchmarks.isEmpty {
            ProgressView("Building benchmark ghosts…")
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let historyErrorMessage = healthSyncManager.historyErrorMessage {
            Label(historyErrorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(AppTheme.warning)
        } else if healthSyncManager.ghostBenchmarks.isEmpty {
            Text("Finish a synced workout to generate your first benchmark ghost.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink(value: GameRoute.ghostRace) {
                    HStack {
                        Label("Open Ghost Race", systemImage: "hare.fill")
                            .font(.subheadline.weight(.semibold))

                        Spacer(minLength: 12)

                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(AppTheme.tint)
                    }
                }
                .buttonStyle(.plain)

                VStack(spacing: 12) {
                    ForEach(healthSyncManager.ghostBenchmarks) { benchmark in
                        BenchmarkRow(benchmark: benchmark)
                    }
                }

                if !healthSyncManager.personalBestBoard.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Personal Best Board")
                            .font(.subheadline.weight(.semibold))

                        ForEach(healthSyncManager.personalBestBoard.prefix(4)) { entry in
                            HStack(spacing: 12) {
                                Image(systemName: entry.systemImage)
                                    .foregroundStyle(AppTheme.tint)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title)
                                        .font(.subheadline.weight(.semibold))

                                    Text(entry.detail)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 12)

                                Text(entry.metric)
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct BenchmarkRow: View {
    let benchmark: TrainingBenchmark

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(benchmark.distance.ghostTitle.capitalized)
                    .font(.subheadline.weight(.semibold))

                Text(benchmark.sourceSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(AppFormatters.duration(benchmark.bestTime))
                    .font(.headline.weight(.semibold))
                    .monospacedDigit()

                Text(AppFormatters.pace(benchmark.pace))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
