import Foundation
import GRDB

struct UserSkillRecord: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "user_skills"

    var id: String
    var skillId: String
    var level: String
    var weeklyFrequency: Int
    var isActive: Bool
    var addedAt: Double

    init(from userSkill: UserSkill) {
        id = userSkill.id
        skillId = userSkill.skillId
        level = userSkill.level.rawValue
        weeklyFrequency = userSkill.weeklyFrequency
        isActive = userSkill.isActive
        addedAt = userSkill.addedAt.timeIntervalSince1970
    }

    init(row: Row) {
        id = row["id"]
        skillId = row["skillId"]
        level = row["level"]
        weeklyFrequency = row["weeklyFrequency"]
        isActive = row["isActive"]
        addedAt = row["addedAt"]
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["skillId"] = skillId
        container["level"] = level
        container["weeklyFrequency"] = weeklyFrequency
        container["isActive"] = isActive
        container["addedAt"] = addedAt
    }

    var asDomain: UserSkill? {
        guard let skillLevel = SkillLevel(rawValue: level) else { return nil }
        var skill = UserSkill(skillId: skillId, level: skillLevel, weeklyFrequency: weeklyFrequency)
        skill.isActive = isActive
        skill.addedAt = Date(timeIntervalSince1970: addedAt)
        return skill
    }
}
