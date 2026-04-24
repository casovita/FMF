import Foundation

enum PRValue: Hashable, Codable, Sendable {
    case duration(seconds: Int)
    case reps(count: Int)

    var score: Int {
        switch self {
        case .duration(let s): return s
        case .reps(let c): return c
        }
    }

    var displayString: String {
        switch self {
        case .duration(let s):
            if s >= 60 {
                let m = s / 60
                let rem = s % 60
                return rem == 0 ? "\(m)m" : "\(m)m \(rem)s"
            }
            return "\(s)s"
        case .reps(let c):
            return "\(c) reps"
        }
    }

    static func > (lhs: PRValue, rhs: PRValue) -> Bool {
        switch (lhs, rhs) {
        case (.duration(let a), .duration(let b)): return a > b
        case (.reps(let a), .reps(let b)): return a > b
        default: return false
        }
    }
}
