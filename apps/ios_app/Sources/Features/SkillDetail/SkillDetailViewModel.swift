import Foundation
import Observation

struct PersonalRecordPoint: Identifiable, Hashable, Sendable {
    let id: String
    let date: Date
    let score: Int
}

enum SkillMetricKind: Sendable {
    case time
    case reps
    case weight(unit: String)

    static func from(skill: Skill) -> SkillMetricKind {
        switch skill.prescriptionType {
        case .duration:
            return .time
        case .reps:
            return .reps
        }
    }

    func headlineValue(for score: Int?) -> String {
        guard let score, score > 0 else { return String(localized: "skillDetailPRPlaceholder") }

        switch self {
        case .time:
            return PRValue.duration(seconds: score).displayString
        case .reps:
            return "\(score)"
        case .weight(let unit):
            return "\(score) \(unit)"
        }
    }

    var headlineUnit: String? {
        switch self {
        case .time:
            return nil
        case .reps:
            return String(localized: "practiceSessionRepsUnit")
        case .weight(let unit):
            return unit
        }
    }
}

struct PersonalRecordChartState: Sendable {
    let metricKind: SkillMetricKind
    let currentScore: Int?
    let points: [PersonalRecordPoint]

    var headlineValue: String {
        metricKind.headlineValue(for: currentScore)
    }

    var headlineUnit: String? {
        metricKind.headlineUnit
    }

    var trendText: String {
        guard points.count > 1, let first = points.first?.score, let last = points.last?.score else {
            return String(localized: "skillDetailTrendWaiting")
        }

        if last > first {
            return String(localized: "skillDetailTrendIncreasing")
        }

        return String(localized: "skillDetailTrendNoChange")
    }

    var isEmpty: Bool {
        points.isEmpty
    }

    static func empty(metricKind: SkillMetricKind) -> PersonalRecordChartState {
        PersonalRecordChartState(metricKind: metricKind, currentScore: nil, points: [])
    }
}

@Observable
@MainActor
final class SkillDetailViewModel {
    private(set) var skill: Skill?
    private(set) var plannedSessions: [PlannedSession] = []
    private(set) var sessions: [PracticeSession] = []
    private(set) var chartState = PersonalRecordChartState.empty(metricKind: .time)
    private(set) var isLoading = false
    private(set) var isDeletingSession = false
    private(set) var errorMessage: String?

    private let skillId: String
    private let skillRepo: any SkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository
    private let sessionRepo: any PracticeSessionRepository
    private let deletionService: any PracticeSessionDeleting

    var nextPlannedSession: PlannedSession? {
        let now = Date()
        return plannedSessions
            .filter { !$0.isCompleted && !$0.isSkipped && $0.scheduledDate >= Calendar.current.startOfDay(for: now) }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
            ?? plannedSessions
            .filter { !$0.isCompleted && !$0.isSkipped }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }

    init(
        skillId: String,
        skillRepo: any SkillRepository,
        trainingProgramRepo: any TrainingProgramRepository,
        sessionRepo: any PracticeSessionRepository,
        deletionService: (any PracticeSessionDeleting)? = nil
    ) {
        self.skillId = skillId
        self.skillRepo = skillRepo
        self.trainingProgramRepo = trainingProgramRepo
        self.sessionRepo = sessionRepo
        self.deletionService = deletionService ?? PracticeSessionDeletionService(
            sessionRepo: sessionRepo,
            skillRepo: skillRepo,
            trainingProgramRepo: trainingProgramRepo
        )
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedSkill = skillRepo.getSkillById(skillId)
            let skill = try await fetchedSkill
            self.skill = skill
            chartState = PersonalRecordChartState.empty(metricKind: skill.map(SkillMetricKind.from) ?? .time)

            let currentProgram = try await trainingProgramRepo.getProgram(for: skillId)
            if let program = currentProgram {
                plannedSessions = try await trainingProgramRepo.getPlannedSessions(for: program.id)
            } else {
                plannedSessions = []
            }

            if let skill {
                let sessions = try await sessionRepo.getSessionsForSkill(skillId)
                self.sessions = sessions.sorted { $0.date > $1.date }
                chartState = buildChartState(skill: skill, sessions: sessions)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func watchProgress() async {
        for await _ in skillRepo.skillProgressStream(skillId: skillId) {
            guard let skill else { continue }
            if let sessions = try? await sessionRepo.getSessionsForSkill(skillId) {
                self.sessions = sessions.sorted { $0.date > $1.date }
                chartState = buildChartState(skill: skill, sessions: sessions)
            }
        }
    }

    func deleteSession(_ session: PracticeSession) async {
        guard !isDeletingSession else { return }
        isDeletingSession = true
        errorMessage = nil
        defer { isDeletingSession = false }

        do {
            try await deletionService.deleteSession(session)
            if let skill {
                let updatedSessions = try await sessionRepo.getSessionsForSkill(skillId)
                sessions = updatedSessions.sorted { $0.date > $1.date }
                chartState = buildChartState(skill: skill, sessions: updatedSessions)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildChartState(skill: Skill, sessions: [PracticeSession]) -> PersonalRecordChartState {
        let metricKind = SkillMetricKind.from(skill: skill)
        let orderedSessions = sessions.sorted { $0.date < $1.date }
        var runningBest = 0
        let points = orderedSessions.map { session -> PersonalRecordPoint in
            runningBest = max(runningBest, session.sessionScore)
            return PersonalRecordPoint(
                id: session.id,
                date: session.date,
                score: runningBest
            )
        }
        let currentScore = points.last?.score

        return PersonalRecordChartState(
            metricKind: metricKind,
            currentScore: currentScore,
            points: points
        )
    }
}
