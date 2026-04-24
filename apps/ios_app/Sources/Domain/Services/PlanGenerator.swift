import Foundation

struct PlanGenerator: Sendable {

    // MARK: - Prescription templates

    private static let templates: [String: [SkillLevel: SessionPrescription]] = [
        "handstand": [
            .beginner:     SessionPrescription(sets: 3, target: .duration(seconds: 15), notes: String(localized: "plan_note_handstand_beginner")),
            .intermediate: SessionPrescription(sets: 3, target: .duration(seconds: 30), notes: String(localized: "plan_note_handstand_intermediate")),
            .advanced:     SessionPrescription(sets: 5, target: .duration(seconds: 30), notes: String(localized: "plan_note_handstand_advanced")),
        ],
        "pullups": [
            .beginner:     SessionPrescription(sets: 3, target: .reps(count: 3), notes: String(localized: "plan_note_pullups_beginner")),
            .intermediate: SessionPrescription(sets: 4, target: .reps(count: 5), notes: String(localized: "plan_note_pullups_intermediate")),
            .advanced:     SessionPrescription(sets: 5, target: .reps(count: 8), notes: String(localized: "plan_note_pullups_advanced")),
        ],
        "handstand_pushups": [
            .beginner:     SessionPrescription(sets: 3, target: .reps(count: 2), notes: String(localized: "plan_note_hspu_beginner")),
            .intermediate: SessionPrescription(sets: 4, target: .reps(count: 4), notes: String(localized: "plan_note_hspu_intermediate")),
            .advanced:     SessionPrescription(sets: 5, target: .reps(count: 6), notes: String(localized: "plan_note_hspu_advanced")),
        ],
    ]

    // MARK: - Generation

    /// Generates a training program and the next 4 weeks of planned sessions.
    func generate(
        userSkill: UserSkill,
        skill: Skill,
        recentSessions: [PracticeSession],
        startingFrom startDate: Date = Date()
    ) -> (program: TrainingProgram, sessions: [PlannedSession]) {
        let programId = UUID().uuidString
        let program = TrainingProgram(
            id: programId,
            skillId: userSkill.skillId,
            level: userSkill.level,
            weeklyFrequency: userSkill.weeklyFrequency,
            generatedAt: startDate
        )
        let basePrescription = Self.templates[userSkill.skillId]?[userSkill.level]
            ?? SessionPrescription(sets: 3, target: defaultTarget(for: skill), notes: "")

        let adapted = adapt(prescription: basePrescription, recentSessions: recentSessions)
        let intervalDays = 7.0 / Double(userSkill.weeklyFrequency)
        let sessionCount = userSkill.weeklyFrequency * 4  // 4 weeks

        var sessions: [PlannedSession] = []
        for i in 0 ..< sessionCount {
            let offset = intervalDays * Double(i)
            guard let date = Calendar.current.date(byAdding: .second, value: Int(offset * 86400), to: startDate) else { continue }
            sessions.append(PlannedSession(
                id: UUID().uuidString,
                programId: programId,
                scheduledDate: date,
                prescription: adapted,
                completedSessionId: nil,
                isSkipped: false
            ))
        }
        return (program, sessions)
    }

    // MARK: - Private

    private func defaultTarget(for skill: Skill) -> PrescriptionTarget {
        skill.prescriptionType == .duration ? .duration(seconds: 15) : .reps(count: 3)
    }

    private func adapt(prescription: SessionPrescription, recentSessions: [PracticeSession]) -> SessionPrescription {
        let last3 = Array(recentSessions.prefix(3))
        guard last3.count == 3 else { return prescription }

        let avgSetsCompleted = Double(last3.map { $0.setsCompleted }.reduce(0, +)) / 3.0
        let rate = prescription.sets > 0 ? avgSetsCompleted / Double(prescription.sets) : 1.0

        let factor: Double
        if rate >= 0.9 {
            factor = 1.1
        } else if rate < 0.6 {
            factor = 0.9
        } else {
            return prescription
        }

        return SessionPrescription(
            sets: prescription.sets,
            target: prescription.target.scaled(by: factor),
            notes: prescription.notes
        )
    }
}
