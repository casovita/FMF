import SwiftUI

struct RootView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false

    var body: some View {
        if didCompleteOnboarding {
            AppShellView()
        } else {
            OnboardingView()
        }
    }
}
