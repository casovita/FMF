import Foundation

protocol PracticeSessionCompleting: Sendable {
    func completeSession(_ session: PracticeSession) async throws -> PracticeSession
}

struct PracticeSessionCompletionService: PracticeSessionCompleting {
    private let sessionRepo: any PracticeSessionRepository
    private let skillRepo: any SkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository
    private let tracker = PRTracker()

    init(
        sessionRepo: any PracticeSessionRepository,
        skillRepo: any SkillRepository,
        trainingProgramRepo: any TrainingProgramRepository
    ) {
        self.sessionRepo = sessionRepo
        self.skillRepo = skillRepo
        self.trainingProgramRepo = trainingProgramRepo
    }

    func completeSession(_ session: PracticeSession) async throws -> PracticeSession {
        guard let skill = try await skillRepo.getSkillById(session.skillId) else {
            throw SessionCompletionError.missingSkill
        }

        let previousSessions = try await sessionRepo.getSessionsForSkill(session.skillId)
        let currentPR = previousSessions
            .map(\.sessionScore)
            .max()
            .flatMap { score -> PRValue? in
                guard score > 0 else { return nil }
                return skill.prescriptionType == .duration ? .duration(seconds: score) : .reps(count: score)
            }

        var finalizedSession = session
        finalizedSession.sessionScore = resolvedScore(for: session, prescriptionType: skill.prescriptionType)
        finalizedSession.setsCompleted = max(0, finalizedSession.setsCompleted)

        let (_, isPersonalRecord) = tracker.evaluate(
            sessionScore: finalizedSession.sessionScore,
            prescriptionType: skill.prescriptionType,
            currentPR: currentPR
        )
        finalizedSession.isPersonalRecord = isPersonalRecord

        try await sessionRepo.logSession(finalizedSession)

        if let plannedSessionId = finalizedSession.plannedSessionId {
            try await trainingProgramRepo.markSessionComplete(id: plannedSessionId, completedSessionId: finalizedSession.id)
        }

        let updatedSessions = try await sessionRepo.getSessionsForSkill(session.skillId)
        let snapshot = ProgressSnapshot(
            id: session.skillId,
            skillId: session.skillId,
            trackId: nil,
            snapshotDate: Date(),
            practiceCount: updatedSessions.count,
            lastPracticeDate: updatedSessions.first?.date
        )
        try await skillRepo.saveProgressSnapshot(snapshot)

        return finalizedSession
    }

    private func resolvedScore(for session: PracticeSession, prescriptionType: PrescriptionType) -> Int {
        if session.sessionScore > 0 {
            return session.sessionScore
        }

        switch prescriptionType {
        case .duration:
            return max(0, session.durationMinutes * 60)
        case .reps:
            return max(0, session.setsCompleted)
        }
    }
}

enum SessionCompletionError: Error {
    case missingSkill
}
