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

    func deleteSession(id: String) async throws {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        logged.removeAll { $0.id == id }
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

    func clearCompletedSession(id: String) async throws {
        for key in plannedSessionsByProgramId.keys {
            plannedSessionsByProgramId[key] = plannedSessionsByProgramId[key]?.map { session in
                guard session.id == id else { return session }
                var updated = session
                updated.completedSessionId = nil
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

private final class MockDeletionService: PracticeSessionDeleting, @unchecked Sendable {
    private(set) var deletedSessions: [PracticeSession] = []
    var shouldThrow = false

    func deleteSession(_ session: PracticeSession) async throws {
        if shouldThrow { throw URLError(.cannotRemoveFile) }
        deletedSessions.append(session)
    }
}

private func makeSession(
    id: String = "s1",
    skillId: String = "handstand",
    daysAgo: Int = 0,
    durationMinutes: Int = 5,
    targetValuePerSet: Int = 15,
    restSeconds: Int = 45,
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
        targetValuePerSet: targetValuePerSet,
        restSeconds: restSeconds,
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

@Suite("SkillsBrowseViewModel")
@MainActor
struct SkillsBrowseViewModelTests {
    @Test("load builds sectioned roadmap state")
    func loadBuildsRoadmapSections() async {
        let skillRepo = MockSkillRepository(
            catalog: [
                Skill(id: "handstand", name: "Handstand", description: "", category: .balance),
                Skill(id: "pullups", name: "Pull-ups", description: "", category: .strength, prescriptionType: .reps),
                Skill(id: "handstand_pushups", name: "Handstand Push-ups", description: "", category: .bodyweight, prescriptionType: .reps)
            ]
        )
        let userSkillRepo = MockUserSkillRepository()
        userSkillRepo.userSkills = [UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)]

        let trainingRepo = MockTrainingProgramRepository()
        let handstandProgram = TrainingProgram(id: "program-handstand", skillId: "handstand", level: .beginner, weeklyFrequency: 3, generatedAt: Date())
        trainingRepo.programsBySkillId["handstand"] = handstandProgram
        trainingRepo.plannedSessionsByProgramId["program-handstand"] = [
            makePlannedSession(id: "planned-handstand", programId: "program-handstand", daysOffset: 1)
        ]

        let vm = SkillsBrowseViewModel(
            skillRepo: skillRepo,
            userSkillRepo: userSkillRepo,
            trainingProgramRepo: trainingRepo,
            sessionRepo: MockSessionRepository()
        )

        await vm.load()

        #expect(vm.continueTrainingItems.map(\.skill.id) == ["handstand"])
        #expect(vm.unlockNextItems.map(\.skill.id) == ["pullups"])
        #expect(vm.futureCurriculumItems.map(\.skill.id) == ["handstand_pushups"])
        #expect(vm.continueTrainingItems.first?.nextPlannedSession?.id == "planned-handstand")
    }

    @Test("search and filters narrow visible roadmap items without changing base order")
    func searchAndFiltersNarrowVisibleItems() async {
        let skillRepo = MockSkillRepository(
            catalog: [
                Skill(id: "handstand", name: "Handstand", description: "Balance", category: .balance),
                Skill(id: "pullups", name: "Pull-ups", description: "Strength", category: .strength, prescriptionType: .reps),
                Skill(id: "handstand_pushups", name: "Handstand Push-ups", description: "Pressing", category: .bodyweight, prescriptionType: .reps)
            ]
        )
        let userSkillRepo = MockUserSkillRepository()
        userSkillRepo.userSkills = [UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)]

        let vm = SkillsBrowseViewModel(
            skillRepo: skillRepo,
            userSkillRepo: userSkillRepo,
            trainingProgramRepo: MockTrainingProgramRepository(),
            sessionRepo: MockSessionRepository()
        )

        await vm.load()
        vm.searchText = "hand"
        vm.selectedStatusFilter = .future

        #expect(vm.visibleItems.map(\.skill.id) == ["handstand_pushups"])

        vm.selectedStatusFilter = .all
        vm.selectedCategory = .balance

        #expect(vm.visibleItems.map(\.skill.id) == ["handstand"])
    }

    @Test("active items include PR and practice progress when available")
    func activeItemsExposePersonalRecordAndProgress() async throws {
        let skillRepo = MockSkillRepository(
            catalog: [
                Skill(id: "handstand", name: "Handstand", description: "", category: .balance)
            ]
        )
        skillRepo.snapshots["handstand"] = ProgressSnapshot(
            id: "snapshot-handstand",
            skillId: "handstand",
            trackId: nil,
            snapshotDate: Date(),
            practiceCount: 7,
            lastPracticeDate: Date()
        )

        let userSkillRepo = MockUserSkillRepository()
        userSkillRepo.userSkills = [UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)]

        let trainingRepo = MockTrainingProgramRepository()
        let program = TrainingProgram(id: "program-handstand", skillId: "handstand", level: .beginner, weeklyFrequency: 3, generatedAt: Date())
        trainingRepo.programsBySkillId["handstand"] = program

        let sessionRepo = MockSessionRepository()
        try await sessionRepo.logSession(makeSession(id: "session-1", sessionScore: 45))

        let vm = SkillsBrowseViewModel(
            skillRepo: skillRepo,
            userSkillRepo: userSkillRepo,
            trainingProgramRepo: trainingRepo,
            sessionRepo: sessionRepo
        )

        await vm.load()

        #expect(vm.continueTrainingItems.first?.personalRecord == .duration(seconds: 45))
        #expect(vm.continueTrainingItems.first?.practiceCount == 7)
    }

    @Test("active items omit PR and progress when no data exists")
    func activeItemsOmitMetricsWhenUnavailable() async {
        let skillRepo = MockSkillRepository(
            catalog: [
                Skill(id: "handstand", name: "Handstand", description: "", category: .balance)
            ]
        )

        let userSkillRepo = MockUserSkillRepository()
        userSkillRepo.userSkills = [UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)]

        let vm = SkillsBrowseViewModel(
            skillRepo: skillRepo,
            userSkillRepo: userSkillRepo,
            trainingProgramRepo: MockTrainingProgramRepository(),
            sessionRepo: MockSessionRepository()
        )

        await vm.load()

        #expect(vm.continueTrainingItems.first?.personalRecord == nil)
        #expect(vm.continueTrainingItems.first?.practiceCount == nil)
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

@Suite("SkillDetailViewModel")
@MainActor
struct SkillDetailViewModelTests {
    private func makeVM(
        skillRepo: MockSkillRepository? = nil,
        trainingRepo: MockTrainingProgramRepository? = nil,
        sessionRepo: MockSessionRepository? = nil,
        skillId: String = "handstand"
    ) -> SkillDetailViewModel {
        SkillDetailViewModel(
            skillId: skillId,
            skillRepo: skillRepo ?? MockSkillRepository(),
            trainingProgramRepo: trainingRepo ?? MockTrainingProgramRepository(),
            sessionRepo: sessionRepo ?? MockSessionRepository()
        )
    }

    @Test("load builds empty PR state when no sessions exist")
    func loadBuildsEmptyPRState() async {
        let vm = makeVM()

        await vm.load()

        #expect(vm.skill?.id == "handstand")
        #expect(vm.chartState.isEmpty == true)
        #expect(vm.chartState.currentScore == nil)
        #expect(vm.chartState.headlineValue == "--")
    }

    @Test("duration skill uses cumulative max PR trend")
    func durationSkillUsesCumulativeMax() async throws {
        let sessionRepo = MockSessionRepository()
        try await sessionRepo.logSession(makeSession(id: "s1", daysAgo: 3, sessionScore: 20))
        try await sessionRepo.logSession(makeSession(id: "s2", daysAgo: 2, sessionScore: 45))
        try await sessionRepo.logSession(makeSession(id: "s3", daysAgo: 1, sessionScore: 30))

        let vm = makeVM(sessionRepo: sessionRepo)
        await vm.load()

        #expect(vm.chartState.points.map(\.score) == [20, 45, 45])
        #expect(vm.chartState.currentScore == 45)
        #expect(vm.chartState.headlineValue == "45s")
        #expect(vm.chartState.headlineUnit == nil)
        #expect(vm.chartState.trendText == "Increasing")
    }

    @Test("reps skill formats PR as reps")
    func repsSkillFormatsAsReps() async throws {
        let skillRepo = MockSkillRepository(
            catalog: [
                Skill(id: "pullups", name: "Pull-ups", description: "", category: .strength, prescriptionType: .reps)
            ]
        )
        let sessionRepo = MockSessionRepository()
        try await sessionRepo.logSession(makeSession(id: "r1", skillId: "pullups", daysAgo: 1, sessionScore: 12))

        let vm = makeVM(skillRepo: skillRepo, sessionRepo: sessionRepo, skillId: "pullups")
        await vm.load()

        #expect(vm.chartState.points.map(\.score) == [12])
        #expect(vm.chartState.headlineValue == "12")
        #expect(vm.chartState.headlineUnit == "reps")
    }

    @Test("weight formatter stays extensible")
    func weightFormatterExtensible() {
        let state = PersonalRecordChartState(
            metricKind: .weight(unit: "kg"),
            currentScore: 84,
            points: [
                PersonalRecordPoint(id: "w1", date: Date(), score: 84)
            ]
        )

        #expect(state.headlineValue == "84 kg")
        #expect(state.headlineUnit == "kg")
    }

    @Test("next planned session still available for action routing")
    func nextPlannedSessionStillAvailable() async {
        let trainingRepo = MockTrainingProgramRepository()
        let program = TrainingProgram(id: "program-1", skillId: "handstand", level: .beginner, weeklyFrequency: 3, generatedAt: Date())
        trainingRepo.programsBySkillId["handstand"] = program
        trainingRepo.plannedSessionsByProgramId["program-1"] = [
            makePlannedSession(id: "later", programId: "program-1", daysOffset: 3),
            makePlannedSession(id: "sooner", programId: "program-1", daysOffset: 1)
        ]

        let vm = makeVM(trainingRepo: trainingRepo)
        await vm.load()

        #expect(vm.nextPlannedSession?.id == "sooner")
    }

    @Test("deleteSession removes session from view model state")
    func deleteSessionRemovesState() async throws {
        let skillRepo = MockSkillRepository()
        let trainingRepo = MockTrainingProgramRepository()
        let sessionRepo = MockSessionRepository()
        let deletionService = MockDeletionService()
        let oldSession = makeSession(id: "s1", daysAgo: 1, sessionScore: 15)
        let newSession = makeSession(id: "s2", daysAgo: 0, sessionScore: 20)
        try await sessionRepo.logSession(oldSession)
        try await sessionRepo.logSession(newSession)

        let vm = SkillDetailViewModel(
            skillId: "handstand",
            skillRepo: skillRepo,
            trainingProgramRepo: trainingRepo,
            sessionRepo: sessionRepo,
            deletionService: deletionService
        )

        await vm.load()
        try await sessionRepo.deleteSession(id: "s2")

        await vm.deleteSession(newSession)

        #expect(deletionService.deletedSessions.map(\.id) == ["s2"])
        #expect(vm.sessions.map(\.id) == ["s1"])
    }
}

@Suite("PracticeSessionViewModel")
@MainActor
struct PracticeSessionViewModelTests {
    private func makeVM(
        skills: [Skill]? = nil,
        completionService: MockCompletionService = MockCompletionService(),
        selectedSkillId: String = "handstand",
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

    @Test("duration skill initializes adaptive fields and title")
    func durationSkillDefaults() {
        let vm = makeVM(selectedSkillId: "handstand")
        #expect(vm.selectedSkillId == "handstand")
        #expect(vm.navigationTitle == "Log a handstand session")
        #expect(vm.targetLabel == "Seconds per set")
        #expect(vm.targetValuePerSet == 15)
        #expect(vm.restSeconds == 45)
        #expect(vm.durationSetValues == [15, 15, 15])
        #expect(vm.bestSetValueText == "15 sec")
        #expect(vm.cumulativeValueText == "45 sec")
    }

    @Test("rep skill initializes adaptive fields and emoji suggestions")
    func repSkillDefaults() {
        let vm = makeVM(selectedSkillId: "pullups")
        #expect(vm.navigationTitle == "Log a pull-ups session")
        #expect(vm.targetLabel == "Reps per set")
        #expect(vm.targetValuePerSet == 5)
        #expect(vm.restSeconds == 90)
        #expect(vm.noteSuggestions.map(\.displayText).contains("💪 Strong"))
    }

    @Test("planned session seeds per-set target")
    func plannedSessionSeedsValues() {
        let planned = makePlannedSession()
        let vm = makeVM(selectedSkillId: "handstand", plannedSession: planned)
        #expect(vm.targetValuePerSet == 20)
        #expect(vm.setsCompleted == 3)
        #expect(vm.durationSetValues == [20, 20, 20])
    }

    @Test("changing set count resizes manual duration inputs")
    func changingSetCountResizesDurationInputs() {
        let vm = makeVM(selectedSkillId: "handstand")
        vm.updateDurationValue(at: 0, value: 18)
        vm.updateDurationValue(at: 1, value: 22)
        vm.updateDurationValue(at: 2, value: 25)

        vm.updateSetsCompleted(5)
        #expect(vm.durationSetValues == [18, 22, 25, 15, 15])

        vm.updateSetsCompleted(2)
        #expect(vm.durationSetValues == [18, 22])
        #expect(vm.bestSetValueText == "22 sec")
        #expect(vm.cumulativeValueText == "40 sec")
    }

    @Test("submit for duration skill completes session and sets didSave")
    func submitCompletesDurationSession() async {
        let completionService = MockCompletionService()
        let vm = makeVM(completionService: completionService)
        vm.updateSetsCompleted(3)
        vm.updateDurationValue(at: 0, value: 20)
        vm.updateDurationValue(at: 1, value: 30)
        vm.updateDurationValue(at: 2, value: 25)
        vm.restSeconds = 45

        await vm.submit()

        #expect(vm.didSave == true)
        #expect(completionService.completedSessions.count == 1)
        #expect(completionService.completedSessions[0].sessionScore == 30)
        #expect(completionService.completedSessions[0].targetValuePerSet == 30)
        #expect(completionService.completedSessions[0].restSeconds == 45)
        #expect(completionService.completedSessions[0].durationMinutes == 3)
    }

    @Test("submit for rep skill stores total reps in session score")
    func submitCompletesRepSession() async {
        let completionService = MockCompletionService()
        let vm = makeVM(completionService: completionService, selectedSkillId: "pullups")
        vm.updateSetsCompleted(4)
        vm.targetValuePerSet = 6
        vm.restSeconds = 90

        #expect(vm.bestSetValueText == "6 reps")
        #expect(vm.cumulativeValueText == "24 reps")

        await vm.submit()

        #expect(vm.didSave == true)
        #expect(completionService.completedSessions[0].sessionScore == 24)
        #expect(completionService.completedSessions[0].durationMinutes > 0)
    }

    @Test("submit requires valid adaptive fields")
    func submitRequiresValidFields() async {
        let completionService = MockCompletionService()
        let vm = makeVM(completionService: completionService)
        vm.durationSetValues = [0, 15, 15]

        await vm.submit()

        #expect(vm.didSave == false)
        #expect(completionService.completedSessions.isEmpty)
    }

    @Test("submit sets error on failure")
    func submitHandlesError() async {
        let completionService = MockCompletionService()
        completionService.shouldThrow = true
        let vm = makeVM(completionService: completionService)
        vm.targetValuePerSet = 60

        await vm.submit()

        #expect(vm.didSave == false)
        #expect(vm.errorMessage != nil)
    }
}
