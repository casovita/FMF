import SwiftUI

struct HomeView: View {
    @Environment(\.skillRepository) private var repo
    @State private var vm: HomeViewModel?
    @State private var selectedSkill: Skill?

    var body: some View {
        ZStack {
            AtmosphericBackground()

            Group {
                if let vm {
                    content(vm: vm)
                }
            }
        }
        .navigationTitle(String(localized: "homeWelcomeTitle"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedSkill) { skill in
            SkillDetailView(skillId: skill.id)
        }
        .task {
            let viewModel = HomeViewModel(repo: repo)
            vm = viewModel
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func content(vm: HomeViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: FMFSpacing.sm) {
                    Text(String(localized: "homeWelcomeTitle"))
                        .font(FMFTypography.headlineLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(String(localized: "homeWelcomeSubtitle"))
                        .font(FMFTypography.bodyLarge)
                        .foregroundStyle(Color(hex: 0x7B8DB8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, FMFSpacing.md)
                .padding(.top, FMFSpacing.xxl)
                .padding(.bottom, FMFSpacing.lg)

                if vm.isLoading {
                    ProgressView()
                        .tint(FMFColors.brandAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, FMFSpacing.xxl)
                } else if let error = vm.errorMessage {
                    Text("Error: \(error)")
                        .font(FMFTypography.bodyMedium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, FMFSpacing.md)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: FMFSpacing.md
                    ) {
                        ForEach(vm.skills) { skill in
                            SkillCardView(skill: skill) {
                                selectedSkill = skill
                            }
                        }
                    }
                    .padding(.horizontal, FMFSpacing.md)
                }
            }
            .padding(.bottom, 100)
        }
    }
}
