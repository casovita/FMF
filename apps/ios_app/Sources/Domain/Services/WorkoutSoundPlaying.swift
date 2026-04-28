import Foundation

enum WorkoutSoundEffect: String, CaseIterable, Sendable {
    case countdownTick = "countdown_tick"
    case countdownFinalTick = "countdown_final_tick"
    case countdownGo = "countdown_go"
    case workStart = "work_start"
    case restStart = "rest_start"
    case poseAcquired = "pose_acquired"
    case poseLostWarning = "pose_lost_warning"
    case poseResumed = "pose_resumed"
    case repCounted = "rep_counted"
    case sessionComplete = "session_complete"
    case error = "error"
}

@MainActor
protocol WorkoutSoundPlaying: Sendable {
    func play(_ effect: WorkoutSoundEffect)
}

struct NoOpWorkoutSoundPlayer: WorkoutSoundPlaying {
    func play(_ effect: WorkoutSoundEffect) {}
}

struct WorkoutTimingConfiguration: Sendable {
    let gracePeriodSeconds: Int
    let initialGetReadySeconds: Int
    let betweenSetsGetReadySeconds: Int

    static let standard = WorkoutTimingConfiguration(
        gracePeriodSeconds: 3,
        initialGetReadySeconds: 10,
        betweenSetsGetReadySeconds: 5
    )
}
