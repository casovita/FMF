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
        container["plannedSessionId"] = plannedSessionId
        container["isPersonalRecord"] = isPersonalRecord
        container["sessionScore"] = sessionScore
    }

    var asDomain: PracticeSession {
        PracticeSession(
            id: id,
            skillId: skillId,
            date: date,
            durationMinutes: durationMinutes,
            notes: notes,
            completedAt: completedAt,
            setsCompleted: setsCompleted,
            plannedSessionId: plannedSessionId,
            isPersonalRecord: isPersonalRecord,
            sessionScore: sessionScore
        )
    }
}
