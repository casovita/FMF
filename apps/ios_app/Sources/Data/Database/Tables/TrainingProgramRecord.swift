import Foundation
import GRDB

struct TrainingProgramRecord: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "training_programs"

    var id: String
    var skillId: String
    var level: String
    var weeklyFrequency: Int
    var generatedAt: Double

    init(from program: TrainingProgram) {
        id = program.id
        skillId = program.skillId
        level = program.level.rawValue
        weeklyFrequency = program.weeklyFrequency
        generatedAt = program.generatedAt.timeIntervalSince1970
    }

    init(row: Row) {
        id = row["id"]
        skillId = row["skillId"]
        level = row["level"]
        weeklyFrequency = row["weeklyFrequency"]
        generatedAt = row["generatedAt"]
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["skillId"] = skillId
        container["level"] = level
        container["weeklyFrequency"] = weeklyFrequency
        container["generatedAt"] = generatedAt
    }

    var asDomain: TrainingProgram? {
        guard let skillLevel = SkillLevel(rawValue: level) else { return nil }
        return TrainingProgram(
            id: id,
            skillId: skillId,
            level: skillLevel,
            weeklyFrequency: weeklyFrequency,
            generatedAt: Date(timeIntervalSince1970: generatedAt)
        )
    }
}
