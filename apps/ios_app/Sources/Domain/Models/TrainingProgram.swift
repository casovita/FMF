import Foundation

struct TrainingProgram: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let skillId: String
    let level: SkillLevel
    var weeklyFrequency: Int
    var generatedAt: Date
}
