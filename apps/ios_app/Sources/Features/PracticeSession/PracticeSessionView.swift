import SwiftUI

struct PracticeSessionView: View {
    let skillId: String?
    let plannedSession: PlannedSession?
    let initialDurationMinutes: Int?

    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.practiceSessionRepository) private var sessionRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.dismiss) private var dismiss
    @State private var vm: PracticeSessionViewModel?
    @State private var skills: [Skill] = []

    init(skillId: String? = nil, plannedSession: PlannedSession? = nil, initialDurationMinutes: Int? = nil) {
        self.skillId = skillId
        self.plannedSession = plannedSession
        self.initialDurationMinutes = initialDurationMinutes
    }

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
            let completionService = PracticeSessionCompletionService(
                sessionRepo: sessionRepo,
                skillRepo: skillRepo,
                trainingProgramRepo: trainingProgramRepo
            )
            vm = PracticeSessionViewModel(
                skills: loaded,
                completionService: completionService,
                selectedSkillId: skillId,
                plannedSession: plannedSession,
                initialDurationMinutes: initialDurationMinutes
            )
        }
    }

    @ViewBuilder
    private func form(vm: PracticeSessionViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FMFSpacing.lg) {
                if let summary = vm.plannedSummary {
                    VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                        Text(String(localized: "practiceSessionPlannedTitle"))
                            .font(FMFTypography.labelLarge)
                            .foregroundStyle(FMFColors.neutral300)
                        Text(summary)
                            .font(FMFTypography.titleMedium)
                            .foregroundStyle(.white)
                    }
                    .padding(FMFSpacing.md)
                    .background(FMFColors.darkSurface)
                    .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
                }

                // Skill picker
                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    Label(String(localized: "practiceSessionSkillLabel"), systemImage: "figure.strengthtraining.traditional")
                        .font(FMFTypography.labelLarge)
                        .foregroundStyle(FMFColors.neutral300)

                    Picker(String(localized: "practiceSessionSkillLabel"), selection: Binding(
                        get: { vm.selectedSkillId },
                        set: { vm.updateSelectedSkill($0) }
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
                .opacity(vm.isSkillLocked ? 0.6 : 1.0)
                .disabled(vm.isSkillLocked)

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

                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    Label(vm.performanceLabel, systemImage: "chart.bar.xaxis")
                        .font(FMFTypography.labelLarge)
                        .foregroundStyle(FMFColors.neutral300)

                    HStack {
                        Text("\(vm.performanceValue) \(vm.performanceUnit)")
                            .font(FMFTypography.titleLarge)
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Spacer()
                        Stepper(
                            "",
                            value: Binding(
                                get: { vm.performanceValue },
                                set: { vm.performanceValue = $0 }
                            ),
                            in: 1...600
                        )
                        .labelsHidden()
                    }
                }
                .padding(FMFSpacing.md)
                .background(FMFColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))

                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    Label(String(localized: "practiceSessionSetsLabel"), systemImage: "number")
                        .font(FMFTypography.labelLarge)
                        .foregroundStyle(FMFColors.neutral300)

                    HStack {
                        Text("\(vm.setsCompleted)")
                            .font(FMFTypography.titleLarge)
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Spacer()
                        Stepper(
                            "",
                            value: Binding(
                                get: { vm.setsCompleted },
                                set: { vm.setsCompleted = $0 }
                            ),
                            in: 1...20
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
