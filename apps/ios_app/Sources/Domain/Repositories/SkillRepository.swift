import Foundation

protocol SkillRepository: Sendable {
    func getSkills() async throws -> [Skill]
    func getSkillById(_ id: String) async throws -> Skill?
    func skillProgressStream(skillId: String) -> AsyncStream<ProgressSnapshot?>
}
