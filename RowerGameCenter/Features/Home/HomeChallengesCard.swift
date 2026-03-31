import SwiftUI

struct HomeChallengesCard: View {
    @Environment(HealthSyncManager.self) private var healthSyncManager
    @Environment(AppNavigationModel.self) private var navigationModel

    var body: some View {
        PanelCard(title: "Challenges", subtitle: "Small daily and weekly goals that turn raw volume into momentum.") {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch healthSyncManager.authorizationState {
        case .unavailable:
            Text("Apple Health is unavailable on this device, so challenge progress cannot be calculated here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .notDetermined, .denied:
            Text("Enable Apple Health to track challenge progress automatically from your synced workouts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .authorized:
            authorizedContent
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        if healthSyncManager.isLoadingRecentWorkouts, healthSyncManager.trainingChallenges.isEmpty {
            ProgressView("Loading challenge progress…")
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let historyErrorMessage = healthSyncManager.historyErrorMessage {
            Label(historyErrorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(AppTheme.warning)
        } else if healthSyncManager.trainingChallenges.isEmpty {
            Text("Finish a synced workout to start tracking challenge progress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            let incomplete = healthSyncManager.trainingChallenges.filter { !$0.isCompleted }

            VStack(spacing: 14) {
                ForEach(healthSyncManager.trainingChallenges) { challenge in
                    ChallengeRow(challenge: challenge)
                }

                if !incomplete.isEmpty {
                    Button {
                        navigationModel.openGamesLibrary()
                    } label: {
                        Label("Play a Game", systemImage: "gamecontroller.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
    }
}

private struct ChallengeRow: View {
    let challenge: TrainingChallengeProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: challenge.systemImage)
                    .font(.headline)
                    .foregroundStyle(challenge.isCompleted ? AppTheme.success : AppTheme.tint)
                    .frame(width: 38, height: 38)
                    .background(
                        (challenge.isCompleted ? AppTheme.success : AppTheme.tint)
                            .opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.subheadline.weight(.semibold))

                    Text(challenge.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Text("+\(challenge.rewardXP) XP")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(challenge.isCompleted ? AppTheme.success : .secondary)
            }

            ProgressView(value: challenge.progress)
                .tint(challenge.isCompleted ? AppTheme.success : AppTheme.tint)

            HStack {
                Text(challenge.progressLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                if challenge.isCompleted {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.success)
                }
            }
        }
        .padding(16)
        .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
