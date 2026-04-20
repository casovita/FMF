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

    init(from session: PracticeSession) {
        id = session.id
        skillId = session.skillId
        date = session.date
        durationMinutes = session.durationMinutes
        notes = session.notes
        completedAt = session.completedAt
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
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["skillId"] = skillId
        container["date"] = date.timeIntervalSince1970
        container["durationMinutes"] = durationMinutes
        container["notes"] = notes
        container["completedAt"] = completedAt?.timeIntervalSince1970
    }

    var asDomain: PracticeSession {
        PracticeSession(
            id: id,
            skillId: skillId,
            date: date,
            durationMinutes: durationMinutes,
            notes: notes,
            completedAt: completedAt
        )
    }
}
