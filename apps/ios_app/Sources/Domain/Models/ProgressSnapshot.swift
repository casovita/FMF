import Foundation

struct ProgressSnapshot: Identifiable, Hashable, Codable {
    let id: String
    let skillId: String
    let trackId: String?
    let snapshotDate: Date
    let practiceCount: Int
    let lastPracticeDate: Date?
}
