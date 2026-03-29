import SwiftUI

enum AppTab: String, Hashable {
    case home
    case games
    case settings

    var title: String {
        switch self {
        case .home: "Home"
        case .games: "Games"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .games: "gamecontroller.fill"
        case .settings: "slider.horizontal.3"
        }
    }
}
