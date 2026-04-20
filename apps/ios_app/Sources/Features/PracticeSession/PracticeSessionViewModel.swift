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

    private let repo: any PracticeSessionRepository
    private let skills: [Skill]

    init(repo: any PracticeSessionRepository, skills: [Skill]) {
        self.repo = repo
        self.skills = skills
        self.selectedSkillId = skills.first?.id ?? "handstand"
    }

    var availableSkills: [Skill] { skills }

    var canSubmit: Bool { durationMinutes > 0 && !selectedSkillId.isEmpty }

    func submit() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        let session = PracticeSession(
            id: UUID().uuidString,
            skillId: selectedSkillId,
            date: Date(),
            durationMinutes: durationMinutes,
            notes: notes.isEmpty ? nil : notes,
            completedAt: Date()
        )
        do {
            try await repo.logSession(session)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
