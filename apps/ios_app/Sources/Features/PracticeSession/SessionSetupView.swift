import SwiftUI

struct SessionSetupView: View {
    private struct ExecutionSelection: Identifiable {
        let id = UUID()
        let mode: WorkoutMode
        let draft: PracticeSessionDraft
    }

    let skillId: String
    let plannedSession: PlannedSession?

    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.practiceSessionRepository) private var sessionRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.dismiss) private var dismiss
    @State private var vm: PracticeSessionViewModel?
    @State private var activeExecution: ExecutionSelection?

    init(skillId: String, plannedSession: PlannedSession? = nil) {
        self.skillId = skillId
        self.plannedSession = plannedSession
    }

    var body: some View {
        Group {
            if let vm {
                ScrollView {
                    VStack(alignment: .leading, spacing: FMFSpacing.lg) {
                        PracticeSessionFormView(vm: vm)

                        if let error = vm.errorMessage {
                            Text(error)
                                .font(FMFTypography.bodySmall)
                                .foregroundStyle(FMFColors.error)
                                .padding(.horizontal, FMFSpacing.xs)
                        }

                        executionSection(vm: vm)
                    }
                    .padding(FMFSpacing.md)
                    .padding(.bottom, FMFSpacing.xxl)
                }
            } else {
                ProgressView().tint(FMFColors.brandPrimary)
            }
        }
        .atmosphericScreenBackground()
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let loaded = (try? await skillRepo.getSkills()) ?? []
            let completionService = PracticeSessionCompletionService(
                sessionRepo: sessionRepo,
                skillRepo: skillRepo,
                trainingProgramRepo: trainingProgramRepo
            )
            vm = PracticeSessionViewModel(
                skills: loaded,
                completionService: completionService,
                selectedSkillId: skillId,
                plannedSession: plannedSession
            )
        }
        .fullScreenCover(item: $activeExecution) { execution in
            WorkoutView(
                skillId: skillId,
                plannedSession: plannedSession,
                sessionDraft: execution.draft,
                initialMode: execution.mode,
                onSessionFinished: { dismiss() }
            )
        }
    }

    private var navigationTitle: String {
        guard let skillName = vm?.selectedSkill?.name else {
            return String(localized: "sessionSetupTitle")
        }

        let format = String(localized: "sessionSetupTitleFormat")
        return String(format: format, skillName)
    }

    @ViewBuilder
    private func executionSection(vm: PracticeSessionViewModel) -> some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            Text(String(localized: "sessionSetupExecutionTitle"))
                .font(FMFTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(String(localized: "sessionSetupExecutionSubtitle"))
                .font(FMFTypography.bodySmall)
                .foregroundStyle(FMFColors.neutral500)

            ExecutionModeCard(
                title: String(localized: "sessionSetupModeManualTitle"),
                subtitle: String(localized: "sessionSetupModeManualSubtitle"),
                systemImage: "hand.tap",
                color: FMFColors.brandPrimary,
                isEnabled: vm.canSubmit
            ) {
                activeExecution = ExecutionSelection(mode: .manual, draft: vm.sessionDraft)
            }

            ExecutionModeCard(
                title: String(localized: "sessionSetupModeSmartTitle"),
                subtitle: String(localized: "sessionSetupModeSmartSubtitle"),
                systemImage: "sparkles",
                color: FMFColors.skillBalance,
                isEnabled: vm.canSubmit
            ) {
                activeExecution = ExecutionSelection(mode: .smart, draft: vm.sessionDraft)
            }

            ExecutionModeCard(
                title: String(localized: "sessionSetupModeSoundTitle"),
                subtitle: vm.supportsSoundExecution
                    ? String(localized: "sessionSetupModeSoundSubtitle")
                    : String(localized: "sessionSetupModeDurationOnly"),
                systemImage: "waveform.and.mic",
                color: FMFColors.skillStrength,
                isEnabled: vm.supportsSoundExecution && vm.canSubmit
            ) {
                activeExecution = ExecutionSelection(mode: .sound, draft: vm.sessionDraft)
            }
        }
        .padding(FMFSpacing.md)
        .background(FMFColors.surfaceMid)
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
    }
}

private struct ExecutionModeCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FMFSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: FMFRadius.md)
                        .fill(color.opacity(0.15))
                        .overlay {
                            RoundedRectangle(cornerRadius: FMFRadius.md)
                                .strokeBorder(color.opacity(0.25), lineWidth: 1)
                        }

                    Image(systemName: systemImage)
                        .font(.system(size: 24))
                        .foregroundStyle(color)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FMFTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color.opacity(isEnabled ? 0.7 : 0.25))
            }
            .padding(FMFSpacing.md)
            .background(color.opacity(isEnabled ? 0.08 : 0.03))
            .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: FMFRadius.lg)
                    .strokeBorder(color.opacity(isEnabled ? 0.35 : 0.15), lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
