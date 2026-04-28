import Foundation

protocol TrainingProgramRepository: Sendable {
    func getProgram(for skillId: String) async throws -> TrainingProgram?
    func saveProgram(_ program: TrainingProgram) async throws
    func getPlannedSessions(for programId: String) async throws -> [PlannedSession]
    func getAllPlannedSessions(for skillId: String) async throws -> [PlannedSession]
    func savePlannedSession(_ session: PlannedSession) async throws
    func savePlannedSessions(_ sessions: [PlannedSession]) async throws
    func markSessionComplete(id: String, completedSessionId: String) async throws
    func clearCompletedSession(id: String) async throws
    func skipSession(id: String) async throws
}
