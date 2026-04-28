import Foundation

struct PracticeSessionDraft: Hashable, Codable, Sendable {
    private static let guidedTimerBetweenSetsGetReadySeconds = 5

    let skillId: String
    let prescriptionType: PrescriptionType
    let setsCompleted: Int
    let targetValuePerSet: Int
    let restSeconds: Int
    let durationSetValues: [Int]
    let notes: String?
    let plannedSessionId: String?

    var resolvedTargetValuePerSet: Int {
        if prescriptionType == .duration {
            return durationSetValues.max() ?? targetValuePerSet
        }
        return targetValuePerSet
    }

    var manualSessionScore: Int {
        switch prescriptionType {
        case .duration:
            return durationSetValues.max() ?? 0
        case .reps:
            return targetValuePerSet * setsCompleted
        }
    }

    var estimatedDurationMinutes: Int {
        let totalRestSeconds = max(0, setsCompleted - 1) * restSeconds
        let totalBetweenSetsGetReadySeconds = prescriptionType == .duration
            ? max(0, setsCompleted - 1) * Self.guidedTimerBetweenSetsGetReadySeconds
            : 0
        let estimatedWorkSeconds: Int

        switch prescriptionType {
        case .duration:
            estimatedWorkSeconds = durationSetValues.reduce(0, +)
        case .reps:
            estimatedWorkSeconds = setsCompleted * max(15, targetValuePerSet * 3)
        }

        return max(1, Int(ceil(Double(estimatedWorkSeconds + totalRestSeconds + totalBetweenSetsGetReadySeconds) / 60.0)))
    }

    func withCompletedDurationSets(_ completedDurations: [Int]) -> PracticeSessionDraft {
        PracticeSessionDraft(
            skillId: skillId,
            prescriptionType: prescriptionType,
            setsCompleted: completedDurations.isEmpty ? setsCompleted : completedDurations.count,
            targetValuePerSet: completedDurations.max() ?? targetValuePerSet,
            restSeconds: restSeconds,
            durationSetValues: completedDurations.isEmpty ? durationSetValues : completedDurations,
            notes: notes,
            plannedSessionId: plannedSessionId
        )
    }

    func makeManualLoggedSession(
        id: String = UUID().uuidString,
        date: Date = Date(),
        completedAt: Date = Date()
    ) -> PracticeSession {
        PracticeSession(
            id: id,
            skillId: skillId,
            date: date,
            durationMinutes: estimatedDurationMinutes,
            notes: normalizedNotes,
            completedAt: completedAt,
            setsCompleted: setsCompleted,
            targetValuePerSet: resolvedTargetValuePerSet,
            restSeconds: restSeconds,
            durationSetValues: durationSetValues,
            plannedSessionId: plannedSessionId,
            isPersonalRecord: false,
            sessionScore: manualSessionScore
        )
    }

    func makeExecutedSession(
        mode: WorkoutMode,
        elapsedSeconds: Int,
        repCount: Int,
        id: String = UUID().uuidString,
        date: Date = Date(),
        completedAt: Date = Date()
    ) -> PracticeSession {
        let measuredScore = prescriptionType == .duration ? elapsedSeconds : repCount
        let measuredDurationMinutes = max(1, Int(ceil(Double(max(elapsedSeconds, 1)) / 60.0)))
        let measuredDurationSetValues: [Int]
        let measuredSetsCompleted: Int
        let measuredTargetValuePerSet: Int

        switch prescriptionType {
        case .duration:
            measuredDurationSetValues = elapsedSeconds > 0 ? [elapsedSeconds] : []
            measuredSetsCompleted = measuredDurationSetValues.isEmpty ? 0 : measuredDurationSetValues.count
            measuredTargetValuePerSet = elapsedSeconds
        case .reps:
            measuredDurationSetValues = durationSetValues
            measuredSetsCompleted = setsCompleted
            measuredTargetValuePerSet = resolvedTargetValuePerSet
        }

        return PracticeSession(
            id: id,
            skillId: skillId,
            date: date,
            durationMinutes: measuredDurationMinutes,
            notes: mergedNotes(with: executionSummary(mode: mode, elapsedSeconds: elapsedSeconds, repCount: repCount)),
            completedAt: completedAt,
            setsCompleted: measuredSetsCompleted,
            targetValuePerSet: measuredTargetValuePerSet,
            restSeconds: restSeconds,
            durationSetValues: measuredDurationSetValues,
            plannedSessionId: plannedSessionId,
            isPersonalRecord: false,
            sessionScore: measuredScore
        )
    }

    func makeTimerExecutedSession(
        completedDurations: [Int],
        totalSessionSeconds: Int,
        id: String = UUID().uuidString,
        date: Date = Date(),
        completedAt: Date = Date()
    ) -> PracticeSession {
        // If user stopped mid-first-set, record actual elapsed time as one partial set
        let effectiveDurations: [Int]
        if completedDurations.isEmpty, totalSessionSeconds > 0 {
            effectiveDurations = [totalSessionSeconds]
        } else {
            effectiveDurations = completedDurations
        }
        let completedDraft = withCompletedDurationSets(effectiveDurations)
        let bestSet = effectiveDurations.max() ?? 0

        return PracticeSession(
            id: id,
            skillId: skillId,
            date: date,
            durationMinutes: max(1, Int(ceil(Double(max(totalSessionSeconds, 1)) / 60.0))),
            notes: completedDraft.mergedNotes(with: completedDraft.executionSummary(mode: .timer, elapsedSeconds: bestSet, repCount: 0)),
            completedAt: completedAt,
            setsCompleted: completedDraft.setsCompleted,
            targetValuePerSet: completedDraft.resolvedTargetValuePerSet,
            restSeconds: restSeconds,
            durationSetValues: effectiveDurations,
            plannedSessionId: plannedSessionId,
            isPersonalRecord: false,
            sessionScore: bestSet
        )
    }

    private var normalizedNotes: String? {
        let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func mergedNotes(with summary: String) -> String? {
        guard let normalizedNotes else { return summary }
        return "\(normalizedNotes) • \(summary)"
    }

    private func executionSummary(mode: WorkoutMode, elapsedSeconds: Int, repCount: Int) -> String {
        switch prescriptionType {
        case .duration:
            return "\(mode.summaryLabel): \(elapsedSeconds) sec"
        case .reps:
            return "\(mode.summaryLabel): \(repCount) reps in \(elapsedSeconds) sec"
        }
    }
}
