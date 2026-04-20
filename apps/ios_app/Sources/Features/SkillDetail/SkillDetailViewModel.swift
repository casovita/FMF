import Foundation
import Observation

@Observable
@MainActor
final class SkillDetailViewModel {
    private(set) var skill: Skill?
    private(set) var progress: ProgressSnapshot?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let skillId: String
    private let repo: any SkillRepository

    init(skillId: String, repo: any SkillRepository) {
        self.skillId = skillId
        self.repo = repo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            skill = try await repo.getSkillById(skillId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func watchProgress() async {
        for await snapshot in repo.skillProgressStream(skillId: skillId) {
            progress = snapshot
        }
    }
}
