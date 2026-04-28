import SwiftUI

struct AppShellView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            FMFColors.background
                .ignoresSafeArea()

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
                    ProgressScreenView()
                }
                .tag(AppTab.progress)

                NavigationStack {
                    SettingsView()
                }
                .tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            FloatingDockView(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .ignoresSafeArea(edges: .bottom)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .bottom)
    }
}
