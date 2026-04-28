import Foundation
import GRDB

final class LocalTrainingProgramRepository: TrainingProgramRepository {
    private let db: AppDatabase

    init(db: AppDatabase) {
        self.db = db
    }

    func getProgram(for skillId: String) async throws -> TrainingProgram? {
        try await db.dbWriter.read { db in
            try TrainingProgramRecord
                .filter(Column("skillId") == skillId)
                .order(Column("generatedAt").desc)
                .fetchOne(db)?
                .asDomain
        }
    }

    func saveProgram(_ program: TrainingProgram) async throws {
        let record = TrainingProgramRecord(from: program)
        try await db.dbWriter.write { db in
            try record.save(db)
        }
    }

    func getPlannedSessions(for programId: String) async throws -> [PlannedSession] {
        try await db.dbWriter.read { db in
            try PlannedSessionRecord
                .filter(Column("programId") == programId)
                .order(Column("scheduledDate").asc)
                .fetchAll(db)
                .compactMap { $0.asDomain }
        }
    }

    func getAllPlannedSessions(for skillId: String) async throws -> [PlannedSession] {
        try await db.dbWriter.read { db in
            let programIds = try TrainingProgramRecord
                .filter(Column("skillId") == skillId)
                .fetchAll(db)
                .map { $0.id }
            guard !programIds.isEmpty else { return [] }
            return try PlannedSessionRecord
                .filter(programIds.contains(Column("programId")))
                .order(Column("scheduledDate").asc)
                .fetchAll(db)
                .compactMap { $0.asDomain }
        }
    }

    func savePlannedSession(_ session: PlannedSession) async throws {
        let record = try PlannedSessionRecord(from: session)
        try await db.dbWriter.write { db in
            try record.save(db)
        }
    }

    func savePlannedSessions(_ sessions: [PlannedSession]) async throws {
        let records = try sessions.map { try PlannedSessionRecord(from: $0) }
        try await db.dbWriter.write { db in
            for record in records {
                try record.save(db)
            }
        }
    }

    func markSessionComplete(id: String, completedSessionId: String) async throws {
        try await db.dbWriter.write { db in
            try db.execute(
                sql: "UPDATE planned_sessions SET completedSessionId = ? WHERE id = ?",
                arguments: [completedSessionId, id]
            )
        }
    }

    func clearCompletedSession(id: String) async throws {
        try await db.dbWriter.write { db in
            try db.execute(
                sql: "UPDATE planned_sessions SET completedSessionId = NULL WHERE id = ?",
                arguments: [id]
            )
        }
    }

    func skipSession(id: String) async throws {
        try await db.dbWriter.write { db in
            try db.execute(
                sql: "UPDATE planned_sessions SET isSkipped = 1 WHERE id = ?",
                arguments: [id]
            )
        }
    }
}
