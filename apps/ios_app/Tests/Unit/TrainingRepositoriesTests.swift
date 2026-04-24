import Testing
import Foundation
import GRDB
@testable import FMF

@Suite("UserSkillRepository")
struct UserSkillRepositoryTests {
    private func makeRepo() throws -> LocalUserSkillRepository {
        let db = try AppDatabase.inMemory()
        return LocalUserSkillRepository(db: db)
    }

    @Test("save and fetch active user skill")
    func saveAndFetch() async throws {
        let repo = try makeRepo()
        let skill = UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)

        try await repo.saveUserSkill(skill)
        let fetched = try await repo.getUserSkill(id: "handstand")

        #expect(fetched?.skillId == "handstand")
        #expect(fetched?.weeklyFrequency == 3)
        #expect(fetched?.isActive == true)
    }

    @Test("inactive skills do not appear in active list")
    func inactiveFiltered() async throws {
        let repo = try makeRepo()
        var skill = UserSkill(skillId: "pullups", level: .intermediate, weeklyFrequency: 2)
        skill.isActive = false

        try await repo.saveUserSkill(skill)
        let active = try await repo.getUserSkills()

        #expect(active.isEmpty)
    }
}

@Suite("TrainingProgramRepository")
struct TrainingProgramRepositoryTests {
    private func makeRepo() throws -> LocalTrainingProgramRepository {
        let db = try AppDatabase.inMemory()
        return LocalTrainingProgramRepository(db: db)
    }

    @Test("save and fetch program with planned sessions")
    func saveAndFetchProgram() async throws {
        let repo = try makeRepo()
        let program = TrainingProgram(
            id: "program-1",
            skillId: "handstand",
            level: .beginner,
            weeklyFrequency: 3,
            generatedAt: Date()
        )
        let session = PlannedSession(
            id: "planned-1",
            programId: "program-1",
            scheduledDate: Date(),
            prescription: SessionPrescription(sets: 3, target: .duration(seconds: 20), notes: "Hold tight"),
            completedSessionId: nil,
            isSkipped: false
        )

        try await repo.saveProgram(program)
        try await repo.savePlannedSessions([session])

        let fetchedProgram = try await repo.getProgram(for: "handstand")
        let fetchedSessions = try await repo.getPlannedSessions(for: "program-1")

        #expect(fetchedProgram?.id == "program-1")
        #expect(fetchedSessions.count == 1)
        #expect(fetchedSessions.first?.prescription.displayString == "3×20s")
    }

    @Test("markSessionComplete and skipSession update stored session")
    func updatesPlannedSessionState() async throws {
        let repo = try makeRepo()
        let program = TrainingProgram(
            id: "program-1",
            skillId: "handstand",
            level: .beginner,
            weeklyFrequency: 3,
            generatedAt: Date()
        )
        let session = PlannedSession(
            id: "planned-1",
            programId: "program-1",
            scheduledDate: Date(),
            prescription: SessionPrescription(sets: 3, target: .duration(seconds: 20), notes: "Hold tight"),
            completedSessionId: nil,
            isSkipped: false
        )

        try await repo.saveProgram(program)
        try await repo.savePlannedSessions([session])
        try await repo.markSessionComplete(id: "planned-1", completedSessionId: "session-1")
        try await repo.skipSession(id: "planned-1")

        let updated = try await repo.getPlannedSessions(for: "program-1").first
        #expect(updated?.completedSessionId == "session-1")
        #expect(updated?.isSkipped == true)
    }
}

@Suite("Database migrations")
struct DatabaseMigrationTests {
    @Test("v2 columns exist for academy data")
    func v2ColumnsExist() async throws {
        let db = try AppDatabase.inMemory()

        let practiceColumns = try await db.dbWriter.read { database in
            try Row.fetchAll(database, sql: "PRAGMA table_info(practice_sessions)")
                .compactMap { $0["name"] as String? }
        }
        let userSkillColumns = try await db.dbWriter.read { database in
            try Row.fetchAll(database, sql: "PRAGMA table_info(user_skills)")
                .compactMap { $0["name"] as String? }
        }
        let programColumns = try await db.dbWriter.read { database in
            try Row.fetchAll(database, sql: "PRAGMA table_info(training_programs)")
                .compactMap { $0["name"] as String? }
        }
        let plannedColumns = try await db.dbWriter.read { database in
            try Row.fetchAll(database, sql: "PRAGMA table_info(planned_sessions)")
                .compactMap { $0["name"] as String? }
        }

        #expect(practiceColumns.contains("plannedSessionId"))
        #expect(practiceColumns.contains("isPersonalRecord"))
        #expect(practiceColumns.contains("sessionScore"))
        #expect(userSkillColumns.contains("weeklyFrequency"))
        #expect(programColumns.contains("generatedAt"))
        #expect(plannedColumns.contains("prescriptionData"))
    }
}
