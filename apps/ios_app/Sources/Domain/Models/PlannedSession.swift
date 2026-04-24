import Foundation

struct PlannedSession: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let programId: String
    let scheduledDate: Date
    var prescription: SessionPrescription
    var completedSessionId: String?
    var isSkipped: Bool

    var isCompleted: Bool { completedSessionId != nil }
}

struct SessionPrescription: Hashable, Codable, Sendable {
    let sets: Int
    let target: PrescriptionTarget
    let notes: String

    var displayString: String {
        switch target {
        case .duration(let seconds): return "\(sets)×\(seconds)s"
        case .reps(let count): return "\(sets)×\(count) reps"
        }
    }
}

enum PrescriptionTarget: Hashable, Codable, Sendable {
    case duration(seconds: Int)
    case reps(count: Int)

    var value: Int {
        switch self {
        case .duration(let s): return s
        case .reps(let c): return c
        }
    }

    func scaled(by factor: Double) -> PrescriptionTarget {
        switch self {
        case .duration(let s):
            return .duration(seconds: max(5, Int((Double(s) * factor).rounded())))
        case .reps(let c):
            return .reps(count: max(1, Int((Double(c) * factor).rounded())))
        }
    }
}
