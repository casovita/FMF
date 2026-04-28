import SwiftUI

struct AtmosphericBackground: View {
    var body: some View {
        FMFColors.background
            .ignoresSafeArea()
    }
}

private struct AtmosphericScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AtmosphericBackground()
            content
        }
    }
}

extension View {
    func atmosphericScreenBackground() -> some View {
        modifier(AtmosphericScreenBackgroundModifier())
    }
}
