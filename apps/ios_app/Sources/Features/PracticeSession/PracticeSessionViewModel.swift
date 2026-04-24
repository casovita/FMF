import Foundation
import Observation

@Observable
@MainActor
final class PracticeSessionViewModel {
    private(set) var isLoading = false
    private(set) var didSave = false
    private(set) var errorMessage: String?

    var selectedSkillId: String = "handstand"
    var durationMinutes: Int = 10
    var notes: String = ""
    var setsCompleted: Int = 1
    var performanceValue: Int = 0

    private let skills: [Skill]
    private let completionService: any PracticeSessionCompleting
    private let plannedSession: PlannedSession?

    init(
        skills: [Skill],
        completionService: any PracticeSessionCompleting,
        selectedSkillId: String? = nil,
        plannedSession: PlannedSession? = nil,
        initialDurationMinutes: Int? = nil
    ) {
        self.skills = skills
        self.completionService = completionService
        self.plannedSession = plannedSession
        self.selectedSkillId = selectedSkillId ?? skills.first?.id ?? ""
        if let initialDurationMinutes {
            durationMinutes = max(1, initialDurationMinutes)
        }

        if let plannedSession {
            setsCompleted = max(1, plannedSession.prescription.sets)
            performanceValue = plannedSession.prescription.target.value
        } else if let skill = skills.first(where: { $0.id == self.selectedSkillId }), skill.prescriptionType == .duration {
            performanceValue = durationMinutes * 60
        }
    }

    var availableSkills: [Skill] { skills }

    var selectedSkill: Skill? {
        skills.first(where: { $0.id == selectedSkillId })
    }

    var isSkillLocked: Bool {
        plannedSession != nil
    }

    var performanceLabel: String {
        guard let selectedSkill else { return String(localized: "practiceSessionResultLabel") }
        return selectedSkill.prescriptionType == .duration
            ? String(localized: "practiceSessionDurationResultLabel")
            : String(localized: "practiceSessionRepsResultLabel")
    }

    var performanceUnit: String {
        guard let selectedSkill else { return "" }
        return selectedSkill.prescriptionType == .duration
            ? String(localized: "practiceSessionSecondsUnit")
            : String(localized: "practiceSessionRepsUnit")
    }

    var plannedSummary: String? {
        plannedSession?.prescription.displayString
    }

    var canSubmit: Bool {
        durationMinutes > 0 && !selectedSkillId.isEmpty && performanceValue > 0 && setsCompleted > 0
    }

    func updateSelectedSkill(_ skillId: String) {
        selectedSkillId = skillId
        if selectedSkill?.prescriptionType == .duration {
            performanceValue = durationMinutes * 60
        } else if performanceValue == 0 {
            performanceValue = 1
        }
    }

    func submit() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        do {
            let session = PracticeSession(
                id: UUID().uuidString,
                skillId: selectedSkillId,
                date: Date(),
                durationMinutes: durationMinutes,
                notes: notes.isEmpty ? nil : notes,
                completedAt: Date(),
                setsCompleted: setsCompleted,
                plannedSessionId: plannedSession?.id,
                isPersonalRecord: false,
                sessionScore: performanceValue
            )
            _ = try await completionService.completeSession(session)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
