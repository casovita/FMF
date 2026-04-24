import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case welcome, skillSelection, levelSetup, frequencySetup, summary
    }

    // MARK: - State

    private(set) var step: Step = .welcome
    private(set) var allSkills: [Skill] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var selectedSkillIds: Set<String> = []
    var skillLevels: [String: SkillLevel] = [:]
    var skillFrequencies: [String: Int] = [:]

    var selectedSkills: [Skill] {
        allSkills.filter { selectedSkillIds.contains($0.id) }
    }

    var canAdvance: Bool {
        switch step {
        case .welcome:
            return true
        case .skillSelection:
            return !selectedSkillIds.isEmpty
        case .levelSetup:
            return selectedSkills.allSatisfy { skillLevels[$0.id] != nil }
        case .frequencySetup:
            return selectedSkills.allSatisfy { skillFrequencies[$0.id] != nil }
        case .summary:
            return false
        }
    }

    // MARK: - Dependencies

    private let skillRepo: any SkillRepository
    private let userSkillRepo: any UserSkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository
    private let planGenerator = PlanGenerator()

    init(
        skillRepo: any SkillRepository,
        userSkillRepo: any UserSkillRepository,
        trainingProgramRepo: any TrainingProgramRepository
    ) {
        self.skillRepo = skillRepo
        self.userSkillRepo = userSkillRepo
        self.trainingProgramRepo = trainingProgramRepo
    }

    // MARK: - Navigation

    func advance() {
        guard canAdvance, let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            step = next
        }
    }

    func back() {
        guard step.rawValue > 0, let prev = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            step = prev
        }
    }

    // MARK: - Data

    func loadSkills() async {
        guard allSkills.isEmpty else { return }
        isLoading = true
        do {
            allSkills = try await skillRepo.getSkills()
            for skill in allSkills where skillLevels[skill.id] == nil {
                skillLevels[skill.id] = .beginner
                skillFrequencies[skill.id] = 3
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func complete() async throws {
        isLoading = true
        defer { isLoading = false }

        for skill in selectedSkills {
            let level = skillLevels[skill.id] ?? .beginner
            let frequency = skillFrequencies[skill.id] ?? 3

            let userSkill = UserSkill(skillId: skill.id, level: level, weeklyFrequency: frequency)
            try await userSkillRepo.saveUserSkill(userSkill)

            let (program, sessions) = planGenerator.generate(
                userSkill: userSkill,
                skill: skill,
                recentSessions: []
            )
            try await trainingProgramRepo.saveProgram(program)
            try await trainingProgramRepo.savePlannedSessions(sessions)
        }
    }
}
