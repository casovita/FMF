import Testing
import Foundation
import GRDB
@testable import FMF

@Suite("PracticeSessionRepository")
struct PracticeSessionRepositoryTests {
    private func makeRepo() throws -> (LocalPracticeSessionRepository, AppDatabase) {
        let db = try AppDatabase.inMemory()
        return (LocalPracticeSessionRepository(db: db), db)
    }

    @Test("insert and fetch round-trip")
    func insertFetch() async throws {
        let (repo, _) = try makeRepo()
        let session = PracticeSession(
            id: "s1",
            skillId: "handstand",
            date: Date(),
            durationMinutes: 10,
            notes: nil,
            completedAt: nil,
            setsCompleted: 3,
            targetValuePerSet: 20,
            restSeconds: 45
        )
        try await repo.logSession(session)
        let results = try await repo.getRecentSessions(limit: 10)
        #expect(results.count == 1)
        #expect(results[0].id == "s1")
        #expect(results[0].durationMinutes == 10)
        #expect(results[0].targetValuePerSet == 20)
        #expect(results[0].restSeconds == 45)
    }

    @Test("getRecentSessions orders by date desc")
    func orderingDesc() async throws {
        let (repo, _) = try makeRepo()
        let older = PracticeSession(id: "old", skillId: "handstand", date: Date(timeIntervalSinceNow: -3600), durationMinutes: 5, notes: nil, completedAt: nil)
        let newer = PracticeSession(id: "new", skillId: "handstand", date: Date(), durationMinutes: 8, notes: nil, completedAt: nil)
        try await repo.logSession(older)
        try await repo.logSession(newer)
        let results = try await repo.getRecentSessions(limit: 10)
        #expect(results[0].id == "new")
        #expect(results[1].id == "old")
    }

    @Test("getSessionsForSkill filters correctly")
    func filterBySkill() async throws {
        let (repo, _) = try makeRepo()
        let s1 = PracticeSession(id: "a", skillId: "handstand", date: Date(), durationMinutes: 5, notes: nil, completedAt: nil)
        let s2 = PracticeSession(id: "b", skillId: "pullups", date: Date(), durationMinutes: 3, notes: nil, completedAt: nil)
        try await repo.logSession(s1)
        try await repo.logSession(s2)
        let results = try await repo.getSessionsForSkill("handstand")
        #expect(results.count == 1)
        #expect(results[0].id == "a")
    }

    @Test("logSession upserts on conflict")
    func upsert() async throws {
        let (repo, _) = try makeRepo()
        let session = PracticeSession(id: "s1", skillId: "handstand", date: Date(), durationMinutes: 5, notes: nil, completedAt: nil)
        try await repo.logSession(session)
        let updated = PracticeSession(id: "s1", skillId: "handstand", date: session.date, durationMinutes: 20, notes: "updated", completedAt: nil, setsCompleted: 4, targetValuePerSet: 25, restSeconds: 60)
        try await repo.logSession(updated)
        let results = try await repo.getRecentSessions(limit: 10)
        #expect(results.count == 1)
        #expect(results[0].durationMinutes == 20)
        #expect(results[0].targetValuePerSet == 25)
        #expect(results[0].restSeconds == 60)
    }

    @Test("deleteSession removes stored session")
    func deleteSession() async throws {
        let (repo, _) = try makeRepo()
        let session = PracticeSession(id: "s1", skillId: "handstand", date: Date(), durationMinutes: 5, notes: nil, completedAt: nil)
        try await repo.logSession(session)

        try await repo.deleteSession(id: "s1")

        let results = try await repo.getRecentSessions(limit: 10)
        #expect(results.isEmpty)
    }

    @Test("v3 migration preserves existing practice sessions")
    func migrationPreservesExistingSessions() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let dbQueue = try DatabaseQueue(path: tempURL.path)
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "practice_sessions", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("skillId", .text).notNull()
                t.column("date", .double).notNull()
                t.column("durationMinutes", .integer).notNull()
                t.column("notes", .text)
                t.column("completedAt", .double)
            }
            try db.create(table: "skill_progress", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("skillId", .text).notNull()
                t.column("trackId", .text)
                t.column("snapshotDate", .double).notNull()
                t.column("practiceCount", .integer).notNull().defaults(to: 0)
                t.column("lastPracticeDate", .double)
            }
        }
        migrator.registerMigration("v2") { db in
            try db.alter(table: "practice_sessions") { t in
                t.add(column: "setsCompleted", .integer).notNull().defaults(to: 0)
                t.add(column: "plannedSessionId", .text)
                t.add(column: "isPersonalRecord", .boolean).notNull().defaults(to: false)
                t.add(column: "sessionScore", .integer).notNull().defaults(to: 0)
            }
            try db.create(table: "user_skills") { t in
                t.primaryKey("id", .text)
                t.column("skillId", .text).notNull()
                t.column("level", .text).notNull()
                t.column("weeklyFrequency", .integer).notNull()
                t.column("isActive", .boolean).notNull()
                t.column("addedAt", .double).notNull()
            }
            try db.create(table: "training_programs") { t in
                t.primaryKey("id", .text)
                t.column("skillId", .text).notNull()
                t.column("level", .text).notNull()
                t.column("weeklyFrequency", .integer).notNull()
                t.column("generatedAt", .double).notNull()
            }
            try db.create(table: "planned_sessions") { t in
                t.primaryKey("id", .text)
                t.column("programId", .text).notNull()
                t.column("scheduledDate", .double).notNull()
                t.column("prescriptionData", .blob).notNull()
                t.column("completedSessionId", .text)
                t.column("isSkipped", .boolean).notNull().defaults(to: false)
            }
        }
        try migrator.migrate(dbQueue)
        try await dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO practice_sessions
                (id, skillId, date, durationMinutes, notes, completedAt, setsCompleted, plannedSessionId, isPersonalRecord, sessionScore)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    "legacy-1",
                    "handstand",
                    Date().timeIntervalSince1970,
                    12,
                    "legacy",
                    nil,
                    3,
                    nil,
                    false,
                    30
                ]
            )
        }

        let appDatabase = try AppDatabase(path: tempURL.path)
        let repo = LocalPracticeSessionRepository(db: appDatabase)
        let results = try await repo.getRecentSessions(limit: 10)

        #expect(results.count == 1)
        #expect(results[0].id == "legacy-1")
        #expect(results[0].targetValuePerSet == 0)
        #expect(results[0].restSeconds == 0)
    }
}
