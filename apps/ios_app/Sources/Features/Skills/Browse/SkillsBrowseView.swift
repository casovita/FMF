import SwiftUI

struct SkillsBrowseView: View {
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.userSkillRepository) private var userSkillRepo
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
        .navigationTitle(String(localized: "browseTitle"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedSkill) { skill in
            SkillDetailView(skillId: skill.id)
        }
        .task {
            let viewModel = SkillsBrowseViewModel(skillRepo: skillRepo, userSkillRepo: userSkillRepo)
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
            VStack(spacing: FMFSpacing.xs) {
                Text(String(localized: "errorGeneric"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(.white)
                Text(verbatim: error)
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.neutral500)
            }
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: FMFSpacing.md) {
                    ForEach(vm.skills) { skill in
                        BrowseSkillRow(
                            skill: skill,
                            isEnrolled: vm.isEnrolled(skillId: skill.id),
                            onTap: { selectedSkill = skill }
                        )
                    }
                }
                .padding(.horizontal, FMFSpacing.md)
                .padding(.top, FMFSpacing.xs)
                .padding(.bottom, 100)
            }
        }
    }
}

private struct BrowseSkillRow: View {
    let skill: Skill
    let isEnrolled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FMFSpacing.md) {
                SkillCardView(skill: skill, onTap: {})
                    .allowsHitTesting(false)
                    .frame(width: 132)

                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    Text(skill.name)
                        .font(FMFTypography.titleMedium)
                        .foregroundStyle(.white)
                    Text(skill.description)
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                        .multilineTextAlignment(.leading)

                    Text(isEnrolled ? String(localized: "browse_enrolled") : String(localized: "browse_not_enrolled"))
                        .font(FMFTypography.labelSmall)
                        .foregroundStyle(isEnrolled ? FMFColors.success : FMFColors.warning)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
