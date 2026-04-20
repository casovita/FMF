import Testing
import Foundation
@testable import FMF

@Suite("SkillRepository")
struct SkillRepositoryTests {
    private func makeRepo() throws -> LocalSkillRepository {
        let db = try AppDatabase.inMemory()
        return LocalSkillRepository(db: db)
    }

    @Test("getSkills returns catalog")
    func getCatalog() async throws {
        let repo = try makeRepo()
        let skills = try await repo.getSkills()
        #expect(!skills.isEmpty)
        #expect(skills.contains { $0.id == "handstand" })
    }

    @Test("getSkillById returns correct skill")
    func getById() async throws {
        let repo = try makeRepo()
        let skill = try await repo.getSkillById("handstand")
        #expect(skill?.name == "Handstand")
        #expect(skill?.category == .balance)
    }

    @Test("getSkillById returns nil for unknown id")
    func getByIdMissing() async throws {
        let repo = try makeRepo()
        let skill = try await repo.getSkillById("nonexistent")
        #expect(skill == nil)
    }

    @Test("skillProgressStream emits nil when no progress exists")
    func streamEmitsNilInitially() async throws {
        let repo = try makeRepo()
        var stream = repo.skillProgressStream(skillId: "handstand").makeAsyncIterator()
        let first = await stream.next()
        #expect(first == .some(nil))
    }
}
