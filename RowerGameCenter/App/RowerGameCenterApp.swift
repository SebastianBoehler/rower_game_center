import SwiftUI

@main
struct RowerGameCenterApp: App {
    @State private var bluetoothManager = PM5BluetoothManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(bluetoothManager)
        }
    }
}
