import SwiftUI

struct GamesView: View {
    @Environment(HealthSyncManager.self) private var healthSyncManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GamesConnectionStatusCard()
                GamesGhostBenchmarksCard()
                GamesCatalogCard()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Games")
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
