import SwiftUI

struct SkillDetailView: View {
    let skillId: String
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.userSkillRepository) private var userSkillRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.practiceSessionRepository) private var sessionRepo
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
                        VStack(spacing: FMFSpacing.xs) {
                            Text(String(localized: "errorGeneric"))
                                .foregroundStyle(.white)
                            Text(verbatim: error)
                                .font(FMFTypography.bodySmall)
                                .foregroundStyle(FMFColors.neutral500)
                        }
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
            let viewModel = SkillDetailViewModel(
                skillId: skillId,
                skillRepo: skillRepo,
                userSkillRepo: userSkillRepo,
                trainingProgramRepo: trainingProgramRepo,
                sessionRepo: sessionRepo
            )
            vm = viewModel
            async let load: Void = viewModel.load()
            async let watch: Void = viewModel.watchProgress()
            _ = await (load, watch)
        }
        .fullScreenCover(isPresented: $showWorkout) {
            WorkoutView(skillId: skillId, plannedSession: vm?.nextPlannedSession)
        }
        .navigationDestination(isPresented: $showPracticeSession) {
            PracticeSessionView(skillId: skillId, plannedSession: vm?.nextPlannedSession)
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
                CategoryChip(category: skill.category, color: catColor)
                    .padding(.bottom, FMFSpacing.sm)

                Text(skill.name)
                    .font(FMFTypography.headlineMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.bottom, FMFSpacing.sm)

                Text(skill.description)
                    .font(FMFTypography.bodyLarge)
                    .foregroundStyle(FMFColors.neutral300)
                    .padding(.bottom, FMFSpacing.xl)

                if let vm {
                    SkillProgramCard(vm: vm, color: catColor)
                        .padding(.bottom, FMFSpacing.lg)

                    SkillStatsCard(vm: vm)
                        .padding(.bottom, FMFSpacing.lg)

                    SkillSettingsCard(vm: vm)
                        .padding(.bottom, FMFSpacing.xl)
                }

                Button {
                    startPrimarySession(for: skill)
                } label: {
                    Text(String(localized: "skillDetailStartSession"))
                        .font(FMFTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FMFSpacing.md)
                        .background(FMFColors.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.xl))
                }
                .padding(.bottom, FMFSpacing.md)

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

    private func startPrimarySession(for skill: Skill) {
        showWorkout = true
    }
}

private struct SkillProgramCard: View {
    let vm: SkillDetailViewModel
    let color: Color

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.sm) {
            Text(String(localized: "skillDetailProgramTitle"))
                .font(FMFTypography.titleMedium)
                .foregroundStyle(.white)

            if let userSkill = vm.userSkill {
                Text("\(userSkill.level.displayName) • \(userSkill.weeklyFrequency)x \(String(localized: "onboarding_per_week_label"))")
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral300)
            } else {
                Text(String(localized: "skillDetailProgramMissing"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral500)
            }

            if let next = vm.nextPlannedSession {
                Text(next.prescription.displayString)
                    .font(FMFTypography.headlineSmall)
                    .foregroundStyle(.white)
                Text(next.prescription.notes)
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.neutral500)
                Text(Self.dateFormatter.string(from: next.scheduledDate))
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FMFSpacing.md)
        .background(FMFColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: FMFRadius.lg)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        }
    }
}

private struct SkillStatsCard: View {
    let vm: SkillDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            Text(String(localized: "skillDetailStatsTitle"))
                .font(FMFTypography.titleMedium)
                .foregroundStyle(.white)

            if let stats = vm.stats {
                HStack {
                    SkillMetricView(label: String(localized: "skillDetailSessions"), value: "\(stats.totalSessions)")
                    SkillMetricView(label: String(localized: "skillDetailStreak"), value: "\(stats.currentStreak)")
                }
                HStack {
                    SkillMetricView(label: String(localized: "skillDetailCompletion"), value: "\(Int((stats.weeklyCompletionRate * 100).rounded()))%")
                    SkillMetricView(label: String(localized: "skillDetailPR"), value: stats.personalRecord?.displayString ?? String(localized: "home_stats_none"))
                }
            }

            if let progress = vm.progress {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "skillDetailProgressTitle"))
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                    Text("\(progress.practiceCount)")
                        .font(FMFTypography.titleSmall)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FMFSpacing.md)
        .background(FMFColors.darkSurface.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
    }
}

private struct SkillMetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(FMFTypography.bodySmall)
                .foregroundStyle(FMFColors.neutral500)
            Text(value)
                .font(FMFTypography.titleMedium)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SkillSettingsCard: View {
    @Bindable var vm: SkillDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            Text(String(localized: "skillDetailSettingsTitle"))
                .font(FMFTypography.titleMedium)
                .foregroundStyle(.white)

            Toggle(isOn: $vm.isActive) {
                Text(String(localized: "skillDetailActiveToggle"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(.white)
            }
            .tint(FMFColors.brandAccent)

            Picker(String(localized: "skillDetailLevelLabel"), selection: $vm.selectedLevel) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Stepper(
                value: $vm.weeklyFrequency,
                in: 2...5
            ) {
                Text("\(String(localized: "skillDetailFrequencyLabel")) \(vm.weeklyFrequency)x")
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(.white)
            }

            Button {
                Task { await vm.saveSettings() }
            } label: {
                Group {
                    if vm.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text(String(localized: "skillDetailSaveSettings"))
                            .font(FMFTypography.labelMedium)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, FMFSpacing.sm)
                .background(FMFColors.brandAccent)
                .clipShape(RoundedRectangle(cornerRadius: FMFRadius.md))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FMFSpacing.md)
        .background(FMFColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
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
