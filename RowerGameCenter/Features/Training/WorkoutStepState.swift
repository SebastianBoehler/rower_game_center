import Foundation

struct WorkoutStepState {
    let currentIndex: Int
    let currentStep: StructuredWorkoutStep?
    let nextStep: StructuredWorkoutStep?
    let stepProgress: Double
    let remainingLabel: String

    var currentStepNumber: Int {
        min(currentIndex + 1, max(1, (currentStep != nil ? currentIndex + 1 : 1)))
    }

    init(template: StructuredWorkoutTemplate, elapsedTime: TimeInterval) {
        let steps = template.steps
        var runningTime: TimeInterval = 0
        var resolvedIndex = steps.indices.last ?? 0
        var resolvedStep: StructuredWorkoutStep?
        var resolvedNext: StructuredWorkoutStep?
        var resolvedProgress = 0.0
        var resolvedRemaining = AppFormatters.totalDuration(steps.first?.duration)

        for (index, step) in steps.enumerated() {
            let stepEnd = runningTime + step.duration
            if elapsedTime <= stepEnd || index == steps.count - 1 {
                let elapsedInStep = min(max(elapsedTime - runningTime, 0), step.duration)
                resolvedIndex = index
                resolvedStep = step
                resolvedNext = index + 1 < steps.count ? steps[index + 1] : nil
                resolvedProgress = step.duration > 0 ? elapsedInStep / step.duration : 0
                resolvedRemaining = AppFormatters.totalDuration(max(step.duration - elapsedInStep, 0))
                break
            }

            runningTime = stepEnd
        }

        currentIndex = resolvedIndex
        currentStep = resolvedStep
        nextStep = resolvedNext
        stepProgress = resolvedProgress
        remainingLabel = resolvedRemaining
    }
}
