import SwiftUI

struct RootView: View {
    @Environment(SessionRecapManager.self) private var sessionRecapManager
    @SceneStorage("selectedTab") private var selectedTabRawValue = AppTab.home.rawValue
    @State private var navigationModel = AppNavigationModel()

    var body: some View {
        @Bindable var navigation = navigationModel

        TabView(selection: $navigation.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
            }
            .tag(AppTab.home)

            NavigationStack(path: $navigation.gamesPath) {
                GamesView()
                    .navigationDestination(for: GameRoute.self) { route in
                        route.destinationView
                    }
            }
            .tabItem {
                Label(AppTab.games.title, systemImage: AppTab.games.systemImage)
            }
            .tag(AppTab.games)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
            }
            .tag(AppTab.settings)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .environment(self.navigationModel)
        .tint(AppTheme.tint)
        .onAppear {
            self.navigationModel.selectedTab = AppTab(rawValue: selectedTabRawValue) ?? .home
        }
        .onChange(of: self.navigationModel.selectedTab) { _, newValue in
            selectedTabRawValue = newValue.rawValue
        }
        .sheet(item: recapBinding) { recap in
            NavigationStack {
                SessionRecapView(recap: recap)
            }
            .presentationDragIndicator(.visible)
        }
    }

    private var recapBinding: Binding<SessionRecap?> {
        Binding(
            get: { sessionRecapManager.activeRecap },
            set: { newValue in
                if newValue == nil {
                    sessionRecapManager.dismissActiveRecap()
                }
            }
        )
    }
}
