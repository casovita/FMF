import SwiftUI

@main
struct FMFApp: App {
    private let database = AppDatabase.shared
    private let skillRepo: any SkillRepository
    private let sessionRepo: any PracticeSessionRepository

    init() {
        skillRepo = LocalSkillRepository(db: database)
        sessionRepo = LocalPracticeSessionRepository(db: database)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.skillRepository, skillRepo)
                .environment(\.practiceSessionRepository, sessionRepo)
                .preferredColorScheme(.dark)
        }
    }
}
