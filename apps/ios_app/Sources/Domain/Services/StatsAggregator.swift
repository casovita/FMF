import Foundation

struct StatsAggregator: Sendable {
    private let calendar = Calendar.current
    private let tracker = PRTracker()

    func compute(
        sessions: [PracticeSession],
        plannedSessions: [PlannedSession],
        skill: Skill,
        today: Date = Date()
    ) -> SkillStats {
        guard !sessions.isEmpty else {
            return .empty(skillId: skill.id)
        }

        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        let currentStreak = computeCurrentStreak(sessions: sessions, today: today)
        let longestStreak = computeLongestStreak(sessions: sessions)
        let pr = computePR(sessions: sessions, prescriptionType: skill.prescriptionType)
        let completionRate = computeWeeklyCompletionRate(
            sessions: sessions,
            plannedSessions: plannedSessions,
            today: today
        )

        return SkillStats(
            skillId: skill.id,
            totalSessions: sessions.count,
            totalMinutes: totalMinutes,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            personalRecord: pr,
            weeklyCompletionRate: completionRate,
            computedAt: today
        )
    }

    // MARK: - Private

    private func computePR(sessions: [PracticeSession], prescriptionType: PrescriptionType) -> PRValue? {
        let best = sessions.map { $0.sessionScore }.max() ?? 0
        guard best > 0 else { return nil }
        return prescriptionType == .duration ? .duration(seconds: best) : .reps(count: best)
    }

    private func computeCurrentStreak(sessions: [PracticeSession], today: Date) -> Int {
        let days = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = calendar.startOfDay(for: today)
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private func computeLongestStreak(sessions: [PracticeSession]) -> Int {
        let days = sessions
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1 ..< days.count {
            let diff = calendar.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return longest
    }

    private func computeWeeklyCompletionRate(
        sessions: [PracticeSession],
        plannedSessions: [PlannedSession],
        today: Date
    ) -> Double {
        guard let cutoff = calendar.date(byAdding: .day, value: -28, to: today) else { return 0 }
        let recentPlanned = plannedSessions.filter { $0.scheduledDate >= cutoff && $0.scheduledDate <= today }
        guard !recentPlanned.isEmpty else { return 0 }
        let completed = recentPlanned.filter { $0.isCompleted }.count
        return Double(completed) / Double(recentPlanned.count)
    }
}
