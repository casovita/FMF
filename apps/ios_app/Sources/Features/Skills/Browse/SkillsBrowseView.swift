import SwiftUI

struct SkillsBrowseView: View {
    @Environment(\.skillRepository) private var repo
    @State private var vm: SkillsBrowseViewModel?
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
        .navigationTitle("All Skills")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedSkill) { skill in
            SkillDetailView(skillId: skill.id)
        }
        .task {
            let viewModel = SkillsBrowseViewModel(repo: repo)
            vm = viewModel
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func content(vm: SkillsBrowseViewModel) -> some View {
        if vm.isLoading {
            ProgressView()
                .tint(FMFColors.brandAccent)
        } else if let error = vm.errorMessage {
            Text("Error: \(error)")
                .font(FMFTypography.bodyMedium)
                .foregroundStyle(.white)
                .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: FMFSpacing.md) {
                    ForEach(vm.skills) { skill in
                        SkillCardView(skill: skill) {
                            selectedSkill = skill
                        }
                    }
                }
                .padding(.horizontal, FMFSpacing.md)
                .padding(.top, FMFSpacing.xs)
                .padding(.bottom, 100)
            }
        }
    }
}
