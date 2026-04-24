import Foundation
import Observation

@Observable
@MainActor
final class SkillsBrowseViewModel {
    private(set) var skills: [Skill] = []
    private(set) var activeSkillIds: Set<String> = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let skillRepo: any SkillRepository
    private let userSkillRepo: any UserSkillRepository

    init(skillRepo: any SkillRepository, userSkillRepo: any UserSkillRepository) {
        self.skillRepo = skillRepo
        self.userSkillRepo = userSkillRepo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedSkills = skillRepo.getSkills()
            async let fetchedUserSkills = userSkillRepo.getUserSkills()
            let (catalog, userSkills) = try await (fetchedSkills, fetchedUserSkills)
            skills = catalog
            activeSkillIds = Set(userSkills.filter(\.isActive).map(\.skillId))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func isEnrolled(skillId: String) -> Bool {
        activeSkillIds.contains(skillId)
    }
}
