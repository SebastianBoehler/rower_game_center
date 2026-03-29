import SwiftUI

struct HealthSyncStatusCard: View {
    @Environment(HealthSyncManager.self) private var healthSyncManager

    var body: some View {
        PanelCard(
            title: "Apple Health",
            subtitle: "Write indoor rowing workouts, burned calories, distance, and heart rate into Apple Health."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Status", value: healthSyncManager.statusTitle)
                Text(healthSyncManager.statusDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let lastSavedWorkout = healthSyncManager.lastSavedWorkout {
                    LabeledContent("Last saved", value: AppFormatters.relativeTimestamp(lastSavedWorkout.endDate))
                    LabeledContent("Saved calories", value: AppFormatters.calories(lastSavedWorkout.energyKilocalories.map(Int.init)))
                    LabeledContent("Saved distance", value: AppFormatters.distance(lastSavedWorkout.distanceMeters))
                }

                if let errorMessage = healthSyncManager.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.warning)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if healthSyncManager.authorizationState != .authorized,
                   healthSyncManager.canRequestAuthorization {
                    Button(buttonTitle) {
                        healthSyncManager.requestAuthorization()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }

    private var buttonTitle: String {
        switch healthSyncManager.authorizationState {
        case .notDetermined:
            "Enable Apple Health"
        case .denied:
            "Review Health Access"
        case .unavailable, .authorized:
            ""
        }
    }
}
