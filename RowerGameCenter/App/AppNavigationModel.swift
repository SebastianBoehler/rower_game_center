import Observation

@MainActor
@Observable
final class AppNavigationModel {
    var selectedTab: AppTab = .home
    var gamesPath: [GameRoute] = []

    func openGame(_ route: GameRoute) {
        selectedTab = .games
        gamesPath = [route]
    }

    func openGamesLibrary() {
        selectedTab = .games
        gamesPath.removeAll()
    }

    func openSettings() {
        selectedTab = .settings
    }
}
