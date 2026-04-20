import SwiftUI

struct PracticeSessionView: View {
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.practiceSessionRepository) private var sessionRepo
    @Environment(\.dismiss) private var dismiss
    @State private var vm: PracticeSessionViewModel?
    @State private var skills: [Skill] = []

    var body: some View {
        ZStack {
            FMFColors.brandPrimary.ignoresSafeArea()

            if let vm {
                form(vm: vm)
                    .onChange(of: vm.didSave) { _, saved in
                        if saved { dismiss() }
                    }
            } else {
                ProgressView().tint(FMFColors.brandAccent)
            }
        }
        .navigationTitle(String(localized: "practiceSessionTitle"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let loaded = (try? await skillRepo.getSkills()) ?? []
            skills = loaded
            vm = PracticeSessionViewModel(repo: sessionRepo, skills: loaded)
        }
    }

    @ViewBuilder
    private func form(vm: PracticeSessionViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FMFSpacing.lg) {

                // Skill picker
                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    Label(String(localized: "practiceSessionSkillLabel"), systemImage: "figure.strengthtraining.traditional")
                        .font(FMFTypography.labelLarge)
                        .foregroundStyle(FMFColors.neutral300)

                    Picker(String(localized: "practiceSessionSkillLabel"), selection: Binding(
                        get: { vm.selectedSkillId },
                        set: { vm.selectedSkillId = $0 }
                    )) {
                        ForEach(vm.availableSkills) { skill in
                            Text(skill.name).tag(skill.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(FMFColors.brandAccent)
                }
                .padding(FMFSpacing.md)
                .background(FMFColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))

                // Duration stepper
                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    Label(String(localized: "practiceSessionDurationLabel"), systemImage: "timer")
                        .font(FMFTypography.labelLarge)
                        .foregroundStyle(FMFColors.neutral300)

                    HStack {
                        Text("\(vm.durationMinutes) min")
                            .font(FMFTypography.titleLarge)
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Spacer()
                        Stepper(
                            "",
                            value: Binding(
                                get: { vm.durationMinutes },
                                set: { vm.durationMinutes = $0 }
                            ),
                            in: 1...240
                        )
                        .labelsHidden()
                    }
                }
                .padding(FMFSpacing.md)
                .background(FMFColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))

                // Notes field
                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    Label(String(localized: "practiceSessionNotesLabel"), systemImage: "note.text")
                        .font(FMFTypography.labelLarge)
                        .foregroundStyle(FMFColors.neutral300)

                    TextField(
                        String(localized: "practiceSessionNotesPlaceholder"),
                        text: Binding(
                            get: { vm.notes },
                            set: { vm.notes = $0 }
                        ),
                        axis: .vertical
                    )
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(.white)
                    .lineLimit(3...6)
                    .tint(FMFColors.brandAccent)
                }
                .padding(FMFSpacing.md)
                .background(FMFColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))

                // Error
                if let error = vm.errorMessage {
                    Text(error)
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.error)
                        .padding(.horizontal, FMFSpacing.xs)
                }

                // Submit button
                Button {
                    Task { await vm.submit() }
                } label: {
                    Group {
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(String(localized: "practiceSessionSubmitButton"))
                                .font(FMFTypography.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FMFSpacing.md)
                    .background(vm.canSubmit ? FMFColors.brandAccent : FMFColors.neutral700)
                    .clipShape(RoundedRectangle(cornerRadius: FMFRadius.xl))
                }
                .disabled(!vm.canSubmit || vm.isLoading)
            }
            .padding(FMFSpacing.md)
            .padding(.bottom, FMFSpacing.xxl)
        }
    }
}
