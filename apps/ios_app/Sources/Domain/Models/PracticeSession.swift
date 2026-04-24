import Foundation

struct PracticeSession: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let skillId: String
    let date: Date
    let durationMinutes: Int
    let notes: String?
    let completedAt: Date?
    var setsCompleted: Int = 0
    var plannedSessionId: String? = nil
    var isPersonalRecord: Bool = false
    // Raw performance score: seconds for duration skills, total reps for rep skills
    var sessionScore: Int = 0
}
