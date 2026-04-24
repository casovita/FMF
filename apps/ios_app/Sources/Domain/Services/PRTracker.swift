import Foundation

struct PRTracker: Sendable {
    /// Returns the new PR and whether it beats the previous one.
    func evaluate(sessionScore: Int, prescriptionType: PrescriptionType, currentPR: PRValue?) -> (pr: PRValue, isPersonalRecord: Bool) {
        let newPR: PRValue = prescriptionType == .duration
            ? .duration(seconds: sessionScore)
            : .reps(count: sessionScore)

        guard let current = currentPR else {
            return (newPR, sessionScore > 0)
        }
        let isNew = newPR > current
        return (isNew ? newPR : current, isNew)
    }
}
