import Foundation

enum WorkoutMode {
    case manual
    case smart
}

enum WorkoutState: Equatable {
    case modeSelection
    case idle
    case active(elapsedSeconds: Int)
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
