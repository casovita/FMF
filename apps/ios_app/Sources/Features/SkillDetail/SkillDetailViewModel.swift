import Foundation
import Observation

@Observable
@MainActor
final class SkillDetailViewModel {
    private(set) var skill: Skill?
    private(set) var userSkill: UserSkill?
    private(set) var currentProgram: TrainingProgram?
    private(set) var plannedSessions: [PlannedSession] = []
    private(set) var stats: SkillStats?
    private(set) var progress: ProgressSnapshot?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isSaving = false

    private let skillId: String
    private let skillRepo: any SkillRepository
    private let userSkillRepo: any UserSkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository
    private let sessionRepo: any PracticeSessionRepository
    private let planGenerator = PlanGenerator()
    private let statsAggregator = StatsAggregator()

    var selectedLevel: SkillLevel = .beginner
    var weeklyFrequency: Int = 3
    var isActive = true

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
        userSkillRepo: any UserSkillRepository,
        trainingProgramRepo: any TrainingProgramRepository,
        sessionRepo: any PracticeSessionRepository
    ) {
        self.skillId = skillId
        self.skillRepo = skillRepo
        self.userSkillRepo = userSkillRepo
        self.trainingProgramRepo = trainingProgramRepo
        self.sessionRepo = sessionRepo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedSkill = skillRepo.getSkillById(skillId)
            async let fetchedUserSkill = userSkillRepo.getUserSkill(id: skillId)
            async let fetchedProgress = skillRepo.getProgressSnapshot(skillId: skillId)
            let (skill, userSkill, progress) = try await (fetchedSkill, fetchedUserSkill, fetchedProgress)
            self.skill = skill
            self.userSkill = userSkill
            self.progress = progress

            if let userSkill {
                selectedLevel = userSkill.level
                weeklyFrequency = userSkill.weeklyFrequency
                isActive = userSkill.isActive
            }

            currentProgram = try await trainingProgramRepo.getProgram(for: skillId)
            if let program = currentProgram {
                plannedSessions = try await trainingProgramRepo.getPlannedSessions(for: program.id)
            } else {
                plannedSessions = []
            }

            if let skill {
                let sessions = try await sessionRepo.getSessionsForSkill(skillId)
                stats = statsAggregator.compute(
                    sessions: sessions,
                    plannedSessions: plannedSessions,
                    skill: skill
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func watchProgress() async {
        for await snapshot in skillRepo.skillProgressStream(skillId: skillId) {
            progress = snapshot
        }
    }

    func saveSettings() async {
        guard let skill else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            var updatedUserSkill = userSkill ?? UserSkill(
                skillId: skill.id,
                level: selectedLevel,
                weeklyFrequency: weeklyFrequency
            )
            updatedUserSkill.level = selectedLevel
            updatedUserSkill.weeklyFrequency = weeklyFrequency
            updatedUserSkill.isActive = isActive
            try await userSkillRepo.saveUserSkill(updatedUserSkill)
            userSkill = updatedUserSkill
            var latestPlannedSessions: [PlannedSession] = []

            if isActive {
                let sessions = try await sessionRepo.getSessionsForSkill(skill.id)
                let recentSessions = Array(sessions.prefix(3))
                let (program, generatedSessions) = planGenerator.generate(
                    userSkill: updatedUserSkill,
                    skill: skill,
                    recentSessions: recentSessions
                )
                try await trainingProgramRepo.saveProgram(program)
                try await trainingProgramRepo.savePlannedSessions(generatedSessions)
                currentProgram = program
                latestPlannedSessions = generatedSessions
                self.plannedSessions = generatedSessions
            } else {
                currentProgram = nil
                self.plannedSessions = []
            }

            stats = statsAggregator.compute(
                sessions: try await sessionRepo.getSessionsForSkill(skill.id),
                plannedSessions: latestPlannedSessions,
                skill: skill
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
