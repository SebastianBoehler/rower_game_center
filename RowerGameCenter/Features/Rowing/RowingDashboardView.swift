import SwiftUI

struct RowingDashboardView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroSection
                connectionSection
                PowerBar(watts: bluetoothManager.metrics.powerWatts)
                metricsSection
                gamesSection
                devicesSection
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Rower Game Center")
        .navigationBarTitleDisplayMode(.inline)
        .fontDesign(.rounded)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Native CoreBluetooth")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .textCase(.uppercase)

            Text("Concept2 gameplay driven by live PM5 data.")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(.white)

            Text("This app scans, connects, subscribes, and updates games from real BLE notifications only.")
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.82))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var connectionSection: some View {
        PanelCard(title: "Connection") {
            VStack(alignment: .leading, spacing: 12) {
                Text(bluetoothManager.connectionSummary)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)

                Text("Bluetooth: \(bluetoothManager.bluetoothStateDescription) • Mode: \(bluetoothManager.connectionPhase.rawValue)")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)

                if let errorMessage = bluetoothManager.errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.warning)
                }

                HStack(spacing: 12) {
                    Button(bluetoothManager.isScanning ? "Stop Scan" : "Start Scan") {
                        if bluetoothManager.isScanning {
                            bluetoothManager.stopScan()
                        } else {
                            bluetoothManager.startScan()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(variant: .primary))

                    Button("Disconnect") {
                        bluetoothManager.disconnect()
                    }
                    .buttonStyle(PrimaryButtonStyle(variant: .secondary))
                    .disabled(!bluetoothManager.metrics.connected)
                }
            }
        }
    }

    private var metricsSection: some View {
        LazyVGrid(columns: metricColumns, spacing: 12) {
            MetricTile(title: "Elapsed", value: AppFormatters.duration(bluetoothManager.metrics.elapsedTime))
            MetricTile(title: "Distance", value: AppFormatters.distance(bluetoothManager.metrics.distance))
            MetricTile(title: "Stroke Rate", value: AppFormatters.strokeRate(bluetoothManager.metrics.strokeRate))
            MetricTile(title: "Pace", value: AppFormatters.pace(bluetoothManager.metrics.pace))
            MetricTile(title: "Watts", value: AppFormatters.watts(bluetoothManager.metrics.powerWatts))
            MetricTile(title: "Heart Rate", value: AppFormatters.heartRate(bluetoothManager.metrics.heartRate))
            MetricTile(title: "Calories", value: AppFormatters.calories(bluetoothManager.metrics.calories))
            MetricTile(title: "Feed", value: bluetoothManager.metrics.lastUpdatedAt == nil ? "Waiting" : "Live")
        }
    }

    private var gamesSection: some View {
        PanelCard(title: "Games") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Lane Sprint turns live PM5 distance into a 500 m race line with low-chrome HUD.")
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryInk)

                NavigationLink {
                    LaneSprintView()
                } label: {
                    Text("Open Lane Sprint")
                }
                .buttonStyle(PrimaryButtonStyle(variant: .primary))
                .disabled(!bluetoothManager.metrics.connected)
            }
        }
    }

    private var devicesSection: some View {
        PanelCard(title: "Nearby PM5 devices") {
            VStack(alignment: .leading, spacing: 12) {
                if bluetoothManager.devices.isEmpty {
                    Text("Wake the PM5 and scan. Devices only appear when the advertisement matches the current PM5 heuristics.")
                        .font(.body)
                        .foregroundStyle(AppTheme.secondaryInk)
                } else {
                    ForEach(bluetoothManager.devices) { device in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(device.name)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.ink)

                            Text("\(device.localName ?? "No local name") • RSSI \(device.rssi)")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.mutedInk)

                            Button("Connect") {
                                bluetoothManager.connect(to: device.id)
                            }
                            .buttonStyle(PrimaryButtonStyle(variant: .secondary))
                            .disabled(bluetoothManager.connectionPhase == .connecting)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
        }
    }
}
