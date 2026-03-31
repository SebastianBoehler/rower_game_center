import SwiftUI

@main
struct RowerGameCenterApp: App {
    @State private var sessionRecapManager: SessionRecapManager
    @State private var healthSyncManager: HealthSyncManager
    @State private var bluetoothManager: PM5BluetoothManager

    init() {
        let recap = SessionRecapManager()
        _sessionRecapManager = State(initialValue: recap)

        let health = HealthSyncManager(recapManager: recap)
        _healthSyncManager = State(initialValue: health)

        _bluetoothManager = State(
            initialValue: PM5BluetoothManager(
                healthSyncManager: health,
                recapManager: recap
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(bluetoothManager)
                .environment(healthSyncManager)
                .environment(sessionRecapManager)
        }
    }
}
