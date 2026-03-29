import HealthKit

enum HealthKitTypes {
    static let workout = HKWorkoutType.workoutType()
    static let activeEnergy = HKQuantityType(.activeEnergyBurned)
    static let distanceRowing = HKQuantityType(.distanceRowing)
    static let heartRate = HKQuantityType(.heartRate)

    static let shareTypes: Set<HKSampleType> = [
        workout,
        activeEnergy,
        distanceRowing,
        heartRate,
    ]

    static let readTypes: Set<HKObjectType> = [
        workout,
        activeEnergy,
        distanceRowing,
        heartRate,
    ]

    static let authorizationTypes: [HKObjectType] = [
        workout,
        activeEnergy,
        distanceRowing,
        heartRate,
    ]

    static let energyUnit = HKUnit.kilocalorie()
    static let distanceUnit = HKUnit.meter()
    static let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
}
