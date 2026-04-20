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
        try migrator.migrate(dbWriter)
    }
}
