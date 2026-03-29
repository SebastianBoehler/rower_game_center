extension PM5BluetoothManager {
    func syncHealthMetricsIfNeeded() {
        healthSyncManager?.enqueueMetrics(metrics, connectedDeviceName: connectedDeviceName)
    }

    func finishHealthWorkoutIfNeeded() {
        healthSyncManager?.finishWorkout(with: metrics)
    }
}
