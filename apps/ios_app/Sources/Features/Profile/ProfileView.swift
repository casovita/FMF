import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            FMFColors.brandPrimary.ignoresSafeArea()
            VStack(spacing: FMFSpacing.sm) {
                Text(String(localized: "profileTitle"))
                    .font(FMFTypography.headlineSmall)
                    .foregroundStyle(.white)
                Text(String(localized: "profile_placeholder"))
                    .font(FMFTypography.bodyLarge)
                    .foregroundStyle(FMFColors.neutral500)
                    .multilineTextAlignment(.center)
            }
            .padding(FMFSpacing.lg)
        }
        .navigationTitle(String(localized: "profileTitle"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
