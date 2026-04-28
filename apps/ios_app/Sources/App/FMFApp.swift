import SwiftUI

@main
struct FMFApp: App {
    private let database = AppDatabase.shared
    private let skillRepo: any SkillRepository
    private let sessionRepo: any PracticeSessionRepository
    private let userSkillRepo: any UserSkillRepository
    private let trainingProgramRepo: any TrainingProgramRepository
    @MainActor private let workoutSoundPlayer: any WorkoutSoundPlaying

    init() {
        skillRepo = LocalSkillRepository(db: database)
        sessionRepo = LocalPracticeSessionRepository(db: database)
        userSkillRepo = LocalUserSkillRepository(db: database)
        trainingProgramRepo = LocalTrainingProgramRepository(db: database)
        workoutSoundPlayer = WorkoutSoundPlayer()
    }

    var body: some Scene {
        WindowGroup {
            appEntryView()
                .environment(\.skillRepository, skillRepo)
                .environment(\.practiceSessionRepository, sessionRepo)
                .environment(\.userSkillRepository, userSkillRepo)
                .environment(\.trainingProgramRepository, trainingProgramRepo)
                .environment(\.workoutSoundPlayer, workoutSoundPlayer)
                .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private func appEntryView() -> some View {
        if ProcessInfo.processInfo.arguments.contains("ui-test-workout-back") {
            WorkoutBackHarnessView()
        } else if ProcessInfo.processInfo.arguments.contains("ui-test-session-form") {
            SessionFormHarnessView()
        } else {
            RootView()
        }
    }
}
