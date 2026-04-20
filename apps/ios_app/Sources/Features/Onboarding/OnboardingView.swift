import SwiftUI

struct OnboardingView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false

    var body: some View {
        ZStack {
            Color(hex: 0x0D1628).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text(String(localized: "appTitle"))
                    .font(FMFTypography.displaySmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: FMFSpacing.md)

                Text("A skills academy for serious training.")
                    .font(FMFTypography.bodyLarge)
                    .foregroundStyle(FMFColors.neutral500)
                    .multilineTextAlignment(.center)

                Spacer()

                Button {
                    didCompleteOnboarding = true
                } label: {
                    Text("Begin Training")
                        .font(FMFTypography.labelLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FMFSpacing.md)
                        .background(FMFColors.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.md))
                }

                Spacer().frame(height: FMFSpacing.md)
            }
            .padding(.horizontal, FMFSpacing.lg)
        }
    }
}
