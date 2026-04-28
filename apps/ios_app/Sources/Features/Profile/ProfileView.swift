import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: FMFSpacing.sm) {
            Text(String(localized: "settingsTitle"))
                .font(FMFTypography.headlineSmall)
                .foregroundStyle(.white)
            Text(String(localized: "settings_placeholder"))
                .font(FMFTypography.bodyLarge)
                .foregroundStyle(FMFColors.neutral500)
                .multilineTextAlignment(.center)
        }
        .padding(FMFSpacing.lg)
        .atmosphericScreenBackground()
        .navigationTitle(String(localized: "settingsTitle"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
