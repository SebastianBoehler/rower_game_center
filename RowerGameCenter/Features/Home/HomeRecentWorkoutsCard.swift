import SwiftUI

struct HomeRecentWorkoutsCard: View {
    @Environment(HealthSyncManager.self) private var healthSyncManager

    var body: some View {
        PanelCard(title: "Recent Workouts", subtitle: "Latest indoor rowing sessions from Apple Health.") {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch healthSyncManager.authorizationState {
        case .unavailable:
            unavailableMessage
        case .notDetermined, .denied:
            permissionPrompt
        case .authorized:
            authorizedContent
        }
    }

    private var unavailableMessage: some View {
        Text("Apple Health is unavailable on this device.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var permissionPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enable Apple Health to load recent rowing workouts.")
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
        if healthSyncManager.isLoadingRecentWorkouts {
            ProgressView("Loading recent workouts…")
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let historyErrorMessage = healthSyncManager.historyErrorMessage {
            VStack(alignment: .leading, spacing: 12) {
                Label(historyErrorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.warning)

                Button("Retry") {
                    healthSyncManager.refreshRecentWorkouts()
                }
                .buttonStyle(.bordered)
            }
        } else if healthSyncManager.recentWorkouts.isEmpty {
            Text("No synced rowing sessions yet — finish a workout to see it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            ForEach(Array(healthSyncManager.recentWorkouts.enumerated()), id: \.element.id) { index, workout in
                workoutRow(for: workout)

                if index < healthSyncManager.recentWorkouts.count - 1 {
                    Divider()
                }
            }
        }
    }

    private func workoutRow(for workout: HealthWorkoutSummary) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppFormatters.workoutDay(workout.endDate))
                    .font(.headline)

                Text("\(AppFormatters.workoutTime(workout.startDate)) - \(AppFormatters.workoutTime(workout.endDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(AppFormatters.duration(workout.duration))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(AppFormatters.distance(workout.distanceMeters))
                    .font(.headline.weight(.semibold))
                    .monospacedDigit()

                Text(AppFormatters.calories(workout.energyKilocalories))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
