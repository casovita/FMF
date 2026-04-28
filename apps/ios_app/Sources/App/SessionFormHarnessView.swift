import SwiftUI

struct SessionFormHarnessView: View {
    @State private var vm = SessionFormHarnessView.makeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                PracticeSessionFormView(vm: vm)
                    .padding(FMFSpacing.md)
            }
            .background(FMFColors.background.ignoresSafeArea())
            .navigationTitle("Session Form Harness")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private static func makeViewModel() -> PracticeSessionViewModel {
        PracticeSessionViewModel(
            skills: [
                Skill(
                    id: "handstand",
                    name: "Handstand",
                    description: "Balance on your hands",
                    category: .balance
                )
            ],
            completionService: HarnessCompletionService(),
            selectedSkillId: "handstand"
        )
    }
}

private final class HarnessCompletionService: PracticeSessionCompleting, @unchecked Sendable {
    func completeSession(_ session: PracticeSession) async throws -> PracticeSession {
        session
    }
}
