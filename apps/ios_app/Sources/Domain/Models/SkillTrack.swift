import Foundation

struct SkillTrack: Identifiable, Hashable, Codable {
    let id: String
    let skillId: String
    let name: String
    let order: Int
    let description: String
    let requiredPracticeCount: Int
}
