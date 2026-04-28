import Foundation
import GRDB

final class AppDatabase: Sendable {
    let dbWriter: any DatabaseWriter

    static let shared: AppDatabase = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = urls[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbURL = dir.appendingPathComponent("fmf_database.sqlite")
        return try! AppDatabase(path: dbURL.path)
    }()

    /// Real file-backed database (production)
    init(path: String) throws {
        dbWriter = try DatabasePool(path: path)
        try migrate()
    }

    /// In-memory database (tests)
    static func inMemory() throws -> AppDatabase {
        return try AppDatabase()
    }

    private init() throws {
        dbWriter = try DatabaseQueue()
        try migrate()
    }

    private func migrate() throws {
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

        migrator.registerMigration("v3") { db in
            try db.alter(table: "practice_sessions") { t in
                t.add(column: "targetValuePerSet", .integer).notNull().defaults(to: 0)
                t.add(column: "restSeconds", .integer).notNull().defaults(to: 0)
            }
        }

        migrator.registerMigration("v4") { db in
            try db.alter(table: "practice_sessions") { t in
                t.add(column: "durationSetValuesData", .blob)
            }
        }

        try migrator.migrate(dbWriter)
    }
}
