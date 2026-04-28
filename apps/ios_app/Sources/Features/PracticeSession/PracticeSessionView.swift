import SwiftUI

struct PracticeSessionView: View {
    let skillId: String
    let plannedSession: PlannedSession?

    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.practiceSessionRepository) private var sessionRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.dismiss) private var dismiss
    @State private var vm: PracticeSessionViewModel?

    init(skillId: String, plannedSession: PlannedSession? = nil) {
        self.skillId = skillId
        self.plannedSession = plannedSession
    }

    var body: some View {
        Group {
            if let vm {
                form(vm: vm)
                    .onChange(of: vm.didSave) { _, saved in
                        if saved { dismiss() }
                    }
            } else {
                ProgressView().tint(FMFColors.brandPrimary)
            }
        }
        .atmosphericScreenBackground()
        .navigationTitle(vm?.navigationTitle ?? "")
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
    }

    @ViewBuilder
    private func form(vm: PracticeSessionViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FMFSpacing.lg) {
                PracticeSessionFormView(vm: vm)

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
                    .background {
                        if vm.canSubmit {
                            LinearGradient(gradient: FMFGradients.orange, startPoint: .leading, endPoint: .trailing)
                        } else {
                            LinearGradient(colors: [FMFColors.neutral700, FMFColors.neutral700], startPoint: .leading, endPoint: .trailing)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: FMFRadius.xl))
                }
                .disabled(!vm.canSubmit || vm.isLoading)
            }
            .padding(FMFSpacing.md)
            .padding(.bottom, FMFSpacing.xxl)
        }
    }
}
