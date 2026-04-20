import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    private(set) var skills: [Skill] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let repo: any SkillRepository

    init(repo: any SkillRepository) {
        self.repo = repo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            skills = try await repo.getSkills()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
