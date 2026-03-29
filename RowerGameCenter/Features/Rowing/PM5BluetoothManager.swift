@preconcurrency import CoreBluetooth
import Foundation
import Observation

@MainActor
@Observable
final class PM5BluetoothManager: NSObject {
    var metrics = RowingMetrics()
    var devices: [PM5DeviceSummary] = []
    var discoveredServices: [PM5DiscoveredServiceSnapshot] = []
    var diagnostics: [PM5DiagnosticEntry] = []
    var connectionPhase: RowingConnectionPhase = .idle
    var bluetoothStateDescription = "Unknown"
    var isScanning = false
    var errorMessage: String?
    var connectedDeviceID: UUID?
    var connectedDeviceName: String?
    var supportsForceCurve = false
    var latestForceCurve: ForceCurveStroke?
    var recentForceCurves: [ForceCurveStroke] = []

    @ObservationIgnored var peripherals: [UUID: CBPeripheral] = [:]
    @ObservationIgnored var connectedPeripheral: CBPeripheral?
    @ObservationIgnored var controlTransmitCharacteristic: CBCharacteristic?
    @ObservationIgnored var controlReceiveCharacteristic: CBCharacteristic?
    @ObservationIgnored var forceCurveCharacteristic: CBCharacteristic?
    @ObservationIgnored var forceCurveAssembler = PM5ForceCurveAssembler()
    @ObservationIgnored var controlFrameDecoder = PM5CSafeFrameDecoder()
    @ObservationIgnored var pendingControlForceCurveSamples: [Double] = []
    @ObservationIgnored var pendingControlForceCurvePeak = 0.0
    @ObservationIgnored var controlForceCurveRequestInFlight = false
    @ObservationIgnored var hasLoggedLiveMetrics = false
    @ObservationIgnored var seenNotificationCharacteristicUUIDs: Set<String> = []
    @ObservationIgnored let healthSyncManager: HealthSyncManager?
    @ObservationIgnored let recapManager: SessionRecapManager?
    @ObservationIgnored let centralManager: CBCentralManager

    init(
        healthSyncManager: HealthSyncManager? = nil,
        recapManager: SessionRecapManager? = nil
    ) {
        self.healthSyncManager = healthSyncManager
        self.recapManager = recapManager
        centralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        centralManager.delegate = self
        logNotice("Bluetooth manager initialized.", category: "lifecycle")
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            if let message = bluetoothStateErrorMessage(for: centralManager.state) {
                setError(message)
            }
            return
        }

        errorMessage = nil
        devices = []
        peripherals = [:]
        isScanning = true
        connectionPhase = .scanning
        logNotice("Started scanning for nearby PM5 monitors.", category: "scan")

        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false,
        ])
    }

    func stopScan() {
        centralManager.stopScan()
        if isScanning {
            logNotice("Stopped scanning for nearby PM5 monitors.", category: "scan")
        }
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
        logNotice("Connecting to \(peripheral.name ?? "PM5") (\(deviceID.uuidString.lowercased())).", category: "connection")
        peripheral.delegate = self
        centralManager.connect(peripheral)
    }

    func disconnect() {
        guard let connectedPeripheral else {
            clearConnectionState()
            return
        }

        connectionPhase = .disconnecting
        logNotice("Disconnect requested for \(connectedDeviceName ?? connectedPeripheral.name ?? "PM5").", category: "connection")
        centralManager.cancelPeripheralConnection(connectedPeripheral)
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
        hasLoggedLiveMetrics = false
        seenNotificationCharacteristicUUIDs = []
        logNotice("Connected to \(connectedDeviceName ?? "PM5"). Discovering services.", category: "connection")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func handleDisconnection(for peripheral: CBPeripheral, error: Error?) {
        let deviceName = connectedDeviceName ?? peripheral.name

        if shouldPresentUnsyncedWorkoutRecap(for: metrics) {
            recapManager?.present(
                SessionRecapBuilder.workout(
                    metrics: metrics,
                    savedToHealth: false
                )
            )
        }
        finishHealthWorkoutIfNeeded()
        clearConnectionState()
        metrics.connected = false
        metrics.deviceName = deviceName
        metrics.lastUpdatedAt = .now

        if let error {
            setError("PM5 disconnected: \(error.localizedDescription)")
        } else {
            logNotice("Disconnected from \(deviceName ?? "PM5").", category: "connection")
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
            let advertisedServices = summary.serviceUUIDs.isEmpty
                ? "none"
                : summary.serviceUUIDs.joined(separator: ", ")
            logInfo(
                "Discovered \(summary.name) at RSSI \(summary.rssi) with advertised services: \(advertisedServices).",
                category: "discovery"
            )
        }
    }

    func handleNotification(from characteristic: CBCharacteristic) {
        guard let value = characteristic.value else {
            return
        }

        logFirstNotificationIfNeeded(from: characteristic, byteCount: value.count)

        if characteristic.uuid.uuidString.uppercased() == PM5UUIDs.receiveFromPM {
            handleControlResponse(value)
            return
        }

        guard let parsedNotification = PM5Parsers.notification(for: characteristic.uuid, data: value) else {
            return
        }

        switch parsedNotification {
        case .metrics(let patch):
            let previousStrokeState = metrics.strokeState
            metrics.apply(patch)
            metrics.deviceName = connectedDeviceName
            if !hasLoggedLiveMetrics {
                hasLoggedLiveMetrics = true
                logNotice("Live rowing metrics are flowing from the PM5.", category: "telemetry")
            }
            requestForceCurveIfNeeded(
                previousStrokeState: previousStrokeState,
                newStrokeState: patch.strokeState ?? metrics.strokeState
            )
            syncHealthMetricsIfNeeded()
        case .forceCurve(let packet):
            guard let stroke = forceCurveAssembler.ingest(packet) else { return }
            applyForceCurveStroke(stroke)
        }
    }

    func replaceDiscoveredServices(from peripheral: CBPeripheral) {
        discoveredServices = (peripheral.services ?? []).map {
            PM5DiscoveredServiceSnapshot(
                uuid: $0.uuid.uuidString.lowercased(),
                characteristics: ($0.characteristics ?? []).map { $0.uuid.uuidString.lowercased() }
            )
        }
        let hasForceCurveCharacteristic = PM5Discovery.hasCharacteristic(
            serviceUUID: PM5UUIDs.rowingService,
            characteristicUUID: PM5UUIDs.forceCurveData,
            in: discoveredServices
        )
        let hasControlTransport = PM5Discovery.hasCharacteristic(
            serviceUUID: PM5UUIDs.controlService,
            characteristicUUID: PM5UUIDs.transmitToPM,
            in: discoveredServices
        ) && PM5Discovery.hasCharacteristic(
            serviceUUID: PM5UUIDs.controlService,
            characteristicUUID: PM5UUIDs.receiveFromPM,
            in: discoveredServices
        )

        supportsForceCurve = hasForceCurveCharacteristic || hasControlTransport
    }

    func validateNotificationCoverage(for peripheral: CBPeripheral) {
        let allCharacteristicsResolved = (peripheral.services ?? []).allSatisfy { $0.characteristics != nil }
        guard allCharacteristicsResolved else { return }

        replaceDiscoveredServices(from: peripheral)
        let matched = PM5Discovery.availableNotificationDefinitions(in: discoveredServices)
        let hasRowingMetricStream = matched.contains { definition in
            definition.serviceUUID == PM5UUIDs.rowingService
        }

        if !hasRowingMetricStream {
            setError("Connected, but none of the expected PM5 metric characteristics were present. Confirm the monitor is advertising the rowing service.")
        } else {
            logInfo(
                "Resolved \(discoveredServices.count) PM5 services. Force curve support: \(supportsForceCurve ? "available" : "not exposed").",
                category: "discovery"
            )
        }
    }

    func setError(_ message: String) {
        if errorMessage != message {
            logError(message, category: "error")
        }
        errorMessage = message

        if connectedPeripheral == nil {
            connectionPhase = .error
        }
    }

    private func shouldPresentUnsyncedWorkoutRecap(for metrics: RowingMetrics) -> Bool {
        guard healthSyncManager?.authorizationState != .authorized else { return false }
        guard let distance = metrics.distance, distance >= 250 else { return false }
        return metrics.elapsedTime != nil
    }

    func clearConnectionState() {
        connectedPeripheral = nil
        connectedDeviceID = nil
        connectedDeviceName = nil
        discoveredServices = []
        isScanning = false
        hasLoggedLiveMetrics = false
        seenNotificationCharacteristicUUIDs = []
        resetForceCurveState()
        logInfo("Cleared PM5 connection state.", category: "connection")

        if errorMessage == nil {
            connectionPhase = .idle
        }
    }
}
