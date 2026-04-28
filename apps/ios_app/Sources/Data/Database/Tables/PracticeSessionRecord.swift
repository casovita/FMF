import Foundation
import GRDB

struct PracticeSessionRecord: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "practice_sessions"

    var id: String
    var skillId: String
    var date: Date
    var durationMinutes: Int
    var notes: String?
    var completedAt: Date?
    var setsCompleted: Int
    var targetValuePerSet: Int
    var restSeconds: Int
    var durationSetValuesData: Data?
    var plannedSessionId: String?
    var isPersonalRecord: Bool
    var sessionScore: Int

    init(from session: PracticeSession) {
        id = session.id
        skillId = session.skillId
        date = session.date
        durationMinutes = session.durationMinutes
        notes = session.notes
        completedAt = session.completedAt
        setsCompleted = session.setsCompleted
        targetValuePerSet = session.targetValuePerSet
        restSeconds = session.restSeconds
        durationSetValuesData = try? JSONEncoder().encode(session.durationSetValues)
        plannedSessionId = session.plannedSessionId
        isPersonalRecord = session.isPersonalRecord
        sessionScore = session.sessionScore
    }

    init(row: Row) {
        id = row["id"]
        skillId = row["skillId"]
        let dateTimestamp: Double = row["date"]
        date = Date(timeIntervalSince1970: dateTimestamp)
        durationMinutes = row["durationMinutes"]
        notes = row["notes"]
        if let completedAtTimestamp: Double = row["completedAt"] {
            completedAt = Date(timeIntervalSince1970: completedAtTimestamp)
        }
        setsCompleted = row["setsCompleted"] ?? 0
        targetValuePerSet = row["targetValuePerSet"] ?? 0
        restSeconds = row["restSeconds"] ?? 0
        durationSetValuesData = row["durationSetValuesData"]
        plannedSessionId = row["plannedSessionId"]
        isPersonalRecord = row["isPersonalRecord"] ?? false
        sessionScore = row["sessionScore"] ?? 0
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["skillId"] = skillId
        container["date"] = date.timeIntervalSince1970
        container["durationMinutes"] = durationMinutes
        container["notes"] = notes
        container["completedAt"] = completedAt?.timeIntervalSince1970
        container["setsCompleted"] = setsCompleted
        container["targetValuePerSet"] = targetValuePerSet
        container["restSeconds"] = restSeconds
        container["durationSetValuesData"] = durationSetValuesData
        container["plannedSessionId"] = plannedSessionId
        container["isPersonalRecord"] = isPersonalRecord
        container["sessionScore"] = sessionScore
    }

    var asDomain: PracticeSession {
        let durationSetValues = (try? durationSetValuesData.flatMap { try JSONDecoder().decode([Int].self, from: $0) }) ?? []
        return PracticeSession(
            id: id,
            skillId: skillId,
            date: date,
            durationMinutes: durationMinutes,
            notes: notes,
            completedAt: completedAt,
            setsCompleted: setsCompleted,
            targetValuePerSet: targetValuePerSet,
            restSeconds: restSeconds,
            durationSetValues: durationSetValues,
            plannedSessionId: plannedSessionId,
            isPersonalRecord: isPersonalRecord,
            sessionScore: sessionScore
        )
    }
}
