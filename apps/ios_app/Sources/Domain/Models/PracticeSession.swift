import Foundation

struct PracticeSession: Identifiable, Hashable, Codable {
    let id: String
    let skillId: String
    let date: Date
    let durationMinutes: Int
    let notes: String?
    let completedAt: Date?
}
