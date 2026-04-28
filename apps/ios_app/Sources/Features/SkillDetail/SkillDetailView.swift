import SwiftUI

struct SkillDetailView: View {
    let skillId: String
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.practiceSessionRepository) private var sessionRepo
    @State private var vm: SkillDetailViewModel?
    @State private var showSessionSetup = false
    @State private var expandedSessionIDs: Set<String> = []

    var body: some View {
        Group {
            if let vm {
                if vm.isLoading {
                    ProgressView().tint(FMFColors.brandPrimary)
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
        .atmosphericScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let deletionService = PracticeSessionDeletionService(
                sessionRepo: sessionRepo,
                skillRepo: skillRepo,
                trainingProgramRepo: trainingProgramRepo
            )
            let viewModel = SkillDetailViewModel(
                skillId: skillId,
                skillRepo: skillRepo,
                trainingProgramRepo: trainingProgramRepo,
                sessionRepo: sessionRepo,
                deletionService: deletionService
            )
            vm = viewModel
            async let load: Void = viewModel.load()
            async let watch: Void = viewModel.watchProgress()
            _ = await (load, watch)
        }
        .navigationDestination(isPresented: $showSessionSetup) {
            SessionSetupView(skillId: skillId, plannedSession: vm?.nextPlannedSession)
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
                    PersonalRecordGraphCard(
                        state: vm.chartState,
                        accentColor: catColor
                    )
                        .padding(.bottom, FMFSpacing.xl)
                }

                Button {
                    startPrimarySession()
                } label: {
                    Text(String(localized: "skillDetailStartSession"))
                        .font(FMFTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FMFSpacing.md)
                        .background(LinearGradient(gradient: FMFGradients.orange, startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.xl))
                        .shadow(color: FMFColors.brandPrimary.opacity(0.30), radius: 12, x: 0, y: 4)
                }

                if let vm, !vm.sessions.isEmpty {
                    SessionHistorySection(
                        sessions: vm.sessions,
                        metricKind: vm.chartState.metricKind,
                        expandedSessionIDs: $expandedSessionIDs,
                        onDelete: { session in
                            Task { await vm.deleteSession(session) }
                        }
                    )
                    .padding(.top, FMFSpacing.xl)
                }

                Spacer()
                    .frame(height: 100)
            }
            .padding(FMFSpacing.md)
        }
    }

    private func startPrimarySession() {
        showSessionSetup = true
    }
}

private struct PersonalRecordGraphCard: View {
    let state: PersonalRecordChartState
    let accentColor: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: FMFSpacing.md) {
            VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                Text(String(localized: "skillDetailPRTitle"))
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.neutral500)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(state.headlineValue)
                        .font(.system(size: 30, weight: .light).monospacedDigit())
                        .foregroundStyle(.white)

                    if let unit = state.headlineUnit {
                        Text(unit)
                            .font(FMFTypography.titleSmall)
                            .foregroundStyle(FMFColors.neutral300)
                    }
                }

                Text(state.trendText)
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.neutral500)
            }

            Spacer(minLength: 0)

            SparklineView(points: state.points, accentColor: accentColor)
                .frame(width: 124, height: 72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FMFSpacing.md)
        .background(FMFColors.surfaceMid)
        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: FMFRadius.lg)
                .strokeBorder(accentColor.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct SparklineView: View {
    let points: [PersonalRecordPoint]
    let accentColor: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: FMFRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                FMFColors.surfaceLow,
                                FMFColors.surfaceLow.opacity(0.88)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if points.isEmpty {
                    EmptySparklinePlaceholder()
                        .padding(.horizontal, FMFSpacing.sm)
                        .padding(.vertical, FMFSpacing.md)
                } else {
                    let pathPoints = sparklinePoints(in: proxy.size)

                    Path { path in
                        guard let first = pathPoints.first else { return }
                        path.move(to: first)
                        for point in pathPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [accentColor.opacity(0.35), FMFColors.brandPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: FMFColors.brandPrimary.opacity(0.28), radius: 8, x: 0, y: 4)

                    if let last = pathPoints.last {
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .shadow(color: .white.opacity(0.7), radius: 6, x: 0, y: 0)
                            .overlay {
                                Circle()
                                    .strokeBorder(FMFColors.brandPrimary.opacity(0.5), lineWidth: 2)
                            }
                            .position(last)
                    }
                }
            }
        }
    }

    private func sparklinePoints(in size: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        if points.count == 1 {
            return [CGPoint(x: size.width * 0.85, y: size.height * 0.3)]
        }

        let scores = points.map(\.score)
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 0
        let scoreRange = max(maxScore - minScore, 1)
        let width = max(size.width - 16, 1)
        let height = max(size.height - 16, 1)

        return points.enumerated().map { index, point in
            let xProgress = CGFloat(index) / CGFloat(max(points.count - 1, 1))
            let normalizedY = CGFloat(point.score - minScore) / CGFloat(scoreRange)
            let x = 8 + (width * xProgress)
            let y = 8 + height - (height * normalizedY)
            return CGPoint(x: x, y: y)
        }
    }
}

private struct EmptySparklinePlaceholder: View {
    var body: some View {
        HStack(spacing: 8) {
            Capsule().fill(FMFColors.neutral700.opacity(0.45)).frame(width: 22, height: 3)
            Capsule().fill(FMFColors.neutral700.opacity(0.28)).frame(width: 30, height: 3)
            Capsule().fill(FMFColors.neutral700.opacity(0.18)).frame(width: 16, height: 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct SessionHistorySection: View {
    let sessions: [PracticeSession]
    let metricKind: SkillMetricKind
    @Binding var expandedSessionIDs: Set<String>
    let onDelete: (PracticeSession) -> Void

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            Text(String(localized: "skillDetailSessionHistoryTitle"))
                .font(FMFTypography.titleMedium)
                .foregroundStyle(.white)

            VStack(spacing: FMFSpacing.sm) {
                ForEach(sessions) { session in
                    SessionHistoryRow(
                        session: session,
                        metricKind: metricKind,
                        isExpanded: expandedSessionIDs.contains(session.id),
                        onDelete: { onDelete(session) },
                        onToggle: {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                if expandedSessionIDs.contains(session.id) {
                                    expandedSessionIDs.remove(session.id)
                                } else {
                                    expandedSessionIDs.insert(session.id)
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

private struct SessionHistoryRow: View {
    let session: PracticeSession
    let metricKind: SkillMetricKind
    let isExpanded: Bool
    let onDelete: () -> Void
    let onToggle: () -> Void

    private var bestValueText: String {
        metricKind.headlineValue(for: session.sessionScore)
    }

    private var dateText: String {
        let dateText = SessionHistorySection.dateFormatter.string(from: session.date)
        return dateText
    }

    private var totalValueText: String {
        switch metricKind {
        case .time:
            return PRValue.duration(seconds: totalTimeSeconds).displayString
        case .reps:
            return "\(session.sessionScore)"
        case .weight(let unit):
            return "\(session.sessionScore) \(unit)"
        }
    }

    private var totalValueLabel: String {
        switch metricKind {
        case .time:
            return String(localized: "skillDetailSessionTotalTime")
        case .reps:
            return String(localized: "skillDetailSessionTotalReps")
        case .weight:
            return String(localized: "skillDetailSessionTotalWeight")
        }
    }

    private var compactSummaryText: String {
        "\(dateText) • \(totalValueLabel.lowercased()): \(totalValueText)"
    }

    private var bestValueLabel: String {
        switch metricKind {
        case .time:
            return String(localized: "skillDetailSessionBestTime")
        case .reps:
            return String(localized: "skillDetailSessionBestSet")
        case .weight:
            return String(localized: "skillDetailSessionBestWeight")
        }
    }

    private var totalTimeSeconds: Int {
        if !session.durationSetValues.isEmpty {
            return session.durationSetValues.reduce(0, +)
        }

        switch metricKind {
        case .time:
            return max(0, session.targetValuePerSet * max(session.setsCompleted, 1))
        case .reps, .weight:
            return max(0, session.durationMinutes * 60)
        }
    }

    private var performedSetValues: [Int] {
        if !session.durationSetValues.isEmpty {
            return session.durationSetValues
        }

        let fallbackCount = max(session.setsCompleted, 0)
        guard fallbackCount > 0 else { return [] }
        return Array(repeating: max(session.targetValuePerSet, 0), count: fallbackCount)
    }

    private var completedAtText: String? {
        guard let completedAt = session.completedAt else { return nil }
        return SessionHistorySection.timeFormatter.string(from: completedAt)
    }

    private var notesText: String? {
        guard let notes = session.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty else {
            return nil
        }
        return notes
    }

    private var chevronName: String {
        isExpanded ? "chevron.up" : "chevron.down"
    }

    private func setValueText(_ value: Int) -> String {
        switch metricKind {
        case .time:
            return PRValue.duration(seconds: value).displayString
        case .reps:
            return "\(value) \(String(localized: "practiceSessionRepsUnit"))"
        case .weight(let unit):
            return "\(value) \(unit)"
        }
    }

    private func metaValue(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(FMFTypography.titleSmall)
                .foregroundStyle(.white)
                .monospacedDigit()

            Text(label)
                .font(FMFTypography.bodySmall)
                .foregroundStyle(FMFColors.neutral500)
        }
    }

    private func setRow(index: Int, value: Int) -> some View {
        HStack {
            Text(String(format: String(localized: "skillDetailSessionSetNumberFormat"), index + 1))
                .font(FMFTypography.bodyMedium)
                .foregroundStyle(FMFColors.neutral300)

            Spacer()

            Text(setValueText(value))
                .font(FMFTypography.bodyMedium)
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: isExpanded ? FMFSpacing.sm : FMFSpacing.xs) {
                HStack(alignment: .center, spacing: FMFSpacing.sm) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(bestValueText)
                                .font(FMFTypography.titleMedium)
                                .foregroundStyle(.white)
                                .monospacedDigit()

                            Text(bestValueLabel)
                                .font(FMFTypography.bodySmall)
                                .foregroundStyle(FMFColors.neutral500)
                        }

                        Text(compactSummaryText)
                            .font(FMFTypography.bodySmall)
                            .foregroundStyle(FMFColors.neutral500)
                            .lineLimit(1)
                    }

                    Spacer(minLength: FMFSpacing.sm)

                    HStack(spacing: FMFSpacing.xs) {
                        if session.isPersonalRecord {
                            Text(String(localized: "skillDetailPR"))
                                .font(FMFTypography.labelSmall)
                                .foregroundStyle(FMFColors.brandPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(FMFColors.brandPrimary.opacity(0.14))
                                .clipShape(Capsule())
                        }

                        Image(systemName: chevronName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FMFColors.neutral500)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .frame(width: 18, height: 18)
                    }
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: FMFSpacing.sm) {
                        Divider()
                            .overlay(FMFColors.neutral700)

                        HStack(spacing: FMFSpacing.md) {
                            metaValue("\(session.setsCompleted)", label: String(localized: "skillDetailSessionSets"))
                            metaValue(setValueText(session.targetValuePerSet), label: String(localized: "skillDetailSessionTargetPerSet"))
                            metaValue(PRValue.duration(seconds: session.restSeconds).displayString, label: String(localized: "skillDetailSessionRest"))
                        }

                        VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                            Text(String(localized: "skillDetailSessionSetBreakdown"))
                                .font(FMFTypography.labelMedium)
                                .foregroundStyle(FMFColors.neutral500)

                            ForEach(Array(performedSetValues.enumerated()), id: \.offset) { index, value in
                                setRow(index: index, value: value)
                            }
                        }

                        if let notesText {
                            VStack(alignment: .leading, spacing: FMFSpacing.xs) {
                                Text(String(localized: "skillDetailSessionNotes"))
                                    .font(FMFTypography.labelMedium)
                                    .foregroundStyle(FMFColors.neutral500)

                                Text(notesText)
                                    .font(FMFTypography.bodySmall)
                                    .foregroundStyle(FMFColors.neutral300)
                                    .lineLimit(3)
                            }
                        }

                        Divider()
                            .overlay(FMFColors.neutral700)

                        Button(role: .destructive, action: onDelete) {
                            Label(String(localized: "skillDetailSessionDelete"), systemImage: "trash")
                                .font(FMFTypography.bodySmall)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: -6)).combined(with: .scale(scale: 0.98, anchor: .top)),
                            removal: .opacity.combined(with: .offset(y: -4))
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FMFSpacing.md)
            .padding(.vertical, isExpanded ? FMFSpacing.md : FMFSpacing.sm)
            .background(FMFColors.surfaceMid)
            .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label(String(localized: "skillDetailSessionDelete"), systemImage: "trash")
            }
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
