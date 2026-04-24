import Foundation

protocol SkillRepository: Sendable {
    func getSkills() async throws -> [Skill]
    func getSkillById(_ id: String) async throws -> Skill?
    func skillProgressStream(skillId: String) -> AsyncStream<ProgressSnapshot?>
    func getProgressSnapshot(skillId: String) async throws -> ProgressSnapshot?
    func saveProgressSnapshot(_ snapshot: ProgressSnapshot) async throws
}
