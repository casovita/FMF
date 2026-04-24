import Foundation
import Observation

struct ProgressSkillSummary: Identifiable, Sendable {
    let skill: Skill
    let stats: SkillStats
    let progress: ProgressSnapshot?
    let nextPlannedSession: PlannedSession?
    let completedPlannedSessions: Int
    let totalPlannedSessions: Int

    var id: String { skill.id }
}

@Observable
@MainActor
final class ProgressViewModel {
    private(set) var summaries: [ProgressSkillSummary] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let sessionRepo: any PracticeSessionRepository
    private let skillRepo: any SkillRepository
    private let userSkillRepo: any UserSkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository
    private let statsAggregator = StatsAggregator()

    init(
        sessionRepo: any PracticeSessionRepository,
        skillRepo: any SkillRepository,
        userSkillRepo: any UserSkillRepository,
        trainingProgramRepo: any TrainingProgramRepository
    ) {
        self.sessionRepo = sessionRepo
        self.skillRepo = skillRepo
        self.userSkillRepo = userSkillRepo
        self.trainingProgramRepo = trainingProgramRepo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedSkills = skillRepo.getSkills()
            async let fetchedUserSkills = userSkillRepo.getUserSkills()
            let (skills, userSkills) = try await (fetchedSkills, fetchedUserSkills)

            var builtSummaries: [ProgressSkillSummary] = []
            for userSkill in userSkills where userSkill.isActive {
                guard let skill = skills.first(where: { $0.id == userSkill.skillId }) else { continue }
                let sessions = try await sessionRepo.getSessionsForSkill(skill.id)
                let program = try await trainingProgramRepo.getProgram(for: skill.id)
                let plannedSessions: [PlannedSession]
                if let program {
                    plannedSessions = try await trainingProgramRepo.getPlannedSessions(for: program.id)
                } else {
                    plannedSessions = []
                }
                let stats = statsAggregator.compute(
                    sessions: sessions,
                    plannedSessions: plannedSessions,
                    skill: skill
                )
                let progress = try await skillRepo.getProgressSnapshot(skillId: skill.id)
                let nextPlannedSession = plannedSessions
                    .filter { !$0.isCompleted && !$0.isSkipped }
                    .sorted { $0.scheduledDate < $1.scheduledDate }
                    .first
                let completedPlannedSessions = plannedSessions.filter(\.isCompleted).count
                let totalPlannedSessions = plannedSessions.count
                builtSummaries.append(
                    ProgressSkillSummary(
                        skill: skill,
                        stats: stats,
                        progress: progress,
                        nextPlannedSession: nextPlannedSession,
                        completedPlannedSessions: completedPlannedSessions,
                        totalPlannedSessions: totalPlannedSessions
                    )
                )
            }
            summaries = builtSummaries.sorted(by: sortSummaries)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func sortSummaries(_ lhs: ProgressSkillSummary, _ rhs: ProgressSkillSummary) -> Bool {
        switch (lhs.nextPlannedSession?.scheduledDate, rhs.nextPlannedSession?.scheduledDate) {
        case let (left?, right?):
            if left != right { return left < right }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }

        if lhs.stats.currentStreak != rhs.stats.currentStreak {
            return lhs.stats.currentStreak > rhs.stats.currentStreak
        }

        return lhs.skill.name.localizedCaseInsensitiveCompare(rhs.skill.name) == .orderedAscending
    }
}
