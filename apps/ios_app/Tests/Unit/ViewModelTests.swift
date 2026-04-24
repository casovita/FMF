import Testing
import Foundation
@testable import FMF

private final class MockSkillRepository: SkillRepository, @unchecked Sendable {
    let catalog: [Skill]
    var shouldThrow = false
    var snapshots: [String: ProgressSnapshot] = [:]

    init(catalog: [Skill] = [
        Skill(id: "handstand", name: "Handstand", description: "Balance on your hands", category: .balance),
        Skill(id: "pullups", name: "Pull-ups", description: "Upper body pulling", category: .strength, prescriptionType: .reps)
    ]) {
        self.catalog = catalog
    }

    func getSkills() async throws -> [Skill] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        return catalog
    }

    func getSkillById(_ id: String) async throws -> Skill? {
        catalog.first(where: { $0.id == id })
    }

    func skillProgressStream(skillId: String) -> AsyncStream<ProgressSnapshot?> {
        AsyncStream { continuation in
            continuation.yield(snapshots[skillId])
            continuation.finish()
        }
    }

    func getProgressSnapshot(skillId: String) async throws -> ProgressSnapshot? {
        snapshots[skillId]
    }

    func saveProgressSnapshot(_ snapshot: ProgressSnapshot) async throws {
        snapshots[snapshot.skillId] = snapshot
    }
}

private final class MockSessionRepository: PracticeSessionRepository, @unchecked Sendable {
    private(set) var logged: [PracticeSession] = []
    var shouldThrow = false

    func logSession(_ session: PracticeSession) async throws {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        logged.removeAll(where: { $0.id == session.id })
        logged.append(session)
    }

    func getSessionsForSkill(_ id: String) async throws -> [PracticeSession] {
        logged.filter { $0.skillId == id }.sorted { $0.date > $1.date }
    }

    func getRecentSessions(limit: Int) async throws -> [PracticeSession] {
        Array(logged.sorted { $0.date > $1.date }.prefix(limit))
    }
}

private final class MockUserSkillRepository: UserSkillRepository, @unchecked Sendable {
    var userSkills: [UserSkill] = []

    func getUserSkills() async throws -> [UserSkill] {
        userSkills
    }

    func getUserSkill(id: String) async throws -> UserSkill? {
        userSkills.first(where: { $0.id == id })
    }

    func saveUserSkill(_ skill: UserSkill) async throws {
        userSkills.removeAll(where: { $0.id == skill.id })
        userSkills.append(skill)
    }

    func deleteUserSkill(id: String) async throws {
        userSkills.removeAll(where: { $0.id == id })
    }

    func userSkillStream() -> AsyncStream<[UserSkill]> {
        AsyncStream { continuation in
            continuation.yield(userSkills)
            continuation.finish()
        }
    }
}

private final class MockTrainingProgramRepository: TrainingProgramRepository, @unchecked Sendable {
    var programsBySkillId: [String: TrainingProgram] = [:]
    var plannedSessionsByProgramId: [String: [PlannedSession]] = [:]

    func getProgram(for skillId: String) async throws -> TrainingProgram? {
        programsBySkillId[skillId]
    }

    func saveProgram(_ program: TrainingProgram) async throws {
        programsBySkillId[program.skillId] = program
    }

    func getPlannedSessions(for programId: String) async throws -> [PlannedSession] {
        plannedSessionsByProgramId[programId] ?? []
    }

    func getAllPlannedSessions(for skillId: String) async throws -> [PlannedSession] {
        guard let program = programsBySkillId[skillId] else { return [] }
        return plannedSessionsByProgramId[program.id] ?? []
    }

    func savePlannedSession(_ session: PlannedSession) async throws {
        plannedSessionsByProgramId[session.programId, default: []].append(session)
    }

    func savePlannedSessions(_ sessions: [PlannedSession]) async throws {
        guard let programId = sessions.first?.programId else { return }
        plannedSessionsByProgramId[programId] = sessions
    }

    func markSessionComplete(id: String, completedSessionId: String) async throws {
        for key in plannedSessionsByProgramId.keys {
            plannedSessionsByProgramId[key] = plannedSessionsByProgramId[key]?.map { session in
                guard session.id == id else { return session }
                var updated = session
                updated.completedSessionId = completedSessionId
                return updated
            }
        }
    }

    func skipSession(id: String) async throws {
        for key in plannedSessionsByProgramId.keys {
            plannedSessionsByProgramId[key] = plannedSessionsByProgramId[key]?.map { session in
                guard session.id == id else { return session }
                var updated = session
                updated.isSkipped = true
                return updated
            }
        }
    }
}

private final class MockCompletionService: PracticeSessionCompleting, @unchecked Sendable {
    var shouldThrow = false
    private(set) var completedSessions: [PracticeSession] = []

    func completeSession(_ session: PracticeSession) async throws -> PracticeSession {
        if shouldThrow { throw URLError(.cannotConnectToHost) }
        completedSessions.append(session)
        return session
    }
}

private func makeSession(
    id: String = "s1",
    skillId: String = "handstand",
    daysAgo: Int = 0,
    durationMinutes: Int = 5,
    sessionScore: Int = 30
) -> PracticeSession {
    PracticeSession(
        id: id,
        skillId: skillId,
        date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date(),
        durationMinutes: durationMinutes,
        notes: nil,
        completedAt: nil,
        setsCompleted: 3,
        plannedSessionId: nil,
        isPersonalRecord: false,
        sessionScore: sessionScore
    )
}

private func makePlannedSession(id: String = "planned-1", programId: String = "program-1", daysOffset: Int = 0) -> PlannedSession {
    PlannedSession(
        id: id,
        programId: programId,
        scheduledDate: Calendar.current.date(byAdding: .day, value: daysOffset, to: Date()) ?? Date(),
        prescription: SessionPrescription(sets: 3, target: .duration(seconds: 20), notes: "Hold quality"),
        completedSessionId: nil,
        isSkipped: false
    )
}

@Suite("HomeViewModel")
@MainActor
struct HomeViewModelTests {
    @Test("load builds dashboard items from active skills")
    func loadBuildsDashboard() async throws {
        let skillRepo = MockSkillRepository()
        let userSkillRepo = MockUserSkillRepository()
        userSkillRepo.userSkills = [UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)]
        let trainingRepo = MockTrainingProgramRepository()
        let program = TrainingProgram(id: "program-1", skillId: "handstand", level: .beginner, weeklyFrequency: 3, generatedAt: Date())
        trainingRepo.programsBySkillId["handstand"] = program
        trainingRepo.plannedSessionsByProgramId["program-1"] = [makePlannedSession(programId: "program-1")]
        let sessionRepo = MockSessionRepository()
        try await sessionRepo.logSession(makeSession())

        let vm = HomeViewModel(
            skillRepo: skillRepo,
            userSkillRepo: userSkillRepo,
            trainingProgramRepo: trainingRepo,
            sessionRepo: sessionRepo
        )
        await vm.load()

        #expect(vm.dashboardItems.count == 1)
        #expect(vm.skillCatalog.count == 2)
        #expect(vm.dashboardItems.first?.skill.id == "handstand")
    }

    @Test("load sets error when skills fail")
    func loadHandlesFailure() async {
        let skillRepo = MockSkillRepository()
        skillRepo.shouldThrow = true
        let vm = HomeViewModel(
            skillRepo: skillRepo,
            userSkillRepo: MockUserSkillRepository(),
            trainingProgramRepo: MockTrainingProgramRepository(),
            sessionRepo: MockSessionRepository()
        )
        await vm.load()
        #expect(vm.errorMessage != nil)
        #expect(vm.dashboardItems.isEmpty)
    }
}

@Suite("ProgressViewModel")
@MainActor
struct ProgressViewModelTests {
    @Test("load builds per-skill summaries")
    func loadBuildsSummaries() async throws {
        let skillRepo = MockSkillRepository()
        let userSkillRepo = MockUserSkillRepository()
        userSkillRepo.userSkills = [UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)]
        let trainingRepo = MockTrainingProgramRepository()
        let program = TrainingProgram(id: "program-1", skillId: "handstand", level: .beginner, weeklyFrequency: 3, generatedAt: Date())
        trainingRepo.programsBySkillId["handstand"] = program
        trainingRepo.plannedSessionsByProgramId["program-1"] = [makePlannedSession(programId: "program-1")]
        let sessionRepo = MockSessionRepository()
        try await sessionRepo.logSession(makeSession())

        let vm = ProgressViewModel(
            sessionRepo: sessionRepo,
            skillRepo: skillRepo,
            userSkillRepo: userSkillRepo,
            trainingProgramRepo: trainingRepo
        )
        await vm.load()

        #expect(vm.summaries.count == 1)
        #expect(vm.summaries.first?.skill.id == "handstand")
        #expect(vm.summaries.first?.stats.totalSessions == 1)
        #expect(vm.summaries.first?.totalPlannedSessions == 1)
        #expect(vm.summaries.first?.completedPlannedSessions == 0)
    }

    @Test("load orders summaries by next planned session date")
    func loadOrdersSummariesByUpcomingWork() async throws {
        let skillRepo = MockSkillRepository(
            catalog: [
                Skill(id: "handstand", name: "Handstand", description: "", category: .balance),
                Skill(id: "pullups", name: "Pull-ups", description: "", category: .strength, prescriptionType: .reps)
            ]
        )
        let userSkillRepo = MockUserSkillRepository()
        userSkillRepo.userSkills = [
            UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3),
            UserSkill(skillId: "pullups", level: .beginner, weeklyFrequency: 2)
        ]

        let trainingRepo = MockTrainingProgramRepository()
        let handstandProgram = TrainingProgram(id: "program-handstand", skillId: "handstand", level: .beginner, weeklyFrequency: 3, generatedAt: Date())
        let pullupsProgram = TrainingProgram(id: "program-pullups", skillId: "pullups", level: .beginner, weeklyFrequency: 2, generatedAt: Date())
        trainingRepo.programsBySkillId["handstand"] = handstandProgram
        trainingRepo.programsBySkillId["pullups"] = pullupsProgram
        trainingRepo.plannedSessionsByProgramId["program-handstand"] = [
            makePlannedSession(id: "planned-handstand", programId: "program-handstand", daysOffset: 2)
        ]
        trainingRepo.plannedSessionsByProgramId["program-pullups"] = [
            makePlannedSession(id: "planned-pullups", programId: "program-pullups", daysOffset: 0)
        ]

        let vm = ProgressViewModel(
            sessionRepo: MockSessionRepository(),
            skillRepo: skillRepo,
            userSkillRepo: userSkillRepo,
            trainingProgramRepo: trainingRepo
        )

        await vm.load()

        #expect(vm.summaries.map(\.skill.id) == ["pullups", "handstand"])
    }
}

@Suite("PracticeSessionViewModel")
@MainActor
struct PracticeSessionViewModelTests {
    private func makeVM(
        skills: [Skill]? = nil,
        completionService: MockCompletionService = MockCompletionService(),
        selectedSkillId: String? = nil,
        plannedSession: PlannedSession? = nil
    ) -> PracticeSessionViewModel {
        let catalog = skills ?? [
            Skill(id: "handstand", name: "Handstand", description: "", category: .balance),
            Skill(id: "pullups", name: "Pull-ups", description: "", category: .strength, prescriptionType: .reps)
        ]
        return PracticeSessionViewModel(
            skills: catalog,
            completionService: completionService,
            selectedSkillId: selectedSkillId,
            plannedSession: plannedSession
        )
    }

    @Test("selected skill defaults to first skill")
    func defaultSkillId() {
        let vm = makeVM()
        #expect(vm.selectedSkillId == "handstand")
    }

    @Test("planned session seeds result and locks skill")
    func plannedSessionSeedsValues() {
        let planned = makePlannedSession()
        let vm = makeVM(selectedSkillId: "handstand", plannedSession: planned)
        #expect(vm.isSkillLocked == true)
        #expect(vm.performanceValue == 20)
        #expect(vm.setsCompleted == 3)
    }

    @Test("submit completes session and sets didSave")
    func submitCompletesSession() async {
        let completionService = MockCompletionService()
        let vm = makeVM(completionService: completionService)
        vm.durationMinutes = 15
        vm.performanceValue = 90
        vm.setsCompleted = 3

        await vm.submit()

        #expect(vm.didSave == true)
        #expect(completionService.completedSessions.count == 1)
        #expect(completionService.completedSessions[0].sessionScore == 90)
    }

    @Test("submit sets error on failure")
    func submitHandlesError() async {
        let completionService = MockCompletionService()
        completionService.shouldThrow = true
        let vm = makeVM(completionService: completionService)
        vm.performanceValue = 60

        await vm.submit()

        #expect(vm.didSave == false)
        #expect(vm.errorMessage != nil)
    }
}
