import Foundation

struct UserSkill: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let skillId: String
    var level: SkillLevel
    var weeklyFrequency: Int  // sessions per week, 2–5
    var isActive: Bool
    var addedAt: Date

    init(skillId: String, level: SkillLevel, weeklyFrequency: Int) {
        self.id = skillId
        self.skillId = skillId
        self.level = level
        self.weeklyFrequency = weeklyFrequency
        self.isActive = true
        self.addedAt = Date()
    }
}
