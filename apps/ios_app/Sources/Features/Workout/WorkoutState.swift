import Foundation

enum WorkoutMode {
    case timer
    case smart
    case sound

    var summaryLabel: String {
        switch self {
        case .timer:
            return "Timer"
        case .smart:
            return "Smart"
        case .sound:
            return "Sound"
        }
    }
}

enum WorkoutTimerPhase: Equatable {
    case initialCountdown
    case setCountdown(setNumber: Int)
    case work(setNumber: Int)
    case rest(nextSetNumber: Int)
}

enum WorkoutState: Equatable {
    case modeSelection
    case idle
    case countdown(secondsRemaining: Int, phase: WorkoutTimerPhase)
    case active(elapsedSeconds: Int)
    case resting(secondsRemaining: Int, nextSetNumber: Int)
    case paused(elapsedSeconds: Int)
    case complete(totalSeconds: Int)
    case error(message: String)

    var elapsedSeconds: Int {
        switch self {
        case .active(let s), .paused(let s), .complete(let s): return s
        default: return 0
        }
    }
}
