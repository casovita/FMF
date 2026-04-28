import Foundation
import Observation

enum SkillsBrowseState: Sendable {
    case active
    case available
    case locked
    case future
}

enum SkillsBrowseStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case active
    case available
    case future

    var id: String { rawValue }
}

struct SkillRoadmapItem: Identifiable, Sendable {
    let skill: Skill
    let userSkill: UserSkill?
    let nextPlannedSession: PlannedSession?
    let state: SkillsBrowseState
    let academyPhase: Int
    let personalRecord: PRValue?
    let practiceCount: Int?

    var id: String { skill.id }
}

@Observable
@MainActor
final class SkillsBrowseViewModel {
    private(set) var roadmapItems: [SkillRoadmapItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var searchText = ""
    var selectedStatusFilter: SkillsBrowseStatusFilter = .all
    var selectedCategory: SkillCategory?

    private let skillRepo: any SkillRepository
    private let userSkillRepo: any UserSkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository
    private let sessionRepo: any PracticeSessionRepository
    private let statsAggregator = StatsAggregator()

    private static let categoryOrder: [SkillCategory] = [.balance, .strength, .bodyweight]
    private static let explicitSkillOrder: [String] = [
        "handstand",
        "pullups",
        "handstand_pushups"
    ]

    init(
        skillRepo: any SkillRepository,
        userSkillRepo: any UserSkillRepository,
        trainingProgramRepo: any TrainingProgramRepository,
        sessionRepo: any PracticeSessionRepository
    ) {
        self.skillRepo = skillRepo
        self.userSkillRepo = userSkillRepo
        self.trainingProgramRepo = trainingProgramRepo
        self.sessionRepo = sessionRepo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedSkills = skillRepo.getSkills()
            async let fetchedUserSkills = userSkillRepo.getUserSkills()
            let (catalog, userSkills) = try await (fetchedSkills, fetchedUserSkills)
            let activeUserSkills = userSkills.filter(\.isActive)
            let nextSessionsBySkillId = try await loadNextSessions(for: activeUserSkills)
            let activeMetricsBySkillId = try await loadActiveMetrics(
                catalog: catalog,
                userSkills: activeUserSkills
            )
            roadmapItems = buildRoadmapItems(
                catalog: catalog,
                userSkills: userSkills,
                nextSessionsBySkillId: nextSessionsBySkillId,
                activeMetricsBySkillId: activeMetricsBySkillId
            )
        } catch {
            errorMessage = error.localizedDescription
            roadmapItems = []
        }
        isLoading = false
    }

    var shouldShowDiscoveryControls: Bool {
        roadmapItems.count > 8
    }

    var visibleItems: [SkillRoadmapItem] {
        roadmapItems.filter(matchesFilters)
    }

    var continueTrainingItems: [SkillRoadmapItem] {
        visibleItems
            .filter { $0.state == .active }
            .sorted(by: compareActiveItems)
    }

    var unlockNextItems: [SkillRoadmapItem] {
        visibleItems
            .filter { $0.state == .available }
            .sorted(by: compareRoadmapItems)
    }

    var futureCurriculumItems: [SkillRoadmapItem] {
        visibleItems
            .filter { $0.state == .locked || $0.state == .future }
            .sorted(by: compareRoadmapItems)
    }

    var orderedVisibleItems: [SkillRoadmapItem] {
        let activeItems = visibleItems
            .filter { $0.state == .active }
            .sorted(by: compareActiveItems)
        let roadmapItems = visibleItems
            .filter { $0.state != .active }
            .sorted(by: compareRoadmapItems)

        return activeItems + roadmapItems
    }

    func isCategorySelected(_ category: SkillCategory?) -> Bool {
        selectedCategory == category
    }

    private func loadNextSessions(for userSkills: [UserSkill]) async throws -> [String: PlannedSession] {
        var nextSessionsBySkillId: [String: PlannedSession] = [:]

        for userSkill in userSkills {
            guard let program = try await trainingProgramRepo.getProgram(for: userSkill.skillId) else { continue }
            let sessions = try await trainingProgramRepo.getPlannedSessions(for: program.id)
            if let nextSession = nextPlannedSession(from: sessions) {
                nextSessionsBySkillId[userSkill.skillId] = nextSession
            }
        }

        return nextSessionsBySkillId
    }

    private func nextPlannedSession(from sessions: [PlannedSession]) -> PlannedSession? {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        return sessions
            .filter { !$0.isCompleted && !$0.isSkipped && $0.scheduledDate >= startOfDay }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
            ?? sessions
            .filter { !$0.isCompleted && !$0.isSkipped }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }

    private func buildRoadmapItems(
        catalog: [Skill],
        userSkills: [UserSkill],
        nextSessionsBySkillId: [String: PlannedSession],
        activeMetricsBySkillId: [String: ActiveSkillMetrics]
    ) -> [SkillRoadmapItem] {
        let userSkillsById = Dictionary(uniqueKeysWithValues: userSkills.map { ($0.skillId, $0) })
        let activeSkillIds = Set(userSkills.filter(\.isActive).map(\.skillId))
        let orderedCatalog = catalog.sorted(by: compareSkills)
        let firstInactiveIndex = orderedCatalog.firstIndex { !activeSkillIds.contains($0.id) }

        return orderedCatalog.enumerated().map { index, skill in
            let userSkill = userSkillsById[skill.id]
            let state = stateForSkill(
                skillId: skill.id,
                index: index,
                activeSkillIds: activeSkillIds,
                firstInactiveIndex: firstInactiveIndex
            )

            return SkillRoadmapItem(
                skill: skill,
                userSkill: userSkill,
                nextPlannedSession: nextSessionsBySkillId[skill.id],
                state: state,
                academyPhase: index + 1,
                personalRecord: activeMetricsBySkillId[skill.id]?.personalRecord,
                practiceCount: activeMetricsBySkillId[skill.id]?.practiceCount
            )
        }
    }

    private func loadActiveMetrics(
        catalog: [Skill],
        userSkills: [UserSkill]
    ) async throws -> [String: ActiveSkillMetrics] {
        let skillsById = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        var metricsBySkillId: [String: ActiveSkillMetrics] = [:]

        for userSkill in userSkills {
            guard let skill = skillsById[userSkill.skillId] else { continue }

            let sessions = try await sessionRepo.getSessionsForSkill(skill.id)
            let plannedSessions: [PlannedSession]
            if let program = try await trainingProgramRepo.getProgram(for: userSkill.skillId) {
                plannedSessions = try await trainingProgramRepo.getPlannedSessions(for: program.id)
            } else {
                plannedSessions = []
            }

            let stats = statsAggregator.compute(
                sessions: sessions,
                plannedSessions: plannedSessions,
                skill: skill
            )
            let progress = try await skillRepo.getProgressSnapshot(skillId: skill.id)

            metricsBySkillId[skill.id] = ActiveSkillMetrics(
                personalRecord: stats.personalRecord,
                practiceCount: progress?.practiceCount
            )
        }

        return metricsBySkillId
    }

    private func stateForSkill(
        skillId: String,
        index: Int,
        activeSkillIds: Set<String>,
        firstInactiveIndex: Int?
    ) -> SkillsBrowseState {
        if activeSkillIds.contains(skillId) {
            return .active
        }

        guard let firstInactiveIndex else {
            return .future
        }

        if index == firstInactiveIndex {
            return .available
        }

        if index == firstInactiveIndex + 1 {
            return .locked
        }

        return .future
    }

    private func matchesFilters(item: SkillRoadmapItem) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchesSearch: Bool
        if query.isEmpty {
            matchesSearch = true
        } else {
            let loweredQuery = query.localizedLowercase
            matchesSearch =
                item.skill.name.localizedLowercase.contains(loweredQuery)
                || item.skill.description.localizedLowercase.contains(loweredQuery)
        }

        let matchesStatus: Bool
        switch selectedStatusFilter {
        case .all:
            matchesStatus = true
        case .active:
            matchesStatus = item.state == .active
        case .available:
            matchesStatus = item.state == .available
        case .future:
            matchesStatus = item.state == .locked || item.state == .future
        }

        let matchesCategory = selectedCategory == nil || item.skill.category == selectedCategory

        return matchesSearch && matchesStatus && matchesCategory
    }

    private func compareActiveItems(lhs: SkillRoadmapItem, rhs: SkillRoadmapItem) -> Bool {
        switch (lhs.nextPlannedSession?.scheduledDate, rhs.nextPlannedSession?.scheduledDate) {
        case let (left?, right?) where left != right:
            return left < right
        case (nil, .some):
            return false
        case (.some, nil):
            return true
        default:
            return compareRoadmapItems(lhs: lhs, rhs: rhs)
        }
    }

    private func compareRoadmapItems(lhs: SkillRoadmapItem, rhs: SkillRoadmapItem) -> Bool {
        if lhs.academyPhase != rhs.academyPhase {
            return lhs.academyPhase < rhs.academyPhase
        }

        return lhs.skill.name.localizedCaseInsensitiveCompare(rhs.skill.name) == .orderedAscending
    }

    private func compareSkills(lhs: Skill, rhs: Skill) -> Bool {
        let leftExplicit = Self.explicitSkillOrder.firstIndex(of: lhs.id) ?? .max
        let rightExplicit = Self.explicitSkillOrder.firstIndex(of: rhs.id) ?? .max
        if leftExplicit != rightExplicit {
            return leftExplicit < rightExplicit
        }

        let leftCategory = Self.categoryOrder.firstIndex(of: lhs.category) ?? .max
        let rightCategory = Self.categoryOrder.firstIndex(of: rhs.category) ?? .max
        if leftCategory != rightCategory {
            return leftCategory < rightCategory
        }

        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}

private struct ActiveSkillMetrics: Sendable {
    let personalRecord: PRValue?
    let practiceCount: Int?
}
