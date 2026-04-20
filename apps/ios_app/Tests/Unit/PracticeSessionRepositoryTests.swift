import Testing
import Foundation
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
            completedAt: nil
        )
        try await repo.logSession(session)
        let results = try await repo.getRecentSessions(limit: 10)
        #expect(results.count == 1)
        #expect(results[0].id == "s1")
        #expect(results[0].durationMinutes == 10)
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
        let updated = PracticeSession(id: "s1", skillId: "handstand", date: session.date, durationMinutes: 20, notes: "updated", completedAt: nil)
        try await repo.logSession(updated)
        let results = try await repo.getRecentSessions(limit: 10)
        #expect(results.count == 1)
        #expect(results[0].durationMinutes == 20)
    }
}
