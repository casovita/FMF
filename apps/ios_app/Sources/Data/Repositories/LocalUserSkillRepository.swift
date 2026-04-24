import Foundation
import GRDB

final class LocalUserSkillRepository: UserSkillRepository {
    private let db: AppDatabase

    init(db: AppDatabase) {
        self.db = db
    }

    func getUserSkills() async throws -> [UserSkill] {
        try await db.dbWriter.read { db in
            try UserSkillRecord
                .filter(Column("isActive") == true)
                .fetchAll(db)
                .compactMap { $0.asDomain }
        }
    }

    func getUserSkill(id: String) async throws -> UserSkill? {
        try await db.dbWriter.read { db in
            try UserSkillRecord
                .filter(Column("id") == id)
                .fetchOne(db)?
                .asDomain
        }
    }

    func saveUserSkill(_ skill: UserSkill) async throws {
        let record = UserSkillRecord(from: skill)
        try await db.dbWriter.write { db in
            try record.save(db)
        }
    }

    func deleteUserSkill(id: String) async throws {
        _ = try await db.dbWriter.write { db in
            try UserSkillRecord
                .filter(Column("id") == id)
                .deleteAll(db)
        }
    }

    func userSkillStream() -> AsyncStream<[UserSkill]> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> [UserSkill] in
                try UserSkillRecord
                    .filter(Column("isActive") == true)
                    .fetchAll(db)
                    .compactMap { $0.asDomain }
            }
            let cancellable = observation.start(
                in: self.db.dbWriter,
                onError: { _ in continuation.yield([]) },
                onChange: { skills in continuation.yield(skills) }
            )
            final class CancellableBox: @unchecked Sendable {
                let token: AnyDatabaseCancellable
                init(_ token: AnyDatabaseCancellable) { self.token = token }
            }
            let box = CancellableBox(cancellable)
            continuation.onTermination = { _ in box.token.cancel() }
        }
    }
}
