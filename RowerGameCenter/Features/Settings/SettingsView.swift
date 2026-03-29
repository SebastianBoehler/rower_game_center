import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PM5ConnectionSettingsCard()
                PM5DevicesCard()
                HealthSyncStatusCard()
                DiagnosticsSettingsCard()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(AppTheme.groupedBackground, for: .navigationBar)
    }
}
