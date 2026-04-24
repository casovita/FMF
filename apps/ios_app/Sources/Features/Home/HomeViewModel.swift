import Foundation
import Observation

struct HomeDashboardItem: Identifiable, Sendable {
    let skill: Skill
    let userSkill: UserSkill
    let plannedSession: PlannedSession
    let stats: SkillStats
    let urgency: DueSession.Urgency

    var id: String { plannedSession.id }
}

@Observable
@MainActor
final class HomeViewModel {
    private(set) var dashboardItems: [HomeDashboardItem] = []
    private(set) var skillCatalog: [Skill] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let skillRepo: any SkillRepository
    private let userSkillRepo: any UserSkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository
    private let sessionRepo: any PracticeSessionRepository
    private let advisor = ScheduleAdvisor()
    private let statsAggregator = StatsAggregator()

    init(
        skillRepo: any SkillRepository,
        userSkillRepo: any UserSkillRepository,
        trainingProgramRepo: any TrainingProgramRepository,
        sessionRepo: any PracticeSessionRepository
    ) {
        self.skillRepo = skillRepo
        self.userSkillRepo = userSkillRepo
        self.trainingProgramRepo = trainingProgramRepo
        self.sessionRepo = sessionRepo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedSkills = skillRepo.getSkills()
            async let fetchedUserSkills = userSkillRepo.getUserSkills()
            let (skills, userSkills) = try await (fetchedSkills, fetchedUserSkills)
            skillCatalog = skills

            let data = try await loadScheduleData(for: userSkills)
            let dueSessions = advisor.dueSessions(data: data)
            var items: [HomeDashboardItem] = []
            for dueSession in dueSessions {
                guard let skill = skills.first(where: { $0.id == dueSession.userSkill.skillId }) else {
                    continue
                }

                let sessions = try await sessionRepo.getSessionsForSkill(skill.id)
                let plannedSessions = data.first(where: { $0.userSkill.skillId == skill.id })?.plannedSessions ?? []
                let stats = statsAggregator.compute(
                    sessions: sessions,
                    plannedSessions: plannedSessions,
                    skill: skill
                )

                items.append(HomeDashboardItem(
                    skill: skill,
                    userSkill: dueSession.userSkill,
                    plannedSession: dueSession.plannedSession,
                    stats: stats,
                    urgency: dueSession.urgency
                ))
            }
            dashboardItems = items
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadScheduleData(for userSkills: [UserSkill]) async throws -> [SkillScheduleData] {
        var results: [SkillScheduleData] = []
        for userSkill in userSkills where userSkill.isActive {
            guard let program = try await trainingProgramRepo.getProgram(for: userSkill.skillId) else { continue }
            let plannedSessions = try await trainingProgramRepo.getPlannedSessions(for: program.id)
            results.append(SkillScheduleData(userSkill: userSkill, plannedSessions: plannedSessions))
        }
        return results
    }
}
