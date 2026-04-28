import Foundation

protocol PracticeSessionDeleting: Sendable {
    func deleteSession(_ session: PracticeSession) async throws
}

struct PracticeSessionDeletionService: PracticeSessionDeleting {
    private let sessionRepo: any PracticeSessionRepository
    private let skillRepo: any SkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository

    init(
        sessionRepo: any PracticeSessionRepository,
        skillRepo: any SkillRepository,
        trainingProgramRepo: any TrainingProgramRepository
    ) {
        self.sessionRepo = sessionRepo
        self.skillRepo = skillRepo
        self.trainingProgramRepo = trainingProgramRepo
    }

    func deleteSession(_ session: PracticeSession) async throws {
        try await sessionRepo.deleteSession(id: session.id)

        if let plannedSessionId = session.plannedSessionId {
            try await trainingProgramRepo.clearCompletedSession(id: plannedSessionId)
        }

        let remainingSessions = try await sessionRepo.getSessionsForSkill(session.skillId)
            .sorted { $0.date < $1.date }
        try await reassignPersonalRecords(in: remainingSessions)

        let snapshot = ProgressSnapshot(
            id: session.skillId,
            skillId: session.skillId,
            trackId: nil,
            snapshotDate: Date(),
            practiceCount: remainingSessions.count,
            lastPracticeDate: remainingSessions.max(by: { $0.date < $1.date })?.date
        )
        try await skillRepo.saveProgressSnapshot(snapshot)
    }

    private func reassignPersonalRecords(in sessions: [PracticeSession]) async throws {
        var runningBest = 0

        for session in sessions {
            var updatedSession = session
            let shouldBePR = session.sessionScore > 0 && session.sessionScore > runningBest
            if updatedSession.isPersonalRecord != shouldBePR {
                updatedSession.isPersonalRecord = shouldBePR
                try await sessionRepo.logSession(updatedSession)
            }
            runningBest = max(runningBest, session.sessionScore)
        }
    }
}
