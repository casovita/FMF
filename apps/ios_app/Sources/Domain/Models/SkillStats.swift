import Foundation

struct SkillStats: Codable, Sendable {
    let skillId: String
    let totalSessions: Int
    let totalMinutes: Int
    let currentStreak: Int
    let longestStreak: Int
    let personalRecord: PRValue?
    let weeklyCompletionRate: Double  // 0–1, rolling last 4 weeks
    let computedAt: Date

    static func empty(skillId: String) -> SkillStats {
        SkillStats(
            skillId: skillId,
            totalSessions: 0,
            totalMinutes: 0,
            currentStreak: 0,
            longestStreak: 0,
            personalRecord: nil,
            weeklyCompletionRate: 0,
            computedAt: Date()
        )
    }
}
