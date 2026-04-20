import Foundation
import Observation

@Observable
@MainActor
final class ProgressViewModel {
    private(set) var sessions: [PracticeSession] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let repo: any PracticeSessionRepository

    init(repo: any PracticeSessionRepository) {
        self.repo = repo
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            sessions = try await repo.getRecentSessions(limit: 10)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
