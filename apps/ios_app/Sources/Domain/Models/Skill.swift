import Foundation

enum SkillCategory: String, Codable, CaseIterable {
    case balance
    case strength
    case bodyweight
}

struct Skill: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let category: SkillCategory
}
