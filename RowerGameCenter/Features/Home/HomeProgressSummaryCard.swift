import SwiftUI

struct HomeProgressSummaryCard: View {
    @Environment(HealthSyncManager.self) private var healthSyncManager

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        PanelCard(title: "Training Progress", subtitle: "Distance, streaks, XP, and milestones from your synced rows.") {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch healthSyncManager.authorizationState {
        case .unavailable:
            ContentUnavailableView(
                "Apple Health Unavailable",
                systemImage: "heart.slash",
                description: Text("Training stats appear on a physical iPhone once Apple Health is available.")
            )
        case .notDetermined, .denied:
            permissionPrompt
        case .authorized:
            authorizedContent
        }
    }

    private var permissionPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enable Apple Health to unlock streaks, XP, milestones, and personal ghosts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(permissionButtonTitle) {
                healthSyncManager.requestAuthorization()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        if healthSyncManager.isLoadingRecentWorkouts, healthSyncManager.trainingOverview == nil {
            ProgressView("Loading training stats…")
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let historyErrorMessage = healthSyncManager.historyErrorMessage {
            VStack(alignment: .leading, spacing: 12) {
                Label(historyErrorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.warning)

                Button("Retry") {
                    healthSyncManager.refreshTrainingInsights()
                }
                .buttonStyle(.bordered)
            }
        } else if let overview = healthSyncManager.trainingOverview {
            VStack(alignment: .leading, spacing: 18) {
                levelBanner(for: overview)

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    MetricTile(title: "Total Rowed", value: AppFormatters.kilometers(overview.totalDistanceMeters))
                    MetricTile(title: "Current Streak", value: "\(overview.currentStreakDays) days")
                    MetricTile(title: "This Week", value: AppFormatters.kilometers(overview.distanceThisWeekMeters))
                    MetricTile(title: "Workouts", value: "\(overview.totalWorkouts)")
                }

                badgeStrip
            }
        } else {
            ContentUnavailableView(
                "No Training Data Yet",
                systemImage: "figure.rower",
                description: Text("Finish your first synced workout to start building distance, streaks, and XP.")
            )
        }
    }

    private func levelBanner(for overview: TrainingOverview) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(overview.level)")
                        .font(.title2.weight(.bold))

                    Text("\(overview.xp) total XP")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Best streak")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("\(overview.longestStreakDays) days")
                        .font(.headline.weight(.semibold))
                }
            }

            ProgressView(value: overview.progressToNextLevel)
                .tint(AppTheme.tint)

            HStack {
                Text("\(overview.xpIntoCurrentLevel) / \(overview.xpForNextLevel) XP to next level")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                if let lastWorkoutDate = overview.lastWorkoutDate {
                    Text(AppFormatters.relativeTimestamp(lastWorkoutDate))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(levelBannerBackground)
    }

    @ViewBuilder
    private var levelBannerBackground: some View {
        if #available(iOS 26, *) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.tint.opacity(0.10))
                .glassEffect(
                    .regular
                        .tint(AppTheme.tint.opacity(0.12)),
                    in: .rect(cornerRadius: 24)
                )
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.tint.opacity(0.10))
        }
    }

    private var badgeStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Milestones")
                .font(.subheadline.weight(.semibold))

            ForEach(healthSyncManager.trainingBadges.prefix(3)) { badge in
                HStack(spacing: 12) {
                    Image(systemName: badge.systemImage)
                        .font(.headline)
                        .foregroundStyle(badge.isUnlocked ? AppTheme.success : .secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            (badge.isUnlocked ? AppTheme.success : AppTheme.separator)
                                .opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(badge.title)
                            .font(.subheadline.weight(.semibold))

                        Text(badge.progressLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    if badge.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.success)
                    } else {
                        Text("\(Int((badge.progress * 100).rounded()))%")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var permissionButtonTitle: String {
        switch healthSyncManager.authorizationState {
        case .denied:
            "Review Apple Health Access"
        case .unavailable, .notDetermined, .authorized:
            "Enable Apple Health"
        }
    }
}
