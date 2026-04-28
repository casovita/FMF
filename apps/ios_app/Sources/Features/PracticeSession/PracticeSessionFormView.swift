import SwiftUI

struct PracticeSessionFormView: View {
    let vm: PracticeSessionViewModel

    @State private var activePicker: ActivePicker?

    private enum ActivePicker: Identifiable {
        case sets
        case target
        case rest
        case setDuration(Int)

        var id: String {
            switch self {
            case .sets: return "sets"
            case .target: return "target"
            case .rest: return "rest"
            case .setDuration(let i): return "setDuration-\(i)"
            }
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: FMFSpacing.md),
        GridItem(.flexible(), spacing: FMFSpacing.md)
    ]

    private var accentColor: Color {
        guard let category = vm.selectedSkill?.category else { return FMFColors.brandPrimary }
        return FMFGradients.accentForCategory(category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.md) {
            LazyVGrid(columns: columns, spacing: FMFSpacing.md) {
                MetricValueTile(
                    label: String(localized: "practiceSessionSetsLabel"),
                    systemImage: "number",
                    valueText: "\(vm.setsCompleted)",
                    accentColor: accentColor,
                    accessibilityPrefix: "sessionForm.sets"
                ) { activePicker = .sets }

                if vm.usesPerSetDurationInputs {
                    MetricValueTile(
                        label: String(localized: "practiceSessionRestLabel"),
                        systemImage: "pause.circle",
                        valueText: vm.restValueText,
                        accentColor: accentColor,
                        accessibilityPrefix: "sessionForm.rest"
                    ) { activePicker = .rest }
                } else {
                    MetricValueTile(
                        label: vm.targetLabel,
                        systemImage: "figure.strengthtraining.traditional",
                        valueText: vm.targetValueText,
                        accentColor: accentColor,
                        accessibilityPrefix: "sessionForm.target"
                    ) { activePicker = .target }

                    MetricValueTile(
                        label: String(localized: "practiceSessionRestLabel"),
                        systemImage: "pause.circle",
                        valueText: vm.restValueText,
                        accentColor: accentColor,
                        accessibilityPrefix: "sessionForm.rest"
                    ) { activePicker = .rest }
                }
            }

            if vm.usesPerSetDurationInputs {
                DurationSetsCard(vm: vm, accentColor: accentColor) { index in
                    activePicker = .setDuration(index)
                }
            }
        }
        .sheet(item: $activePicker) { picker in
            pickerSheet(for: picker)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func pickerSheet(for picker: ActivePicker) -> some View {
        switch picker {
        case .sets:
            MetricPickerSheet(
                title: String(localized: "practiceSessionSetsLabel"),
                range: 1...20,
                value: vm.setsCompleted,
                label: { "\($0)" }
            ) { vm.updateSetsCompleted($0) }

        case .target:
            MetricPickerSheet(
                title: vm.targetLabel,
                range: 1...50,
                value: vm.targetValuePerSet,
                label: { String(format: String(localized: "practiceSessionRepsValueFormat"), $0) }
            ) { vm.targetValuePerSet = $0 }

        case .rest:
            MetricPickerSheet(
                title: String(localized: "practiceSessionRestLabel"),
                range: 0...300,
                value: vm.restSeconds,
                label: { String(format: String(localized: "practiceSessionSecondsValueFormat"), $0) }
            ) { vm.restSeconds = $0 }

        case .setDuration(let index):
            MetricPickerSheet(
                title: vm.durationLabel(forSetAt: index),
                range: 5...300,
                value: vm.durationValue(at: index),
                label: { String(format: String(localized: "practiceSessionSecondsValueFormat"), $0) }
            ) { vm.updateDurationValue(at: index, value: $0) }
        }
    }
}

// MARK: - Metric value tile (tappable, opens picker sheet)

private struct MetricValueTile: View {
    let label: String
    let systemImage: String
    let valueText: String
    let accentColor: Color
    let accessibilityPrefix: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: FMFSpacing.sm) {
                Label(label, systemImage: systemImage)
                    .font(FMFTypography.labelMedium)
                    .foregroundStyle(FMFColors.neutral300)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .accessibilityIdentifier("\(accessibilityPrefix).label")

                HStack(alignment: .bottom) {
                    Text(valueText)
                        .font(FMFTypography.titleLarge)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .accessibilityIdentifier("\(accessibilityPrefix).value")

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accentColor.opacity(0.7))
                }
            }
            .padding(FMFSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: FMFRadius.lg)
                    .fill(FMFColors.surfaceMid)
                    .overlay {
                        RoundedRectangle(cornerRadius: FMFRadius.lg)
                            .strokeBorder(accentColor.opacity(0.14), lineWidth: 1)
                    }
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(accessibilityPrefix).tile")
    }
}

// MARK: - Duration sets card

private struct DurationSetsCard: View {
    let vm: PracticeSessionViewModel
    let accentColor: Color
    let onTapSet: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FMFSpacing.sm) {
            Label(vm.perSetDurationTitle, systemImage: "timer")
                .font(FMFTypography.labelLarge)
                .foregroundStyle(FMFColors.neutral300)

            VStack(spacing: 0) {
                ForEach(Array(vm.durationSetValues.indices), id: \.self) { index in
                    Button { onTapSet(index) } label: {
                        DurationSetRow(
                            title: vm.durationLabel(forSetAt: index),
                            valueText: String(
                                format: String(localized: "practiceSessionSecondsValueFormat"),
                                vm.durationValue(at: index)
                            ),
                            accentColor: accentColor,
                            accessibilityPrefix: "sessionForm.durationSet\(index + 1)"
                        )
                    }
                    .buttonStyle(.plain)

                    if index < vm.durationSetValues.indices.last ?? 0 {
                        Divider()
                            .overlay(FMFColors.surfaceOverlay.opacity(0.35))
                            .padding(.leading, FMFSpacing.xs)
                    }
                }
            }
        }
        .padding(FMFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FMFRadius.lg)
                .fill(FMFColors.surfaceMid)
                .overlay {
                    RoundedRectangle(cornerRadius: FMFRadius.lg)
                        .strokeBorder(accentColor.opacity(0.14), lineWidth: 1)
                }
        )
    }
}

private struct DurationSetRow: View {
    let title: String
    let valueText: String
    let accentColor: Color
    let accessibilityPrefix: String

    var body: some View {
        HStack(spacing: FMFSpacing.md) {
            Text(title)
                .font(FMFTypography.titleSmall)
                .foregroundStyle(FMFColors.neutral300)
                .accessibilityIdentifier("\(accessibilityPrefix).label")

            Spacer()

            Text(valueText)
                .font(FMFTypography.titleMedium)
                .foregroundStyle(.white)
                .monospacedDigit()
                .accessibilityIdentifier("\(accessibilityPrefix).value")

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accentColor.opacity(0.7))
        }
        .padding(.vertical, FMFSpacing.sm + 2)
    }
}

// MARK: - Wheel picker sheet

private struct MetricPickerSheet: View {
    let title: String
    let range: ClosedRange<Int>
    let value: Int
    let label: (Int) -> String
    let onCommit: (Int) -> Void

    @State private var selection: Int
    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        range: ClosedRange<Int>,
        value: Int,
        label: @escaping (Int) -> String,
        onCommit: @escaping (Int) -> Void
    ) {
        self.title = title
        self.range = range
        self.value = value
        self.label = label
        self.onCommit = onCommit
        _selection = State(initialValue: value)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(FMFTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()

                Button(String(localized: "pickerDoneButton")) {
                    onCommit(selection)
                    dismiss()
                }
                .font(FMFTypography.titleSmall.bold())
                .foregroundStyle(FMFColors.brandPrimary)
            }
            .padding(.horizontal, FMFSpacing.lg)
            .padding(.top, FMFSpacing.lg)
            .padding(.bottom, FMFSpacing.sm)

            Picker(title, selection: $selection) {
                ForEach(range, id: \.self) { i in
                    Text(label(i)).tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .background(FMFColors.surfaceMid)
    }
}
