import Foundation
import GRDB

final class LocalPracticeSessionRepository: PracticeSessionRepository {
    private let db: AppDatabase

    init(db: AppDatabase) {
        self.db = db
    }

    func logSession(_ session: PracticeSession) async throws {
        let record = PracticeSessionRecord(from: session)
        try await db.dbWriter.write { db in
            try record.save(db)
        }
    }

    func getSessionsForSkill(_ skillId: String) async throws -> [PracticeSession] {
        try await db.dbWriter.read { db in
            let records = try PracticeSessionRecord
                .filter(Column("skillId") == skillId)
                .order(Column("date").desc)
                .fetchAll(db)
            return records.map { $0.asDomain }
        }
    }

    func getRecentSessions(limit: Int = 10) async throws -> [PracticeSession] {
        try await db.dbWriter.read { db in
            let records = try PracticeSessionRecord
                .order(Column("date").desc)
                .limit(limit)
                .fetchAll(db)
            return records.map { $0.asDomain }
        }
    }
}
