import Foundation

enum SkillLevel: String, Codable, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: String(localized: "skill_level_beginner")
        case .intermediate: String(localized: "skill_level_intermediate")
        case .advanced: String(localized: "skill_level_advanced")
        }
    }
}
