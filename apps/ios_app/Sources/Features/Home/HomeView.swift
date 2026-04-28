import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(String(localized: "appTitle"))
                    .font(FMFTypography.displaySmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, FMFSpacing.md)
                    .padding(.top, FMFSpacing.sm)

                Spacer(minLength: 0)
                    .frame(maxWidth: .infinity, minHeight: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 0, alignment: .top)
            .padding(.bottom, 100)
        }
        .atmosphericScreenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
