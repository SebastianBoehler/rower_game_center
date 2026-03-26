import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            RowingDashboardView()
        }
        .tint(AppTheme.action)
    }
}
