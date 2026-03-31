import SwiftUI

struct HomeView: View {
    @Environment(HealthSyncManager.self) private var healthSyncManager
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // When live, session card leads so key metrics are immediately visible
                if bluetoothManager.metrics.connected {
                    HomeCurrentSessionCard()
                }

                HomeProgressSummaryCard()
                HomeChallengesCard()

                // When offline, session card acts as the connect CTA in context
                if !bluetoothManager.metrics.connected {
                    HomeCurrentSessionCard()
                }

                HomeWorkoutPlansCard()
                HomeQuickActionsCard()
                HomeRecentWorkoutsCard()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .contentMargins(.bottom, 120, for: .scrollContent)
        .ignoresSafeArea(edges: .bottom)
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if healthSyncManager.authorizationState == .authorized,
               healthSyncManager.trainingOverview == nil,
               !healthSyncManager.isLoadingRecentWorkouts {
                healthSyncManager.refreshTrainingInsights()
            }
        }
    }
}
