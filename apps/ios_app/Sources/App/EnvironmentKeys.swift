import SwiftUI

// MARK: - SkillRepository

private struct SkillRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: any SkillRepository = LocalSkillRepository(db: AppDatabase.shared)
}

extension EnvironmentValues {
    var skillRepository: any SkillRepository {
        get { self[SkillRepositoryKey.self] }
        set { self[SkillRepositoryKey.self] = newValue }
    }
}

// MARK: - PracticeSessionRepository

private struct PracticeSessionRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: any PracticeSessionRepository = LocalPracticeSessionRepository(db: AppDatabase.shared)
}

extension EnvironmentValues {
    var practiceSessionRepository: any PracticeSessionRepository {
        get { self[PracticeSessionRepositoryKey.self] }
        set { self[PracticeSessionRepositoryKey.self] = newValue }
    }
}
