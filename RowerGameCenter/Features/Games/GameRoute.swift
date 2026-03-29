import SwiftUI

enum GameRoute: String, CaseIterable, Hashable, Identifiable {
    case templeErg
    case ghostRace
    case laneSprint
    case cadenceLock
    case strokeShape

    var id: String { rawValue }

    var title: String {
        switch self {
        case .templeErg: "Temple Erg"
        case .ghostRace: "Ghost Race"
        case .laneSprint: "Lane Sprint"
        case .cadenceLock: "Cadence Lock"
        case .strokeShape: "Stroke Shape"
        }
    }

    var subtitle: String {
        switch self {
        case .templeErg:
            "Fast obstacle rush where bursts jump, recoveries duck, and heavy hits smash."
        case .ghostRace:
            "Race your best synced benchmark over 500 m, 1 k, or 2 k."
        case .laneSprint:
            "Race a clean 500 m lane driven by live PM5 distance."
        case .cadenceLock:
            "Hold the moving stroke-rate band and build a streak."
        case .strokeShape:
            "Compare your live force curve against a coaching reference."
        }
    }

    var systemImage: String {
        switch self {
        case .templeErg: "bolt.horizontal.circle.fill"
        case .ghostRace: "hare.fill"
        case .laneSprint: "flag.checkered.circle.fill"
        case .cadenceLock: "metronome.fill"
        case .strokeShape: "waveform.path.ecg.rectangle"
        }
    }

    var tint: Color {
        switch self {
        case .templeErg: .orange
        case .ghostRace: AppTheme.tint
        case .laneSprint: AppTheme.success
        case .cadenceLock: AppTheme.tint
        case .strokeShape: .orange
        }
    }

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .templeErg:
            TempleErgView()
        case .ghostRace:
            GhostRaceView()
        case .laneSprint:
            LaneSprintView()
        case .cadenceLock:
            CadenceLockView()
        case .strokeShape:
            StrokeShapeView()
        }
    }
}
