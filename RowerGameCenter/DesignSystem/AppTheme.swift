import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.91, green: 0.94, blue: 0.97)
    static let panel = Color.white
    static let ink = Color(red: 0.07, green: 0.19, blue: 0.27)
    static let secondaryInk = Color(red: 0.22, green: 0.33, blue: 0.43)
    static let mutedInk = Color(red: 0.36, green: 0.46, blue: 0.54)
    static let action = Color(red: 0.07, green: 0.19, blue: 0.27)
    static let accent = Color(red: 0.56, green: 0.88, blue: 0.72)
    static let accentSoft = Color(red: 0.86, green: 0.92, blue: 0.96)
    static let warning = Color(red: 0.53, green: 0.12, blue: 0.16)
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.19, blue: 0.27),
            Color(red: 0.11, green: 0.28, blue: 0.38),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
