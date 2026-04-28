// Test seams — only used by WorkoutStateMachineTests
extension WorkoutViewModel {
    func testForceState(_ newState: WorkoutState) {
        state = newState
    }

    func testSetElapsed(_ seconds: Int) {
        elapsed = seconds
    }

    func testSetRepCount(_ count: Int) {
        repCount = count
    }

    func testHandlePoseEvent(_ event: PoseEvent) async {
        await handlePoseEvent(event)
    }

    func testCountdownEffect(for remaining: Int) -> WorkoutSoundEffect {
        countdownEffect(for: remaining)
    }
}
