import SwiftUI

struct ProgressScreenView: View {
    @Environment(\.practiceSessionRepository) private var sessionRepo
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.userSkillRepository) private var userSkillRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @State private var vm: ProgressViewModel?

    var body: some View {
        ZStack {
            FMFColors.brandPrimary.ignoresSafeArea()

            Group {
                if let vm {
                    content(vm: vm)
                }
            }
        }
        .navigationTitle(String(localized: "progressTitle"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let viewModel = ProgressViewModel(
                sessionRepo: sessionRepo,
                skillRepo: skillRepo,
                userSkillRepo: userSkillRepo,
                trainingProgramRepo: trainingProgramRepo
            )
            vm = viewModel
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func content(vm: ProgressViewModel) -> some View {
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
        } else if vm.summaries.isEmpty {
            Text(String(localized: "emptyStateNoSessions"))
                .font(FMFTypography.bodyLarge)
                .foregroundStyle(FMFColors.neutral500)
                .multilineTextAlignment(.center)
                .padding(FMFSpacing.lg)
        } else {
            ScrollView {
                VStack(spacing: FMFSpacing.md) {
                    ForEach(vm.summaries) { summary in
                        ProgressSummaryCard(summary: summary)
                    }
                }
                .padding(FMFSpacing.md)
            }
        }
    }
}

private struct ProgressSummaryCard: View {
    let summary: ProgressSkillSummary

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.skill.name)
                        .font(FMFTypography.titleMedium)
                        .foregroundStyle(.white)

                    Text(planProgressText)
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                }
                Spacer()
                statusBadge
            }

            HStack(alignment: .top, spacing: FMFSpacing.md) {
                metric(label: String(localized: "skillDetailSessions"), value: "\(summary.stats.totalSessions)")
                metric(label: String(localized: "progress_minutes"), value: "\(summary.stats.totalMinutes)")
                metric(label: String(localized: "skillDetailPR"), value: summary.stats.personalRecord?.displayString ?? String(localized: "home_stats_none"))
            }

            HStack(alignment: .top, spacing: FMFSpacing.md) {
                metric(label: String(localized: "skillDetailStreak"), value: "\(summary.stats.currentStreak)")
                metric(label: String(localized: "progress_longest_streak"), value: "\(summary.stats.longestStreak)")
                metric(label: String(localized: "skillDetailCompletion"), value: "\(Int((summary.stats.weeklyCompletionRate * 100).rounded()))%")
            }

            VStack(alignment: .leading, spacing: 6) {
                if let next = summary.nextPlannedSession {
                    Text("\(String(localized: "progress_next_session")) \(Self.dateFormatter.string(from: next.scheduledDate))")
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                }

                if let progress = summary.progress, let lastDate = progress.lastPracticeDate {
                    Text("\(String(localized: "progress_last_trained")) \(Self.dateFormatter.string(from: lastDate))")
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FMFSpacing.md)
        .background(FMFColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
    }

    private var planProgressText: String {
        String(
            format: String(localized: "progress_plan_status_format"),
            locale: Locale.current,
            summary.completedPlannedSessions,
            summary.totalPlannedSessions
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let next = summary.nextPlannedSession {
            let calendar = Calendar.current
            let scheduledDay = calendar.startOfDay(for: next.scheduledDate)
            let today = calendar.startOfDay(for: Date())
            let (label, color): (String, Color) =
                if scheduledDay < today {
                    (String(localized: "urgency_overdue"), FMFColors.warning)
                } else if scheduledDay == today {
                    (String(localized: "urgency_today"), FMFColors.brandAccent)
                } else {
                    (String(localized: "urgency_upcoming"), FMFColors.neutral300)
                }

            Text(label)
                .font(FMFTypography.labelMedium)
                .foregroundStyle(color)
                .padding(.horizontal, FMFSpacing.sm)
                .padding(.vertical, 6)
                .background(color.opacity(0.16))
                .clipShape(Capsule())
        }
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(FMFTypography.bodySmall)
                .foregroundStyle(FMFColors.neutral500)
            Text(value)
                .font(FMFTypography.titleSmall)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
