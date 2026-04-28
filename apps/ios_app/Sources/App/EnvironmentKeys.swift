import SwiftUI

// MARK: - SkillRepository

private struct SkillRepositoryKey: EnvironmentKey {
    static let defaultValue: any SkillRepository = LocalSkillRepository(db: AppDatabase.shared)
}

extension EnvironmentValues {
    var skillRepository: any SkillRepository {
        get { self[SkillRepositoryKey.self] }
        set { self[SkillRepositoryKey.self] = newValue }
    }
}

// MARK: - PracticeSessionRepository

private struct PracticeSessionRepositoryKey: EnvironmentKey {
    static let defaultValue: any PracticeSessionRepository = LocalPracticeSessionRepository(db: AppDatabase.shared)
}

extension EnvironmentValues {
    var practiceSessionRepository: any PracticeSessionRepository {
        get { self[PracticeSessionRepositoryKey.self] }
        set { self[PracticeSessionRepositoryKey.self] = newValue }
    }
}

// MARK: - UserSkillRepository

private struct UserSkillRepositoryKey: EnvironmentKey {
    static let defaultValue: any UserSkillRepository = LocalUserSkillRepository(db: AppDatabase.shared)
}

extension EnvironmentValues {
    var userSkillRepository: any UserSkillRepository {
        get { self[UserSkillRepositoryKey.self] }
        set { self[UserSkillRepositoryKey.self] = newValue }
    }
}

// MARK: - TrainingProgramRepository

private struct TrainingProgramRepositoryKey: EnvironmentKey {
    static let defaultValue: any TrainingProgramRepository = LocalTrainingProgramRepository(db: AppDatabase.shared)
}

extension EnvironmentValues {
    var trainingProgramRepository: any TrainingProgramRepository {
        get { self[TrainingProgramRepositoryKey.self] }
        set { self[TrainingProgramRepositoryKey.self] = newValue }
    }
}

// MARK: - WorkoutSoundPlaying

private struct WorkoutSoundPlayerKey: EnvironmentKey {
    static let defaultValue: any WorkoutSoundPlaying = NoOpWorkoutSoundPlayer()
}

extension EnvironmentValues {
    var workoutSoundPlayer: any WorkoutSoundPlaying {
        get { self[WorkoutSoundPlayerKey.self] }
        set { self[WorkoutSoundPlayerKey.self] = newValue }
    }
}
