@preconcurrency import CoreBluetooth
import Foundation

extension PM5BluetoothManager {
    func registerDiscoveredCharacteristic(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid.uuidString.uppercased() {
        case PM5UUIDs.transmitToPM:
            controlTransmitCharacteristic = characteristic
        case PM5UUIDs.receiveFromPM:
            controlReceiveCharacteristic = characteristic
        case PM5UUIDs.forceCurveData:
            forceCurveCharacteristic = characteristic
        default:
            break
        }
    }

    func resetForceCurveState() {
        supportsForceCurve = false
        latestForceCurve = nil
        recentForceCurves = []
        controlTransmitCharacteristic = nil
        controlReceiveCharacteristic = nil
        forceCurveCharacteristic = nil
        forceCurveAssembler.reset()
        controlFrameDecoder.reset()
        pendingControlForceCurveSamples = []
        pendingControlForceCurvePeak = 0
        controlForceCurveRequestInFlight = false
    }

    func requestForceCurveIfNeeded(
        previousStrokeState: Int?,
        newStrokeState: Int?
    ) {
        guard supportsForceCurve else { return }
        guard previousStrokeState != PM5StrokeState.recovery,
              newStrokeState == PM5StrokeState.recovery else {
            return
        }

        if controlTransmitCharacteristic != nil, controlReceiveCharacteristic != nil {
            requestControlForceCurveChunk()
            return
        }

        if let forceCurveCharacteristic,
           forceCurveCharacteristic.properties.contains(.read) {
            connectedPeripheral?.readValue(for: forceCurveCharacteristic)
        }
    }

    func applyForceCurveStroke(_ stroke: ForceCurveStroke) {
        guard stroke.samples != latestForceCurve?.samples else { return }

        latestForceCurve = stroke
        recentForceCurves.append(stroke)
        recentForceCurves = Array(recentForceCurves.suffix(5))
    }

    private func requestControlForceCurveChunk() {
        guard !controlForceCurveRequestInFlight,
              let connectedPeripheral,
              let controlTransmitCharacteristic else {
            return
        }

        let writeType: CBCharacteristicWriteType =
            controlTransmitCharacteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse

        controlForceCurveRequestInFlight = true
        connectedPeripheral.writeValue(
            PM5CSafeProtocol.forceCurveRequest(),
            for: controlTransmitCharacteristic,
            type: writeType
        )
    }

    func handleControlResponse(_ data: Data) {
        let frames = controlFrameDecoder.append(data)
        guard !frames.isEmpty else { return }

        controlForceCurveRequestInFlight = false

        for frame in frames {
            guard let chunk = PM5CSafeProtocol.parseForceCurveResponse(from: frame) else {
                continue
            }

            handleControlForceCurveChunk(chunk)
        }
    }

    private func handleControlForceCurveChunk(_ chunk: PM5CSafeForceCurveChunk) {
        if chunk.bytesReturned == 0 {
            finalizeControlForceCurveIfNeeded()
            return
        }

        var shouldFinalize = chunk.bytesReturned < 20
        var lastValue = pendingControlForceCurveSamples.last ?? 0

        for sample in chunk.samples {
            if pendingControlForceCurveSamples.count > 20,
               lastValue < (pendingControlForceCurvePeak / 4),
               sample > lastValue {
                finalizeControlForceCurveIfNeeded()
            }

            pendingControlForceCurveSamples.append(sample)
            pendingControlForceCurvePeak = max(pendingControlForceCurvePeak, sample)
            lastValue = sample
        }

        if pendingControlForceCurveSamples.count > 10,
           chunk.samples.last == 0 {
            shouldFinalize = true
        }

        if shouldFinalize {
            finalizeControlForceCurveIfNeeded()
        } else {
            requestControlForceCurveChunk()
        }
    }

    private func finalizeControlForceCurveIfNeeded() {
        defer {
            pendingControlForceCurveSamples = []
            pendingControlForceCurvePeak = 0
        }

        guard pendingControlForceCurveSamples.count > 4 else { return }

        applyForceCurveStroke(
            ForceCurveStroke(
                capturedAt: .now,
                samples: pendingControlForceCurveSamples
            )
        )
    }
}

private enum PM5StrokeState {
    static let recovery = 4
}
