import Foundation
import GRDB

final class LocalSkillRepository: SkillRepository {
    private let db: AppDatabase

    // Static catalog — future: load from remote CMS or local JSON bundle
    private static let catalog: [Skill] = [
        Skill(
            id: "handstand",
            name: "Handstand",
            description: "Build balance, body tension, and overhead strength.",
            category: .balance,
            prescriptionType: .duration
        ),
        Skill(
            id: "pullups",
            name: "Pull-ups",
            description: "Develop pulling strength and scapular control.",
            category: .strength,
            prescriptionType: .reps
        ),
        Skill(
            id: "handstand_pushups",
            name: "Handstand Push-ups",
            description: "Master overhead pressing strength and balance combined.",
            category: .bodyweight,
            prescriptionType: .reps
        ),
    ]

    init(db: AppDatabase) {
        self.db = db
    }

    func getSkills() async throws -> [Skill] {
        Self.catalog
    }

    func getSkillById(_ id: String) async throws -> Skill? {
        Self.catalog.first { $0.id == id }
    }

    func getProgressSnapshot(skillId: String) async throws -> ProgressSnapshot? {
        try await db.dbWriter.read { db in
            try SkillProgressRecord
                .filter(Column("skillId") == skillId)
                .order(Column("snapshotDate").desc)
                .fetchOne(db)?
                .asDomain
        }
    }

    func saveProgressSnapshot(_ snapshot: ProgressSnapshot) async throws {
        let record = SkillProgressRecord(from: snapshot)
        try await db.dbWriter.write { db in
            try record.save(db)
        }
    }

    func skillProgressStream(skillId: String) -> AsyncStream<ProgressSnapshot?> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> ProgressSnapshot? in
                let record = try SkillProgressRecord
                    .filter(Column("skillId") == skillId)
                    .order(Column("snapshotDate").desc)
                    .fetchOne(db)
                return record?.asDomain
            }
            let cancellable = observation.start(
                in: self.db.dbWriter,
                onError: { _ in continuation.yield(nil) },
                onChange: { snapshot in continuation.yield(snapshot) }
            )
            // Box non-Sendable cancellable to satisfy Swift 6 concurrency
            final class CancellableBox: @unchecked Sendable {
                let token: AnyDatabaseCancellable
                init(_ token: AnyDatabaseCancellable) { self.token = token }
            }
            let box = CancellableBox(cancellable)
            continuation.onTermination = { _ in box.token.cancel() }
        }
    }
}
