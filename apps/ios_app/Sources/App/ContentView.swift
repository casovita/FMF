import SwiftUI

struct RootView: View {
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            AppShellView()

            if showsSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard showsSplash else { return }
            try? await Task.sleep(for: .milliseconds(1400))
            withAnimation(.easeOut(duration: 0.25)) {
                showsSplash = false
            }
        }
    }
}

private struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color("brandPrimary")
                .ignoresSafeArea()

            Image("SplashPoster")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}
