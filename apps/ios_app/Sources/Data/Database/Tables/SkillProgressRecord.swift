import Foundation
import GRDB

struct SkillProgressRecord: FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "skill_progress"

    var id: String
    var skillId: String
    var trackId: String?
    var snapshotDate: Date
    var practiceCount: Int
    var lastPracticeDate: Date?

    init(from snapshot: ProgressSnapshot) {
        id = snapshot.id
        skillId = snapshot.skillId
        trackId = snapshot.trackId
        snapshotDate = snapshot.snapshotDate
        practiceCount = snapshot.practiceCount
        lastPracticeDate = snapshot.lastPracticeDate
    }

    init(row: Row) {
        id = row["id"]
        skillId = row["skillId"]
        trackId = row["trackId"]
        let ts: Double = row["snapshotDate"]
        snapshotDate = Date(timeIntervalSince1970: ts)
        practiceCount = row["practiceCount"]
        if let lts: Double = row["lastPracticeDate"] {
            lastPracticeDate = Date(timeIntervalSince1970: lts)
        }
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["skillId"] = skillId
        container["trackId"] = trackId
        container["snapshotDate"] = snapshotDate.timeIntervalSince1970
        container["practiceCount"] = practiceCount
        container["lastPracticeDate"] = lastPracticeDate?.timeIntervalSince1970
    }

    var asDomain: ProgressSnapshot {
        ProgressSnapshot(
            id: id,
            skillId: skillId,
            trackId: trackId,
            snapshotDate: snapshotDate,
            practiceCount: practiceCount,
            lastPracticeDate: lastPracticeDate
        )
    }
}
