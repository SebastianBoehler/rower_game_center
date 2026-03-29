import SwiftUI

struct HomeView: View {
    @Environment(HealthSyncManager.self) private var healthSyncManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HomeProgressSummaryCard()
                HomeChallengesCard()
                HomeCurrentSessionCard()
                HomeWorkoutPlansCard()
                HomeQuickActionsCard()
                HomeRecentWorkoutsCard()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(AppTheme.groupedBackground, for: .navigationBar)
        .onAppear {
            if healthSyncManager.authorizationState == .authorized,
               healthSyncManager.trainingOverview == nil,
               !healthSyncManager.isLoadingRecentWorkouts {
                healthSyncManager.refreshTrainingInsights()
            }
        }
    }
}
