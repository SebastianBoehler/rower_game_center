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
        }
        .contentMargins(.bottom, 120, for: .scrollContent)
        .ignoresSafeArea(edges: .bottom)
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}
