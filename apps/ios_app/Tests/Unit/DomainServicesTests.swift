import Testing
import Foundation
@testable import FMF

// MARK: - PRTracker

@Suite("PRTracker")
struct PRTrackerTests {
    private let tracker = PRTracker()

    @Test("first session sets PR")
    func firstSession() {
        let (pr, isNew) = tracker.evaluate(sessionScore: 30, prescriptionType: .duration, currentPR: nil)
        #expect(pr == .duration(seconds: 30))
        #expect(isNew == true)
    }

    @Test("higher score beats existing PR")
    func higherScore() {
        let (pr, isNew) = tracker.evaluate(sessionScore: 45, prescriptionType: .duration, currentPR: .duration(seconds: 30))
        #expect(pr == .duration(seconds: 45))
        #expect(isNew == true)
    }

    @Test("lower score does not beat PR")
    func lowerScore() {
        let (pr, isNew) = tracker.evaluate(sessionScore: 20, prescriptionType: .duration, currentPR: .duration(seconds: 30))
        #expect(pr == .duration(seconds: 30))
        #expect(isNew == false)
    }

    @Test("rep-based PR detection")
    func repBased() {
        let (pr, isNew) = tracker.evaluate(sessionScore: 8, prescriptionType: .reps, currentPR: .reps(count: 5))
        #expect(pr == .reps(count: 8))
        #expect(isNew == true)
    }

    @Test("zero score on first session is not a PR")
    func zeroScore() {
        let (_, isNew) = tracker.evaluate(sessionScore: 0, prescriptionType: .duration, currentPR: nil)
        #expect(isNew == false)
    }
}

// MARK: - StatsAggregator

@Suite("StatsAggregator")
struct StatsAggregatorTests {
    private let aggregator = StatsAggregator()
    private let skill = Skill(
        id: "handstand",
        name: "Handstand",
        description: "",
        category: .balance,
        prescriptionType: .duration
    )

    private func makeSession(id: String, daysAgo: Int, score: Int = 30) -> PracticeSession {
        PracticeSession(
            id: id,
            skillId: "handstand",
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            durationMinutes: score / 60 + 1,
            notes: nil,
            completedAt: Date(),
            setsCompleted: 3,
            sessionScore: score
        )
    }

    @Test("empty sessions returns empty stats")
    func emptySessions() {
        let stats = aggregator.compute(sessions: [], plannedSessions: [], skill: skill)
        #expect(stats.totalSessions == 0)
        #expect(stats.personalRecord == nil)
        #expect(stats.currentStreak == 0)
    }

    @Test("total sessions count")
    func totalCount() {
        let sessions = [makeSession(id: "a", daysAgo: 2), makeSession(id: "b", daysAgo: 1)]
        let stats = aggregator.compute(sessions: sessions, plannedSessions: [], skill: skill)
        #expect(stats.totalSessions == 2)
    }

    @Test("PR is the highest session score")
    func personalRecord() {
        let sessions = [
            makeSession(id: "a", daysAgo: 5, score: 20),
            makeSession(id: "b", daysAgo: 3, score: 45),
            makeSession(id: "c", daysAgo: 1, score: 30),
        ]
        let stats = aggregator.compute(sessions: sessions, plannedSessions: [], skill: skill)
        #expect(stats.personalRecord == .duration(seconds: 45))
    }

    @Test("current streak counts consecutive days")
    func currentStreak() {
        let today = Date()
        let sessions = [
            PracticeSession(id: "a", skillId: "handstand", date: Calendar.current.date(byAdding: .day, value: -2, to: today)!, durationMinutes: 1, notes: nil, completedAt: nil),
            PracticeSession(id: "b", skillId: "handstand", date: Calendar.current.date(byAdding: .day, value: -1, to: today)!, durationMinutes: 1, notes: nil, completedAt: nil),
            PracticeSession(id: "c", skillId: "handstand", date: today, durationMinutes: 1, notes: nil, completedAt: nil),
        ]
        let stats = aggregator.compute(sessions: sessions, plannedSessions: [], skill: skill)
        #expect(stats.currentStreak == 3)
    }

    @Test("streak resets on gap")
    func streakResets() {
        let today = Date()
        let sessions = [
            PracticeSession(id: "a", skillId: "handstand", date: Calendar.current.date(byAdding: .day, value: -5, to: today)!, durationMinutes: 1, notes: nil, completedAt: nil),
            PracticeSession(id: "b", skillId: "handstand", date: today, durationMinutes: 1, notes: nil, completedAt: nil),
        ]
        let stats = aggregator.compute(sessions: sessions, plannedSessions: [], skill: skill)
        #expect(stats.currentStreak == 1)
    }
}

// MARK: - PlanGenerator

@Suite("PlanGenerator")
struct PlanGeneratorTests {
    private let generator = PlanGenerator()
    private let skill = Skill(
        id: "handstand",
        name: "Handstand",
        description: "",
        category: .balance,
        prescriptionType: .duration
    )

    @Test("generates correct session count for 4 weeks")
    func sessionCount() {
        let userSkill = UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)
        let (_, sessions) = generator.generate(userSkill: userSkill, skill: skill, recentSessions: [])
        #expect(sessions.count == 12)  // 3 × 4 weeks
    }

    @Test("sessions are in ascending order")
    func ascendingOrder() {
        let userSkill = UserSkill(skillId: "handstand", level: .intermediate, weeklyFrequency: 2)
        let (_, sessions) = generator.generate(userSkill: userSkill, skill: skill, recentSessions: [])
        let dates = sessions.map { $0.scheduledDate }
        #expect(dates == dates.sorted())
    }

    @Test("beginner gets duration prescription")
    func beginnerPrescription() {
        let userSkill = UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)
        let (_, sessions) = generator.generate(userSkill: userSkill, skill: skill, recentSessions: [])
        if case .duration(let seconds) = sessions.first?.prescription.target {
            #expect(seconds == 15)
        } else {
            Issue.record("Expected duration prescription")
        }
    }

    @Test("load increases when last 3 sessions all completed")
    func loadAdaptationUp() {
        let userSkill = UserSkill(skillId: "handstand", level: .beginner, weeklyFrequency: 3)
        let recentSessions = (0..<3).map { i in
            PracticeSession(
                id: "s\(i)", skillId: "handstand",
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                durationMinutes: 1, notes: nil, completedAt: Date(),
                setsCompleted: 3  // = prescription.sets, 100% completion
            )
        }
        let (_, sessions) = generator.generate(userSkill: userSkill, skill: skill, recentSessions: recentSessions)
        if case .duration(let seconds) = sessions.first?.prescription.target {
            #expect(seconds > 15)  // should be ~17 (15 × 1.1)
        } else {
            Issue.record("Expected duration prescription")
        }
    }
}

// MARK: - ScheduleAdvisor

@Suite("ScheduleAdvisor")
struct ScheduleAdvisorTests {
    private let advisor = ScheduleAdvisor()
    private let today = Calendar.current.startOfDay(for: Date())

    private func makeUserSkill(skillId: String) -> UserSkill {
        UserSkill(skillId: skillId, level: .beginner, weeklyFrequency: 3)
    }

    private func makePlanned(id: String, programId: String, daysOffset: Int, completed: Bool = false) -> PlannedSession {
        PlannedSession(
            id: id,
            programId: programId,
            scheduledDate: Calendar.current.date(byAdding: .day, value: daysOffset, to: today)!,
            prescription: SessionPrescription(sets: 3, target: .duration(seconds: 15), notes: ""),
            completedSessionId: completed ? "done" : nil,
            isSkipped: false
        )
    }

    @Test("overdue sessions appear before due")
    func overdueBeforeDue() {
        let skill = makeUserSkill(skillId: "handstand")
        let data = [
            SkillScheduleData(userSkill: skill, plannedSessions: [
                makePlanned(id: "past", programId: "p1", daysOffset: -1),  // overdue
                makePlanned(id: "today", programId: "p1", daysOffset: 0),  // due
            ])
        ]
        let results = advisor.dueSessions(data: data, today: today)
        #expect(results.first?.plannedSession.id == "past")
        #expect(results.first?.urgency == .overdue)
    }

    @Test("completed sessions are not surfaced")
    func completedNotSurfaced() {
        let skill = makeUserSkill(skillId: "handstand")
        let data = [
            SkillScheduleData(userSkill: skill, plannedSessions: [
                makePlanned(id: "done", programId: "p1", daysOffset: 0, completed: true),
                makePlanned(id: "next", programId: "p1", daysOffset: 2),
            ])
        ]
        let results = advisor.dueSessions(data: data, today: today)
        #expect(results.first?.plannedSession.id == "next")
        #expect(results.first?.urgency == .upcoming)
    }

    @Test("inactive skills are excluded")
    func inactiveSkillsExcluded() {
        var skill = makeUserSkill(skillId: "handstand")
        skill.isActive = false
        let data = [
            SkillScheduleData(userSkill: skill, plannedSessions: [
                makePlanned(id: "s1", programId: "p1", daysOffset: 0)
            ])
        ]
        let results = advisor.dueSessions(data: data, today: today)
        #expect(results.isEmpty)
    }
}

// MARK: - PracticeSessionCompletionService

@Suite("PracticeSessionCompletionService")
struct PracticeSessionCompletionServiceTests {
    @Test("completing a planned session marks it complete and writes snapshot")
    func completesPlannedSessionAndWritesSnapshot() async throws {
        let db = try AppDatabase.inMemory()
        let skillRepo = LocalSkillRepository(db: db)
        let sessionRepo = LocalPracticeSessionRepository(db: db)
        let trainingRepo = LocalTrainingProgramRepository(db: db)
        let service = PracticeSessionCompletionService(
            sessionRepo: sessionRepo,
            skillRepo: skillRepo,
            trainingProgramRepo: trainingRepo
        )

        let program = TrainingProgram(
            id: "program-1",
            skillId: "handstand",
            level: .beginner,
            weeklyFrequency: 3,
            generatedAt: Date()
        )
        try await trainingRepo.saveProgram(program)
        try await trainingRepo.savePlannedSessions([
            PlannedSession(
                id: "planned-1",
                programId: "program-1",
                scheduledDate: Date(),
                prescription: SessionPrescription(sets: 3, target: .duration(seconds: 20), notes: "Hold quality"),
                completedSessionId: nil,
                isSkipped: false
            )
        ])

        let session = PracticeSession(
            id: "session-1",
            skillId: "handstand",
            date: Date(),
            durationMinutes: 2,
            notes: nil,
            completedAt: Date(),
            setsCompleted: 3,
            plannedSessionId: "planned-1",
            isPersonalRecord: false,
            sessionScore: 120
        )

        let completed = try await service.completeSession(session)
        let snapshot = try await skillRepo.getProgressSnapshot(skillId: "handstand")
        let planned = try await trainingRepo.getPlannedSessions(for: "program-1").first

        #expect(completed.isPersonalRecord == true)
        #expect(snapshot?.practiceCount == 1)
        #expect(planned?.completedSessionId == "session-1")
    }
}
