import SwiftUI

struct AppShellView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tag(AppTab.home)

                NavigationStack {
                    SkillsBrowseView()
                }
                .tag(AppTab.skills)

                NavigationStack {
                    ProgressView()
                }
                .tag(AppTab.progress)

                NavigationStack {
                    ProfileView()
                }
                .tag(AppTab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            FloatingDockView(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
