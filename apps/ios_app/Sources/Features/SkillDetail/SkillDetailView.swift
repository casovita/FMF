import SwiftUI

struct SkillDetailView: View {
    let skillId: String
    @Environment(\.skillRepository) private var repo
    @State private var vm: SkillDetailViewModel?
    @State private var showWorkout = false
    @State private var showPracticeSession = false

    var body: some View {
        ZStack {
            FMFColors.brandPrimary.ignoresSafeArea()

            Group {
                if let vm {
                    if vm.isLoading {
                        ProgressView().tint(FMFColors.brandAccent)
                    } else if let error = vm.errorMessage {
                        Text("Error: \(error)")
                            .foregroundStyle(.white)
                            .padding()
                    } else if let skill = vm.skill {
                        skillContent(skill: skill)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let viewModel = SkillDetailViewModel(skillId: skillId, repo: repo)
            vm = viewModel
            async let load: Void = viewModel.load()
            async let watch: Void = viewModel.watchProgress()
            _ = await (load, watch)
        }
        .fullScreenCover(isPresented: $showWorkout) {
            WorkoutView(skillId: skillId)
        }
        .navigationDestination(isPresented: $showPracticeSession) {
            PracticeSessionView()
        }
    }

    private func categoryColor(for category: SkillCategory) -> Color {
        switch category {
        case .balance:    return FMFColors.skillBalance
        case .strength:   return FMFColors.skillStrength
        case .bodyweight: return FMFColors.skillBodyweight
        }
    }

    @ViewBuilder
    private func skillContent(skill: Skill) -> some View {
        let catColor = categoryColor(for: skill.category)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Category chip
                CategoryChip(category: skill.category, color: catColor)
                    .padding(.bottom, FMFSpacing.sm)

                // Name
                Text(skill.name)
                    .font(FMFTypography.headlineMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.bottom, FMFSpacing.sm)

                // Description
                Text(skill.description)
                    .font(FMFTypography.bodyLarge)
                    .foregroundStyle(FMFColors.neutral300)
                    .padding(.bottom, FMFSpacing.xl)

                // Progression tracks placeholder
                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    Text("Progression Tracks")
                        .font(FMFTypography.titleMedium)
                        .foregroundStyle(.white)
                    Text("Coming in the next iteration.")
                        .font(FMFTypography.bodyMedium)
                        .foregroundStyle(FMFColors.neutral500)
                }
                .padding(FMFSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FMFColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
                .overlay {
                    RoundedRectangle(cornerRadius: FMFRadius.lg)
                        .strokeBorder(catColor.opacity(0.3), lineWidth: 1)
                }
                .padding(.bottom, FMFSpacing.xl)

                // Start Workout button
                Button {
                    showWorkout = true
                } label: {
                    Text("Start Workout")
                        .font(FMFTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FMFSpacing.md)
                        .background(FMFColors.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.xl))
                }
                .padding(.bottom, FMFSpacing.md)

                // Log Session button
                Button {
                    showPracticeSession = true
                } label: {
                    Text(String(localized: "practiceSessionLogSessionTitle"))
                        .font(FMFTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(FMFColors.brandAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FMFSpacing.md)
                        .background(FMFColors.darkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.xl))
                        .overlay {
                            RoundedRectangle(cornerRadius: FMFRadius.xl)
                                .strokeBorder(FMFColors.brandAccent.opacity(0.5), lineWidth: 1)
                        }
                }
                .padding(.bottom, 100)
            }
            .padding(FMFSpacing.md)
        }
    }
}

private struct CategoryChip: View {
    let category: SkillCategory
    let color: Color

    var body: some View {
        Text(category.rawValue.uppercased())
            .font(FMFTypography.labelSmall)
            .tracking(1.2)
            .foregroundStyle(color)
            .padding(.horizontal, FMFSpacing.sm)
            .padding(.vertical, FMFSpacing.xs)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay {
                Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1)
            }
    }
}
