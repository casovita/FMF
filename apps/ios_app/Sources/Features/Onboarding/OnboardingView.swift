import SwiftUI

// MARK: - Root flow

struct OnboardingFlowView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.userSkillRepository) private var userSkillRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo

    @State private var vm: OnboardingViewModel?

    var body: some View {
        ZStack {
            AtmosphericBackground()
            if let vm {
                stepContent(vm: vm)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(vm.step)
            }
        }
        .task {
            let model = OnboardingViewModel(
                skillRepo: skillRepo,
                userSkillRepo: userSkillRepo,
                trainingProgramRepo: trainingProgramRepo
            )
            vm = model
            await model.loadSkills()
        }
    }

    @ViewBuilder
    private func stepContent(vm: OnboardingViewModel) -> some View {
        switch vm.step {
        case .welcome:
            WelcomeStepView(vm: vm)
        case .skillSelection:
            SkillSelectionStepView(vm: vm)
        case .levelSetup:
            LevelSetupStepView(vm: vm)
        case .frequencySetup:
            FrequencySetupStepView(vm: vm)
        case .summary:
            SummaryStepView(vm: vm, onComplete: {
                didCompleteOnboarding = true
            })
        }
    }
}

// MARK: - Progress indicator

private struct StepDots: View {
    let current: OnboardingViewModel.Step
    private let steps: [OnboardingViewModel.Step] = [.skillSelection, .levelSetup, .frequencySetup, .summary]

    var body: some View {
        HStack(spacing: FMFSpacing.sm) {
            ForEach(steps, id: \.rawValue) { step in
                Circle()
                    .fill(step == current ? FMFColors.brandAccent : FMFColors.neutral700)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Welcome step

private struct WelcomeStepView: View {
    let vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: FMFSpacing.md) {
                Text(String(localized: "appTitle"))
                    .font(FMFTypography.displaySmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(String(localized: "onboarding_welcome_subtitle"))
                    .font(FMFTypography.bodyLarge)
                    .foregroundStyle(FMFColors.neutral500)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            PrimaryButton(title: String(localized: "onboarding_begin_button")) {
                vm.advance()
            }
            .padding(.bottom, FMFSpacing.xl)
        }
        .padding(.horizontal, FMFSpacing.lg)
    }
}

// MARK: - Skill selection step

private struct SkillSelectionStepView: View {
    let vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            StepDots(current: .skillSelection)
                .padding(.top, FMFSpacing.xxl)

            Spacer().frame(height: FMFSpacing.xl)

            VStack(spacing: FMFSpacing.sm) {
                Text(String(localized: "onboarding_skill_selection_title"))
                    .font(FMFTypography.headlineSmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(String(localized: "onboarding_skill_selection_subtitle"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral500)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FMFSpacing.lg)

            Spacer().frame(height: FMFSpacing.xl)

            ScrollView {
                VStack(spacing: FMFSpacing.sm) {
                    ForEach(vm.allSkills) { skill in
                        SkillPickerRow(
                            skill: skill,
                            isSelected: vm.selectedSkillIds.contains(skill.id)
                        ) {
                            if vm.selectedSkillIds.contains(skill.id) {
                                vm.selectedSkillIds.remove(skill.id)
                            } else {
                                vm.selectedSkillIds.insert(skill.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, FMFSpacing.lg)
            }

            Spacer()

            PrimaryButton(
                title: String(localized: "onboarding_continue_button"),
                disabled: !vm.canAdvance
            ) {
                vm.advance()
            }
            .padding(.horizontal, FMFSpacing.lg)
            .padding(.bottom, FMFSpacing.xl)
        }
    }
}

private struct SkillPickerRow: View {
    let skill: Skill
    let isSelected: Bool
    let onTap: () -> Void

    var tint: Color {
        switch skill.category {
        case .balance: FMFColors.skillBalance
        case .strength: FMFColors.skillStrength
        case .bodyweight: FMFColors.skillBodyweight
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FMFSpacing.md) {
                Circle()
                    .fill(tint.opacity(0.2))
                    .overlay(Circle().stroke(tint.opacity(0.5), lineWidth: 1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: isSelected ? "checkmark" : "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSelected ? tint : FMFColors.neutral500)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .font(FMFTypography.titleMedium)
                        .foregroundStyle(.white)
                    Text(skill.description)
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(FMFSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FMFRadius.md)
                    .fill(isSelected ? tint.opacity(0.12) : FMFColors.darkSurface.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: FMFRadius.md)
                            .stroke(isSelected ? tint.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Level setup step

private struct LevelSetupStepView: View {
    let vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            StepDots(current: .levelSetup)
                .padding(.top, FMFSpacing.xxl)

            Spacer().frame(height: FMFSpacing.xl)

            VStack(spacing: FMFSpacing.sm) {
                Text(String(localized: "onboarding_level_title"))
                    .font(FMFTypography.headlineSmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(String(localized: "onboarding_level_subtitle"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral500)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FMFSpacing.lg)

            Spacer().frame(height: FMFSpacing.xl)

            ScrollView {
                VStack(spacing: FMFSpacing.lg) {
                    ForEach(vm.selectedSkills) { skill in
                        LevelPickerCard(
                            skill: skill,
                            selected: vm.skillLevels[skill.id] ?? .beginner,
                            onSelect: { level in vm.skillLevels[skill.id] = level }
                        )
                    }
                }
                .padding(.horizontal, FMFSpacing.lg)
            }

            Spacer()

            HStack(spacing: FMFSpacing.sm) {
                SecondaryButton(title: String(localized: "onboarding_back_button")) { vm.back() }
                PrimaryButton(
                    title: String(localized: "onboarding_continue_button"),
                    disabled: !vm.canAdvance
                ) { vm.advance() }
            }
            .padding(.horizontal, FMFSpacing.lg)
            .padding(.bottom, FMFSpacing.xl)
        }
    }
}

private struct LevelPickerCard: View {
    let skill: Skill
    let selected: SkillLevel
    let onSelect: (SkillLevel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            Text(skill.name)
                .font(FMFTypography.titleMedium)
                .foregroundStyle(.white)

            HStack(spacing: FMFSpacing.sm) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    LevelChip(level: level, isSelected: level == selected) {
                        onSelect(level)
                    }
                }
            }
        }
        .padding(FMFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FMFRadius.md)
                .fill(FMFColors.darkSurface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: FMFRadius.md)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct LevelChip: View {
    let level: SkillLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(level.displayName)
                .font(FMFTypography.labelMedium)
                .foregroundStyle(isSelected ? .white : FMFColors.neutral500)
                .padding(.horizontal, FMFSpacing.md)
                .padding(.vertical, FMFSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: FMFRadius.sm)
                        .fill(isSelected ? FMFColors.brandAccent : FMFColors.neutral700.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Frequency setup step

private struct FrequencySetupStepView: View {
    let vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            StepDots(current: .frequencySetup)
                .padding(.top, FMFSpacing.xxl)

            Spacer().frame(height: FMFSpacing.xl)

            VStack(spacing: FMFSpacing.sm) {
                Text(String(localized: "onboarding_frequency_title"))
                    .font(FMFTypography.headlineSmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(String(localized: "onboarding_frequency_subtitle"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral500)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FMFSpacing.lg)

            Spacer().frame(height: FMFSpacing.xl)

            ScrollView {
                VStack(spacing: FMFSpacing.lg) {
                    ForEach(vm.selectedSkills) { skill in
                        FrequencyPickerCard(
                            skill: skill,
                            frequency: Binding(
                                get: { vm.skillFrequencies[skill.id] ?? 3 },
                                set: { vm.skillFrequencies[skill.id] = $0 }
                            )
                        )
                    }
                }
                .padding(.horizontal, FMFSpacing.lg)
            }

            Spacer()

            HStack(spacing: FMFSpacing.sm) {
                SecondaryButton(title: String(localized: "onboarding_back_button")) { vm.back() }
                PrimaryButton(
                    title: String(localized: "onboarding_continue_button"),
                    disabled: !vm.canAdvance
                ) { vm.advance() }
            }
            .padding(.horizontal, FMFSpacing.lg)
            .padding(.bottom, FMFSpacing.xl)
        }
    }
}

private struct FrequencyPickerCard: View {
    let skill: Skill
    @Binding var frequency: Int

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            Text(skill.name)
                .font(FMFTypography.titleMedium)
                .foregroundStyle(.white)

            HStack(spacing: FMFSpacing.sm) {
                ForEach(2...5, id: \.self) { count in
                    FrequencyChip(count: count, isSelected: count == frequency) {
                        frequency = count
                    }
                }
                Spacer()
                Text(String(localized: "onboarding_per_week_label"))
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.neutral500)
            }
        }
        .padding(FMFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FMFRadius.md)
                .fill(FMFColors.darkSurface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: FMFRadius.md)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct FrequencyChip: View {
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(count)×")
                .font(FMFTypography.titleMedium)
                .foregroundStyle(isSelected ? .white : FMFColors.neutral500)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: FMFRadius.sm)
                        .fill(isSelected ? FMFColors.brandAccent : FMFColors.neutral700.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Summary step

private struct SummaryStepView: View {
    let vm: OnboardingViewModel
    let onComplete: () -> Void
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        VStack(spacing: 0) {
            StepDots(current: .summary)
                .padding(.top, FMFSpacing.xxl)

            Spacer()

            VStack(spacing: FMFSpacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(FMFColors.success)

                VStack(spacing: FMFSpacing.sm) {
                    Text(String(localized: "onboarding_summary_title"))
                        .font(FMFTypography.headlineSmall)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "onboarding_summary_subtitle"))
                        .font(FMFTypography.bodyMedium)
                        .foregroundStyle(FMFColors.neutral500)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: FMFSpacing.sm) {
                    ForEach(vm.selectedSkills) { skill in
                        SummarySkillRow(
                            skill: skill,
                            level: vm.skillLevels[skill.id] ?? .beginner,
                            frequency: vm.skillFrequencies[skill.id] ?? 3
                        )
                    }
                }
                .padding(.horizontal, FMFSpacing.lg)
            }

            Spacer()

            if let error = saveError {
                Text(error)
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FMFSpacing.lg)
                    .padding(.bottom, FMFSpacing.sm)
            }

            PrimaryButton(
                title: String(localized: "onboarding_start_training_button"),
                isLoading: isSaving,
                disabled: isSaving
            ) {
                isSaving = true
                Task {
                    do {
                        try await vm.complete()
                        onComplete()
                    } catch {
                        saveError = error.localizedDescription
                        isSaving = false
                    }
                }
            }
            .padding(.horizontal, FMFSpacing.lg)
            .padding(.bottom, FMFSpacing.xl)
        }
    }
}

private struct SummarySkillRow: View {
    let skill: Skill
    let level: SkillLevel
    let frequency: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(FMFTypography.titleMedium)
                    .foregroundStyle(.white)
                Text("\(level.displayName) · \(frequency)× \(String(localized: "onboarding_per_week_label"))")
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.neutral500)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FMFColors.neutral700)
        }
        .padding(FMFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FMFRadius.md)
                .fill(FMFColors.darkSurface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: FMFRadius.md)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Shared button components

private struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(FMFTypography.labelLarge)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FMFSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FMFRadius.md)
                    .fill(disabled ? FMFColors.neutral700 : FMFColors.brandAccent)
            )
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}

private struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FMFTypography.labelLarge)
                .foregroundStyle(FMFColors.neutral300)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FMFSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: FMFRadius.md)
                        .fill(FMFColors.darkSurface.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: FMFRadius.md)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
