import SwiftUI

extension WorkoutFocus {
    var tint: Color {
        switch self {
        case .race:
            AppTheme.success
        case .threshold:
            AppTheme.tint
        case .base:
            .orange
        case .technique:
            .pink
        }
    }
}
