import Foundation

protocol UserSkillRepository: Sendable {
    func getUserSkills() async throws -> [UserSkill]
    func getUserSkill(id: String) async throws -> UserSkill?
    func saveUserSkill(_ skill: UserSkill) async throws
    func deleteUserSkill(id: String) async throws
    func userSkillStream() -> AsyncStream<[UserSkill]>
}
