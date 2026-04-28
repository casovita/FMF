import SwiftUI

struct SkillsBrowseView: View {
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.userSkillRepository) private var userSkillRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.practiceSessionRepository) private var sessionRepo
    @State private var vm: SkillsBrowseViewModel?
    @State private var selectedSkill: Skill?

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
            }
        }
        .atmosphericScreenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedSkill) { skill in
            SkillDetailView(skillId: skill.id)
        }
        .task {
            let viewModel = SkillsBrowseViewModel(
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
    private func content(vm: SkillsBrowseViewModel) -> some View {
        @Bindable var bindableVM = vm

        if vm.shouldShowDiscoveryControls {
            ScrollView {
                browseBody(vm: vm)
            }
            .searchable(
                text: $bindableVM.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(String(localized: "browse_search_prompt"))
            )
        } else {
            ScrollView {
                browseBody(vm: vm)
            }
        }
    }

    @ViewBuilder
    private func browseBody(vm: SkillsBrowseViewModel) -> some View {
        VStack(alignment: .leading, spacing: FMFSpacing.xl) {
            Text(String(localized: "browseTitle"))
                .font(FMFTypography.headlineLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(String(localized: "browse_subtitle"))
                .font(FMFTypography.bodyLarge)
                .foregroundStyle(FMFColors.neutral500)
                .frame(maxWidth: .infinity, alignment: .leading)

            if vm.shouldShowDiscoveryControls {
                discoveryControls(vm: vm)
            }

            if vm.isLoading {
                ProgressView()
                    .tint(FMFColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, FMFSpacing.xl)
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
            } else if vm.visibleItems.isEmpty {
                filteredEmptyState
            } else {
                if !vm.continueTrainingItems.isEmpty {
                    SkillsBrowseSection(
                        title: String(localized: "browse_continue_title"),
                        subtitle: String(localized: "browse_continue_subtitle")
                    ) {
                        VStack(spacing: FMFSpacing.md) {
                            ForEach(Array(vm.continueTrainingItems.prefix(3))) { item in
                                ActiveSkillCard(item: item) {
                                    selectedSkill = item.skill
                                }
                            }
                        }
                    }
                }

                if !vm.unlockNextItems.isEmpty {
                    SkillsBrowseSection(
                        title: String(localized: "browse_unlock_title"),
                        subtitle: String(localized: "browse_unlock_subtitle")
                    ) {
                        VStack(spacing: FMFSpacing.md) {
                            ForEach(vm.unlockNextItems) { item in
                                RoadmapSkillRow(item: item, style: .recommended) {
                                    selectedSkill = item.skill
                                }
                            }
                        }
                    }
                }

                if !vm.futureCurriculumItems.isEmpty {
                    SkillsBrowseSection(
                        title: String(localized: "browse_future_title"),
                        subtitle: String(localized: "browse_future_subtitle")
                    ) {
                        VStack(spacing: FMFSpacing.md) {
                            ForEach(vm.futureCurriculumItems) { item in
                                RoadmapSkillRow(item: item, style: .muted) {
                                    selectedSkill = item.skill
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, FMFSpacing.md)
        .padding(.top, FMFSpacing.sm)
        .padding(.bottom, 100)
    }

    private func discoveryControls(vm: SkillsBrowseViewModel) -> some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FMFSpacing.sm) {
                    ForEach(SkillsBrowseStatusFilter.allCases) { filter in
                        BrowseFilterChip(
                            title: filterTitle(for: filter),
                            isSelected: vm.selectedStatusFilter == filter
                        ) {
                            vm.selectedStatusFilter = filter
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FMFSpacing.sm) {
                    BrowseFilterChip(
                        title: String(localized: "browse_filter_all_categories"),
                        isSelected: vm.isCategorySelected(nil)
                    ) {
                        vm.selectedCategory = nil
                    }

                    ForEach(SkillCategory.allCases, id: \.self) { category in
                        BrowseFilterChip(
                            title: categoryTitle(for: category),
                            isSelected: vm.isCategorySelected(category)
                        ) {
                            vm.selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    private func filterTitle(for filter: SkillsBrowseStatusFilter) -> String {
        switch filter {
        case .all:
            return String(localized: "browse_filter_all")
        case .active:
            return String(localized: "browse_filter_active")
        case .available:
            return String(localized: "browse_filter_available")
        case .future:
            return String(localized: "browse_filter_future")
        }
    }

    private func categoryTitle(for category: SkillCategory) -> String {
        switch category {
        case .balance:
            return String(localized: "browse_category_balance")
        case .strength:
            return String(localized: "browse_category_strength")
        case .bodyweight:
            return String(localized: "browse_category_bodyweight")
        }
    }

    private var filteredEmptyState: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.sm) {
            Text(String(localized: "browse_filtered_empty_title"))
                .font(FMFTypography.titleLarge)
                .foregroundStyle(.white)

            Text(String(localized: "browse_filtered_empty_subtitle"))
                .font(FMFTypography.bodyMedium)
                .foregroundStyle(FMFColors.neutral500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FMFSpacing.lg)
        .background(FMFColors.surfaceMid.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
    }
}

private struct SkillsBrowseSection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                Text(title)
                    .font(FMFTypography.titleLarge)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.neutral500)
            }

            content
        }
    }
}

private struct BrowseFilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(FMFTypography.labelMedium)
                .foregroundStyle(isSelected ? .white : FMFColors.neutral300)
                .padding(.horizontal, FMFSpacing.md)
                .padding(.vertical, 10)
                .background(isSelected ? FMFColors.brandPrimary : FMFColors.surfaceMid.opacity(0.95))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? FMFColors.brandPrimaryLight.opacity(0.6) : .white.opacity(0.08),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

private struct ActiveSkillCard: View {
    private static let progressMilestone = 20.0

    let item: SkillRoadmapItem
    let onTap: () -> Void

    private var practiceCount: Int? {
        guard let count = item.practiceCount, count > 0 else { return nil }
        return count
    }

    private var progressValue: Double? {
        guard let practiceCount else { return nil }
        return min(Double(practiceCount) / Self.progressMilestone, 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FMFSpacing.md) {
                SkillRoadmapTile(skill: item.skill, size: 70, isMuted: false)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: FMFSpacing.sm) {
                        Text(item.skill.name)
                            .font(FMFTypography.titleLarge)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)

                        SkillStateChip(state: item.state)
                    }

                    if let personalRecord = item.personalRecord {
                        Text(
                            String(
                                format: String(localized: "browse_active_pr_format"),
                                String(localized: "skillDetailPR"),
                                personalRecord.displayString
                            )
                        )
                            .font(FMFTypography.bodySmall)
                            .foregroundStyle(FMFColors.neutral300)
                            .lineLimit(1)
                    }

                    if let progressValue, let practiceCount {
                        VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                            HStack(spacing: FMFSpacing.xs) {
                                Text(
                                    String(
                                        format: String(localized: "browse_active_progress_format"),
                                        practiceCount
                                    )
                                )
                                .font(FMFTypography.labelSmall)
                                .foregroundStyle(FMFColors.neutral500)

                                Spacer(minLength: 0)
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(FMFColors.neutral700.opacity(0.8))

                                    Capsule()
                                        .fill(categoryColor(for: item.skill.category))
                                        .frame(width: max(proxy.size.width * progressValue, 6))
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FMFColors.neutral500)
            }
            .padding(.horizontal, FMFSpacing.md)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: FMFRadius.lg)
                    .fill(LinearGradient(gradient: FMFGradients.cardSurface, startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                RoundedRectangle(cornerRadius: FMFRadius.lg)
                    .strokeBorder(categoryColor(for: item.skill.category).opacity(0.24), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
            .shadow(color: categoryColor(for: item.skill.category).opacity(0.10), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.skill.name), \(accessibilityStateLabel(for: item.state))")
    }
}

private struct RoadmapSkillRow: View {
    enum Style {
        case recommended
        case muted
    }

    let item: SkillRoadmapItem
    let style: Style
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FMFSpacing.md) {
                SkillRoadmapTile(skill: item.skill, size: style == .recommended ? 56 : 64, isMuted: style == .muted)

                VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                    HStack(spacing: FMFSpacing.sm) {
                        Text(item.skill.name)
                            .font(FMFTypography.titleMedium)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)

                        if style == .recommended {
                            SkillStateChip(state: item.state)
                        }
                    }

                    if style == .recommended {
                        Text(item.nextActionLabel ?? item.prerequisiteSummary ?? item.skill.description)
                            .font(FMFTypography.bodySmall)
                            .foregroundStyle(FMFColors.brandPrimaryLight)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(item.skill.description)
                            .font(FMFTypography.bodySmall)
                            .foregroundStyle(FMFColors.neutral500)
                            .multilineTextAlignment(.leading)

                        if let prerequisiteSummary = item.prerequisiteSummary {
                            Text(prerequisiteSummary)
                                .font(FMFTypography.labelSmall)
                                .foregroundStyle(stateColor(for: item.state))
                        }

                        if let nextActionLabel = item.nextActionLabel {
                            Text(nextActionLabel)
                                .font(FMFTypography.bodySmall)
                                .foregroundStyle(FMFColors.neutral300)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FMFColors.neutral500)
            }
            .padding(.horizontal, FMFSpacing.md)
            .padding(.vertical, style == .recommended ? 12 : FMFSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: FMFRadius.lg)
                    .fill(backgroundFill)
            }
            .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: FMFRadius.lg)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.skill.name), \(accessibilityStateLabel(for: item.state))")
    }

    private var backgroundFill: AnyShapeStyle {
        switch style {
        case .recommended:
            return AnyShapeStyle(FMFColors.surfaceMid.opacity(0.9))
        case .muted:
            return AnyShapeStyle(FMFColors.surfaceMid.opacity(0.86))
        }
    }

    private var borderColor: Color {
        switch style {
        case .recommended:
            return .white.opacity(0.06)
        case .muted:
            return .white.opacity(0.06)
        }
    }
}

private struct SkillRoadmapTile: View {
    let skill: Skill
    let size: CGFloat
    let isMuted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(
                    LinearGradient(
                        gradient: FMFGradients.forCategory(skill.category),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.24)
                        .fill(.black.opacity(isMuted ? 0.35 : 0.0))
                }

            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(.white.opacity(isMuted ? 0.10 : 0.16))
                .frame(width: size * 0.54, height: size * 0.54)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .strokeBorder(.white.opacity(isMuted ? 0.16 : 0.24), lineWidth: 1)
                        .frame(width: size * 0.54, height: size * 0.54)
                }

            if let imageName = iconName(for: skill.id) {
                Image(imageName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(isMuted ? 0.85 : 1.0))
                    .padding(size * 0.29)
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: size * 0.26, weight: .medium))
                    .foregroundStyle(.white.opacity(isMuted ? 0.85 : 1.0))
            }
        }
        .frame(width: size, height: size)
        .shadow(color: categoryColor(for: skill.category).opacity(isMuted ? 0.08 : 0.18), radius: size * 0.2, x: 0, y: size * 0.08)
    }
}

private struct SkillStateChip: View {
    let state: SkillsBrowseState

    var body: some View {
        Text(stateTitle(for: state))
            .font(FMFTypography.labelSmall)
            .foregroundStyle(stateColor(for: state))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(stateColor(for: state).opacity(0.14))
            .clipShape(Capsule())
    }
}

private func stateTitle(for state: SkillsBrowseState) -> String {
    switch state {
    case .active:
        return String(localized: "browse_state_active")
    case .available:
        return String(localized: "browse_state_available")
    case .locked:
        return String(localized: "browse_state_locked")
    case .future:
        return String(localized: "browse_state_future")
    }
}

private func accessibilityStateLabel(for state: SkillsBrowseState) -> String {
    switch state {
    case .active:
        return String(localized: "browse_accessibility_active")
    case .available:
        return String(localized: "browse_accessibility_available")
    case .locked:
        return String(localized: "browse_accessibility_locked")
    case .future:
        return String(localized: "browse_accessibility_future")
    }
}

private func stateColor(for state: SkillsBrowseState) -> Color {
    switch state {
    case .active:
        return FMFColors.success
    case .available:
        return FMFColors.brandPrimary
    case .locked:
        return FMFColors.warning
    case .future:
        return FMFColors.neutral500
    }
}

private func categoryColor(for category: SkillCategory) -> Color {
    switch category {
    case .balance:
        return FMFColors.skillBalance
    case .strength:
        return FMFColors.skillStrength
    case .bodyweight:
        return FMFColors.skillBodyweight
    }
}

private func iconName(for skillId: String) -> String? {
    switch skillId {
    case "handstand":
        return "handstand"
    case "pullups":
        return "pullups"
    case "handstand_pushups":
        return "handstand_pushups"
    default:
        return nil
    }
}
