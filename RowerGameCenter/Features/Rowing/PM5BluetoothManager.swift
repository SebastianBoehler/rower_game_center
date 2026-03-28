@preconcurrency import CoreBluetooth
import Foundation
import Observation

@MainActor
@Observable
final class PM5BluetoothManager: NSObject {
    var metrics = RowingMetrics()
    var devices: [PM5DeviceSummary] = []
    var discoveredServices: [PM5DiscoveredServiceSnapshot] = []
    var connectionPhase: RowingConnectionPhase = .idle
    var bluetoothStateDescription = "Unknown"
    var isScanning = false
    var errorMessage: String?
    var connectedDeviceID: UUID?
    var connectedDeviceName: String?
    var supportsForceCurve = false
    var latestForceCurve: ForceCurveStroke?
    var recentForceCurves: [ForceCurveStroke] = []

    @ObservationIgnored private var peripherals: [UUID: CBPeripheral] = [:]
    @ObservationIgnored private var connectedPeripheral: CBPeripheral?
    @ObservationIgnored private var forceCurveCharacteristic: CBCharacteristic?
    @ObservationIgnored private var forceCurveAssembler = PM5ForceCurveAssembler()
    @ObservationIgnored private let centralManager: CBCentralManager

    override init() {
        centralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        centralManager.delegate = self
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            setError("Bluetooth must be powered on before scanning for a PM5.")
            return
        }

        errorMessage = nil
        devices = []
        peripherals = [:]
        isScanning = true
        connectionPhase = .scanning

        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false,
        ])
    }

    func stopScan() {
        centralManager.stopScan()
        isScanning = false

        if connectedPeripheral == nil {
            connectionPhase = .idle
        }
    }

    func connect(to deviceID: UUID) {
        guard let peripheral = peripherals[deviceID] else {
            setError("The selected PM5 is no longer available. Scan again.")
            return
        }

        guard connectedPeripheral == nil || connectedPeripheral?.identifier == deviceID else {
            setError("Disconnect the current PM5 before connecting to another monitor.")
            return
        }

        stopScan()
        errorMessage = nil
        connectionPhase = .connecting
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral)
    }

    func disconnect() {
        guard let connectedPeripheral else {
            clearConnectionState()
            return
        }

        connectionPhase = .disconnecting
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }

    func clearError() {
        errorMessage = nil
    }

    var connectionSummary: String {
        if metrics.connected {
            return "Connected to \(metrics.deviceName ?? "PM5")"
        }

        if isScanning {
            return "Scanning for nearby Concept2 PM5 monitors"
        }

        return "No PM5 connected"
    }

    func handleConnectedPeripheral(_ peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedDeviceID = peripheral.identifier
        connectedDeviceName = peripheral.name ?? "PM5"
        metrics.connected = true
        metrics.deviceName = connectedDeviceName
        metrics.lastUpdatedAt = .now
        connectionPhase = .connected
        discoveredServices = []
        resetForceCurveState()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func handleDisconnection(for peripheral: CBPeripheral, error: Error?) {
        let deviceName = connectedDeviceName ?? peripheral.name

        clearConnectionState()
        metrics.connected = false
        metrics.deviceName = deviceName
        metrics.lastUpdatedAt = .now

        if let error {
            setError("PM5 disconnected: \(error.localizedDescription)")
        }
    }

    func register(
        peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi: NSNumber
    ) {
        let summary = PM5Discovery.summary(
            for: peripheral,
            advertisementData: advertisementData,
            rssi: rssi
        )

        peripherals[summary.id] = peripheral

        if let existingIndex = devices.firstIndex(where: { $0.id == summary.id }) {
            devices[existingIndex] = summary
        } else {
            devices.append(summary)
            devices.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    func handleNotification(from characteristic: CBCharacteristic) {
        guard let value = characteristic.value,
              let parsedNotification = PM5Parsers.notification(for: characteristic.uuid, data: value) else {
            return
        }

        switch parsedNotification {
        case .metrics(let patch):
            let previousStrokeState = metrics.strokeState
            metrics.apply(patch)
            metrics.deviceName = connectedDeviceName
            requestForceCurveIfNeeded(
                previousStrokeState: previousStrokeState,
                newStrokeState: patch.strokeState ?? metrics.strokeState
            )
        case .forceCurve(let packet):
            guard let stroke = forceCurveAssembler.ingest(packet) else { return }
            guard stroke.samples != latestForceCurve?.samples else { return }

            latestForceCurve = stroke
            recentForceCurves.append(stroke)
            recentForceCurves = Array(recentForceCurves.suffix(5))
        }
    }

    func replaceDiscoveredServices(from peripheral: CBPeripheral) {
        discoveredServices = (peripheral.services ?? []).map {
            PM5DiscoveredServiceSnapshot(
                uuid: $0.uuid.uuidString.lowercased(),
                characteristics: ($0.characteristics ?? []).map { $0.uuid.uuidString.lowercased() }
            )
        }
        supportsForceCurve = PM5Discovery.hasCharacteristic(
            serviceUUID: PM5UUIDs.rowingService,
            characteristicUUID: PM5UUIDs.forceCurveData,
            in: discoveredServices
        )
    }

    func validateNotificationCoverage(for peripheral: CBPeripheral) {
        let allCharacteristicsResolved = (peripheral.services ?? []).allSatisfy { $0.characteristics != nil }
        guard allCharacteristicsResolved else { return }

        replaceDiscoveredServices(from: peripheral)
        let matched = PM5Discovery.availableNotificationDefinitions(in: discoveredServices)

        if matched.isEmpty {
            setError("Connected, but none of the expected PM5 metric characteristics were present. Confirm the monitor is advertising the rowing service.")
        }
    }

    func setError(_ message: String) {
        errorMessage = message

        if connectedPeripheral == nil {
            connectionPhase = .error
        }
    }

    func clearConnectionState() {
        connectedPeripheral = nil
        connectedDeviceID = nil
        connectedDeviceName = nil
        discoveredServices = []
        isScanning = false
        resetForceCurveState()

        if errorMessage == nil {
            connectionPhase = .idle
        }
    }

    func registerDiscoveredCharacteristic(_ characteristic: CBCharacteristic) {
        if characteristic.uuid.uuidString.uppercased() == PM5UUIDs.forceCurveData {
            forceCurveCharacteristic = characteristic
        }
    }

    private func resetForceCurveState() {
        supportsForceCurve = false
        latestForceCurve = nil
        recentForceCurves = []
        forceCurveCharacteristic = nil
        forceCurveAssembler.reset()
    }

    private func requestForceCurveIfNeeded(
        previousStrokeState: Int?,
        newStrokeState: Int?
    ) {
        guard supportsForceCurve else { return }
        guard previousStrokeState != PM5StrokeState.recovery,
              newStrokeState == PM5StrokeState.recovery else {
            return
        }

        guard let forceCurveCharacteristic,
              forceCurveCharacteristic.properties.contains(.read) else {
            return
        }

        connectedPeripheral?.readValue(for: forceCurveCharacteristic)
    }
}

private enum PM5StrokeState {
    static let recovery = 4
}
