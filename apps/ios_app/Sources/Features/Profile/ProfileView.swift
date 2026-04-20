import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            FMFColors.brandPrimary.ignoresSafeArea()
            Text("Profile coming soon.")
                .font(FMFTypography.bodyLarge)
                .foregroundStyle(FMFColors.neutral500)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
