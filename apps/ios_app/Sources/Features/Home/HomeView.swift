import SwiftUI

struct HomeView: View {
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.userSkillRepository) private var userSkillRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.practiceSessionRepository) private var sessionRepo
    @State private var vm: HomeViewModel?
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
        .navigationTitle(String(localized: "homeWelcomeTitle"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedSkill) { skill in
            SkillDetailView(skillId: skill.id)
        }
        .task {
            let viewModel = HomeViewModel(
                skillRepo: skillRepo,
                userSkillRepo: userSkillRepo,
                trainingProgramRepo: trainingProgramRepo,
                sessionRepo: sessionRepo
            )
            vm = viewModel
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func content(vm: HomeViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: FMFSpacing.sm) {
                    Text(String(localized: "homeWelcomeTitle"))
                        .font(FMFTypography.headlineLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(String(localized: "homeWelcomeSubtitle"))
                        .font(FMFTypography.bodyLarge)
                        .foregroundStyle(Color(hex: 0x7B8DB8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, FMFSpacing.md)
                .padding(.top, FMFSpacing.xxl)
                .padding(.bottom, FMFSpacing.lg)

                if vm.isLoading {
                    ProgressView()
                        .tint(FMFColors.brandAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, FMFSpacing.xxl)
                } else if let error = vm.errorMessage {
                    VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                        Text(String(localized: "errorGeneric"))
                            .font(FMFTypography.bodyMedium)
                            .foregroundStyle(.white)
                        Text(verbatim: error)
                            .font(FMFTypography.bodySmall)
                            .foregroundStyle(FMFColors.neutral500)
                    }
                        .font(FMFTypography.bodyMedium)
                        .padding(.horizontal, FMFSpacing.md)
                } else if vm.dashboardItems.isEmpty {
                    academyEmptyState
                        .padding(.horizontal, FMFSpacing.md)
                } else {
                    dashboardSection(vm: vm)
                        .padding(.horizontal, FMFSpacing.md)
                }

                if !vm.skillCatalog.isEmpty {
                    catalogSection(vm: vm)
                }
            }
            .padding(.bottom, 100)
        }
    }

    private var academyEmptyState: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.sm) {
            Text(String(localized: "home_empty_title"))
                .font(FMFTypography.titleLarge)
                .foregroundStyle(.white)

            Text(String(localized: "home_empty_subtitle"))
                .font(FMFTypography.bodyMedium)
                .foregroundStyle(FMFColors.neutral500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FMFSpacing.lg)
        .background(FMFColors.darkSurface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
    }

    private func dashboardSection(vm: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            Text(String(localized: "home_due_title"))
                .font(FMFTypography.titleLarge)
                .foregroundStyle(.white)

            ForEach(vm.dashboardItems) { item in
                DashboardCard(
                    item: item,
                    onOpenPlan: {
                        selectedSkill = item.skill
                    }
                )
            }
        }
    }

    private func catalogSection(vm: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            Text(String(localized: "home_catalog_title"))
                .font(FMFTypography.titleLarge)
                .foregroundStyle(.white)
                .padding(.horizontal, FMFSpacing.md)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: FMFSpacing.md
            ) {
                ForEach(vm.skillCatalog) { skill in
                    SkillCardView(skill: skill) {
                        selectedSkill = skill
                    }
                }
            }
            .padding(.horizontal, FMFSpacing.md)
        }
        .padding(.top, FMFSpacing.xl)
    }
}

private struct DashboardCard: View {
    let item: HomeDashboardItem
    let onOpenPlan: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var urgencyColor: Color {
        switch item.urgency {
        case .overdue:
            FMFColors.error
        case .due:
            FMFColors.warning
        case .upcoming:
            FMFColors.brandAccent
        }
    }

    private var urgencyText: String {
        switch item.urgency {
        case .overdue:
            String(localized: "urgency_overdue")
        case .due:
            String(localized: "urgency_today")
        case .upcoming:
            String(localized: "urgency_upcoming")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.skill.name)
                        .font(FMFTypography.titleMedium)
                        .foregroundStyle(.white)
                    Text(item.userSkill.level.displayName)
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                }
                Spacer()
                Text(urgencyText)
                    .font(FMFTypography.labelSmall)
                    .foregroundStyle(urgencyColor)
                    .padding(.horizontal, FMFSpacing.sm)
                    .padding(.vertical, FMFSpacing.xs)
                    .background(urgencyColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(item.plannedSession.prescription.displayString)
                .font(FMFTypography.headlineSmall)
                .foregroundStyle(.white)

            Text(item.plannedSession.prescription.notes)
                .font(FMFTypography.bodyMedium)
                .foregroundStyle(FMFColors.neutral300)

            HStack {
                Label(
                    Self.dateFormatter.string(from: item.plannedSession.scheduledDate),
                    systemImage: "calendar"
                )
                .font(FMFTypography.bodySmall)
                .foregroundStyle(FMFColors.neutral500)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(localized: "home_stats_pr_label"))
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                    Text(item.stats.personalRecord?.displayString ?? String(localized: "home_stats_none"))
                        .font(FMFTypography.labelMedium)
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: FMFSpacing.sm) {
                Button(action: onOpenPlan) {
                    Text(String(localized: "home_open_skill_button"))
                        .font(FMFTypography.labelMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FMFSpacing.sm)
                        .background(FMFColors.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FMFSpacing.lg)
        .background(FMFColors.darkSurface.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: FMFRadius.lg)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
        }
    }
}
