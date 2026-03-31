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
