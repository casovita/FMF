import Foundation

enum SkillCategory: String, Codable, CaseIterable {
    case balance
    case strength
    case bodyweight
}

struct Skill: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let category: SkillCategory
    var prescriptionType: PrescriptionType = .duration
}
