import Foundation

struct DueSession: Sendable {
    let userSkill: UserSkill
    let plannedSession: PlannedSession
    let urgency: Urgency

    enum Urgency: Sendable {
        case overdue   // scheduled before today, not completed
        case due       // scheduled today
        case upcoming  // scheduled in the future
    }
}

struct SkillScheduleData: Sendable {
    let userSkill: UserSkill
    let plannedSessions: [PlannedSession]
}

struct ScheduleAdvisor: Sendable {
    private let calendar = Calendar.current

    /// Returns the next session per skill, ordered: overdue → due → upcoming.
    func dueSessions(data: [SkillScheduleData], today: Date = Date()) -> [DueSession] {
        let todayStart = calendar.startOfDay(for: today)

        var results: [DueSession] = []
        for entry in data where entry.userSkill.isActive {
            let next = entry.plannedSessions
                .filter { !$0.isCompleted && !$0.isSkipped }
                .sorted { $0.scheduledDate < $1.scheduledDate }
                .first

            guard let session = next else { continue }

            let sessionDay = calendar.startOfDay(for: session.scheduledDate)
            let urgency: DueSession.Urgency
            if sessionDay < todayStart {
                urgency = .overdue
            } else if sessionDay == todayStart {
                urgency = .due
            } else {
                urgency = .upcoming
            }
            results.append(DueSession(userSkill: entry.userSkill, plannedSession: session, urgency: urgency))
        }

        return results.sorted { lhs, rhs in
            urgencyRank(lhs.urgency) < urgencyRank(rhs.urgency)
        }
    }

    private func urgencyRank(_ urgency: DueSession.Urgency) -> Int {
        switch urgency {
        case .overdue: return 0
        case .due: return 1
        case .upcoming: return 2
        }
    }
}
