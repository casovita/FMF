import Foundation

protocol PracticeSessionRepository: Sendable {
    func logSession(_ session: PracticeSession) async throws
    func deleteSession(id: String) async throws
    func getSessionsForSkill(_ skillId: String) async throws -> [PracticeSession]
    func getRecentSessions(limit: Int) async throws -> [PracticeSession]
}
