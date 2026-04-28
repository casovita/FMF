import Foundation
import Observation

@Observable
@MainActor
final class PracticeSessionViewModel {
    struct NoteSuggestion: Identifiable, Hashable, Sendable {
        let emoji: String
        let text: String

        var id: String { "\(emoji)-\(text)" }
        var displayText: String { "\(emoji) \(text)" }
    }

    private(set) var isLoading = false
    private(set) var didSave = false
    private(set) var errorMessage: String?

    let selectedSkillId: String
    var notes: String = ""
    var setsCompleted: Int = 3
    var targetValuePerSet: Int = 15
    var restSeconds: Int = 60
    var durationSetValues: [Int] = []

    private let skills: [Skill]
    private let completionService: any PracticeSessionCompleting
    private let plannedSession: PlannedSession?

    init(
        skills: [Skill],
        completionService: any PracticeSessionCompleting,
        selectedSkillId: String,
        plannedSession: PlannedSession? = nil
    ) {
        self.skills = skills
        self.completionService = completionService
        self.plannedSession = plannedSession
        self.selectedSkillId = selectedSkillId

        if let plannedSession {
            setsCompleted = max(1, plannedSession.prescription.sets)
            targetValuePerSet = max(1, plannedSession.prescription.target.value)
            restSeconds = defaultRestSeconds(for: selectedSkill)
        } else {
            targetValuePerSet = defaultTargetValue(for: selectedSkill)
            restSeconds = defaultRestSeconds(for: selectedSkill)
        }

        syncDurationSetValues()
    }

    var selectedSkill: Skill? {
        skills.first(where: { $0.id == selectedSkillId })
    }

    var navigationTitle: String {
        let format = String(localized: "practiceSessionTitleFormat")
        let skillName = selectedSkill?.name.lowercased() ?? String(localized: "practiceSessionGenericSkillName")
        return String(format: format, skillName)
    }

    var targetLabel: String {
        isDurationSkill
            ? String(localized: "practiceSessionSecondsPerSetLabel")
            : String(localized: "practiceSessionRepsPerSetLabel")
    }

    var targetValueText: String {
        isDurationSkill
            ? String(format: String(localized: "practiceSessionSecondsValueFormat"), targetValuePerSet)
            : String(format: String(localized: "practiceSessionRepsValueFormat"), targetValuePerSet)
    }

    var restValueText: String {
        String(format: String(localized: "practiceSessionSecondsValueFormat"), restSeconds)
    }

    var bestSetValueText: String {
        if isDurationSkill {
            return String(format: String(localized: "practiceSessionSecondsValueFormat"), durationSetValues.max() ?? 0)
        }
        return String(format: String(localized: "practiceSessionRepsValueFormat"), targetValuePerSet)
    }

    var cumulativeValueText: String {
        if isDurationSkill {
            return String(format: String(localized: "practiceSessionSecondsValueFormat"), durationSetValues.reduce(0, +))
        }
        return String(format: String(localized: "practiceSessionRepsValueFormat"), targetValuePerSet * setsCompleted)
    }

    var canSubmit: Bool {
        !selectedSkillId.isEmpty && setsCompleted > 0 && hasValidTargetValues && restSeconds >= 0
    }

    var usesPerSetDurationInputs: Bool {
        isDurationSkill
    }

    var sessionDraft: PracticeSessionDraft {
        PracticeSessionDraft(
            skillId: selectedSkillId,
            prescriptionType: selectedSkill?.prescriptionType ?? .duration,
            setsCompleted: setsCompleted,
            targetValuePerSet: targetValuePerSet,
            restSeconds: restSeconds,
            durationSetValues: durationSetValues,
            notes: notes,
            plannedSessionId: plannedSession?.id
        )
    }

    var supportsTimerExecution: Bool { true }

    var supportsSoundExecution: Bool {
        isDurationSkill
    }

    var perSetDurationTitle: String {
        String(localized: "practiceSessionSetTimesLabel")
    }

    func durationLabel(forSetAt index: Int) -> String {
        let format = String(localized: "practiceSessionSetNumberFormat")
        return String(format: format, index + 1)
    }

    func durationValue(at index: Int) -> Int {
        guard durationSetValues.indices.contains(index) else { return targetValuePerSet }
        return durationSetValues[index]
    }

    func updateDurationValue(at index: Int, value: Int) {
        guard durationSetValues.indices.contains(index) else { return }
        durationSetValues[index] = max(5, value)
    }

    func updateSetsCompleted(_ value: Int) {
        setsCompleted = max(1, value)
        syncDurationSetValues()
    }

    var noteSuggestions: [NoteSuggestion] {
        if isDurationSkill {
            return [
                NoteSuggestion(emoji: "🤸", text: String(localized: "practiceSessionMoodStable")),
                NoteSuggestion(emoji: "🔥", text: String(localized: "practiceSessionMoodStrong")),
                NoteSuggestion(emoji: "😵", text: String(localized: "practiceSessionMoodWobbly")),
                NoteSuggestion(emoji: "😮‍💨", text: String(localized: "practiceSessionMoodFatigued"))
            ]
        }

        return [
            NoteSuggestion(emoji: "💪", text: String(localized: "practiceSessionMoodStrong")),
            NoteSuggestion(emoji: "⚡", text: String(localized: "practiceSessionMoodExplosive")),
            NoteSuggestion(emoji: "🥵", text: String(localized: "practiceSessionMoodBurning")),
            NoteSuggestion(emoji: "😮‍💨", text: String(localized: "practiceSessionMoodFatigued"))
        ]
    }

    func applySuggestion(_ suggestion: NoteSuggestion) {
        let fragment = suggestion.displayText
        if notes.isEmpty {
            notes = fragment
            return
        }

        if !notes.contains(fragment) {
            notes += " • \(fragment)"
        }
    }

    func submit() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        do {
            let session = sessionDraft.makeManualLoggedSession()
            _ = try await completionService.completeSession(session)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var isDurationSkill: Bool {
        selectedSkill?.prescriptionType != .reps
    }

    private func defaultTargetValue(for skill: Skill?) -> Int {
        guard let skill else { return 15 }
        return skill.prescriptionType == .duration ? 15 : 5
    }

    private func defaultRestSeconds(for skill: Skill?) -> Int {
        guard let skill else { return 60 }
        return skill.prescriptionType == .duration ? 45 : 30
    }

    private var hasValidTargetValues: Bool {
        if isDurationSkill {
            return durationSetValues.count == setsCompleted && durationSetValues.allSatisfy { $0 > 0 }
        }
        return targetValuePerSet > 0
    }

    private func syncDurationSetValues() {
        guard isDurationSkill else {
            durationSetValues = []
            return
        }

        let fallback = max(5, targetValuePerSet)
        if durationSetValues.count < setsCompleted {
            durationSetValues += Array(repeating: fallback, count: setsCompleted - durationSetValues.count)
        } else if durationSetValues.count > setsCompleted {
            durationSetValues = Array(durationSetValues.prefix(setsCompleted))
        }

        durationSetValues = durationSetValues.map { max(5, $0) }
    }
}
