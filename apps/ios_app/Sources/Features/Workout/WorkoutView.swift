import SwiftUI
import AVFoundation

struct WorkoutView: View {
    let skillId: String
    let plannedSession: PlannedSession?

    @Environment(\.practiceSessionRepository) private var repo
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.dismiss) private var dismiss
    @State private var vm: WorkoutViewModel?
    @State private var skill: Skill?

    init(skillId: String, plannedSession: PlannedSession? = nil) {
        self.skillId = skillId
        self.plannedSession = plannedSession
    }

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
                    .onChange(of: vm.state) { _, newState in
                        if case .complete(let total) = newState {
                            vm.cleanup()
                            _ = total
                            dismiss()
                        }
                    }
            }
        }
        .task {
            let loadedSkill = try? await skillRepo.getSkillById(skillId)
            skill = loadedSkill
            let completionService = PracticeSessionCompletionService(
                sessionRepo: repo,
                skillRepo: skillRepo,
                trainingProgramRepo: trainingProgramRepo
            )
            let viewModel = WorkoutViewModel(
                skillId: skillId,
                prescriptionType: loadedSkill?.prescriptionType ?? .duration,
                completionService: completionService,
                plannedSession: plannedSession,
                supportsSmartTracking: loadedSkill.map(supportsSmartTracking(for:)) ?? false
            )
            vm = viewModel
        }
        .onDisappear {
            vm?.cleanup()
        }
    }

    @ViewBuilder
    private func content(vm: WorkoutViewModel) -> some View {
        switch vm.state {
        case .modeSelection:
            ModeSelectionView(
                showsSmartTracking: true,
                showsManualTracking: vm.allowsManualMode,
                onBack: { dismiss() }
            ) { mode in
                Task { await vm.selectMode(mode) }
            }
        default:
            WorkoutCameraView(vm: vm, dismiss: { dismiss() })
        }
    }

    private func supportsSmartTracking(for skill: Skill) -> Bool {
        switch skill.id {
        case "handstand", "pullups", "handstand_pushups":
            return true
        default:
            return false
        }
    }
}

// MARK: - Mode selection

private struct ModeSelectionView: View {
    let showsSmartTracking: Bool
    let showsManualTracking: Bool
    let onBack: () -> Void
    let onSelect: (WorkoutMode) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(hex: 0x0D1628).ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        GlassIconButton(
                            systemImage: "chevron.backward",
                            accessibilityIdentifier: "workout.backButton"
                        ) { onBack() }
                        Spacer()
                    }
                    .padding(.top, proxy.safeAreaInsets.top + FMFSpacing.sm)

                    Spacer().frame(height: FMFSpacing.lg)

                    Text(String(localized: "workout_mode_title"))
                        .font(FMFTypography.headlineSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: FMFSpacing.xs)

                    Text(String(localized: "workout_mode_subtitle"))
                        .font(FMFTypography.bodyMedium)
                        .foregroundStyle(FMFColors.neutral500)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: FMFSpacing.xl)

                    if showsSmartTracking {
                        ModeCard(
                            accessibilityIdentifier: "workout.mode.smart",
                            systemImage: "sparkles",
                            title: String(localized: "workout_mode_smart_title"),
                            subtitle: String(localized: "workout_mode_smart_subtitle"),
                            color: FMFColors.skillBalance
                        ) { onSelect(.smart) }

                        if showsManualTracking {
                            Spacer().frame(height: FMFSpacing.md)
                        }
                    }

                    if showsManualTracking {
                        ModeCard(
                            accessibilityIdentifier: "workout.mode.manual",
                            systemImage: "hand.tap",
                            title: String(localized: "workout_mode_manual_title"),
                            subtitle: String(localized: "workout_mode_manual_subtitle"),
                            color: FMFColors.brandAccent
                        ) { onSelect(.manual) }
                    } else {
                        Text(String(localized: "workout_mode_camera_only"))
                            .font(FMFTypography.bodySmall)
                            .foregroundStyle(FMFColors.neutral500)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding(.horizontal, FMFSpacing.lg)
            }
        }
    }
}

private struct ModeCard: View {
    let accessibilityIdentifier: String
    let systemImage: String
    let title: String
    let subtitle: String
    let color: Color
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
                        .font(.system(size: 26))
                        .foregroundStyle(color)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FMFTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(FMFColors.neutral500)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(color.opacity(0.6))
            }
            .padding(FMFSpacing.lg)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: FMFRadius.lg)
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Camera workout screen

private struct WorkoutCameraView: View {
    let vm: WorkoutViewModel
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            // Camera layer
            if let session = vm.captureSession {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else {
                ScanningPlaceholder(vm: vm)
            }

            // Top gradient
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                Spacer()
            }
            .ignoresSafeArea()

            // Bottom gradient
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
            }
            .ignoresSafeArea()

            // UI overlay
            SafeAreaOverlay(vm: vm)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .safeAreaInset(edge: .top) {
            HStack {
                GlassIconButton(
                    systemImage: "chevron.backward",
                    accessibilityIdentifier: "workout.backButton"
                ) { dismiss() }
                Spacer()
            }
            .padding(.horizontal, FMFSpacing.md)
            .padding(.top, FMFSpacing.sm)
        }
    }
}

private struct SafeAreaOverlay: View {
    let vm: WorkoutViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            StatusBadge(state: vm.state)
            Spacer().frame(height: FMFSpacing.md)
            WorkoutMetricDisplay(vm: vm)
            Spacer().frame(height: FMFSpacing.xl)
            ActionButtons(state: vm.state, vm: vm)
            Spacer().frame(height: 40)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Status badge

private struct StatusBadge: View {
    let state: WorkoutState

    private var labelAndColor: (String, Color) {
        switch state {
        case .modeSelection:                 return ("", FMFColors.neutral300)
        case .idle:                          return (String(localized: "workout_status_scanning"), FMFColors.neutral300)
        case .active:                        return (String(localized: "workout_status_active"), FMFColors.skillBalance)
        case .paused:                        return (String(localized: "workout_status_paused"), FMFColors.warning)
        case .complete:                      return (String(localized: "workout_status_done"), FMFColors.success)
        case .error(let msg):                return ("\(String(localized: "workout_status_error")) \(msg)", FMFColors.error)
        }
    }

    var body: some View {
        let (label, color) = labelAndColor
        let isActive = if case .active = state { true } else { false }

        Text(label)
            .font(FMFTypography.labelMedium)
            .fontWeight(.bold)
            .tracking(1.4)
            .foregroundStyle(color)
            .padding(.horizontal, FMFSpacing.md)
            .padding(.vertical, FMFSpacing.xs)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay { Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1) }
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: 20)
            .accessibilityIdentifier("workout.camera.status")
    }
}

// MARK: - Timer display

private struct WorkoutMetricDisplay: View {
    let vm: WorkoutViewModel

    var body: some View {
        if vm.usesRepCounting {
            VStack(spacing: 8) {
                Text("\(vm.repCount)")
                    .font(.system(size: 64, weight: .bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text(String(localized: "workout_reps_label"))
                    .font(FMFTypography.labelMedium)
                    .foregroundStyle(FMFColors.neutral300)
            }
            .accessibilityIdentifier("workout.camera.metric")
        } else {
            let seconds = vm.state.elapsedSeconds
            let mm = String(format: "%02d", seconds / 60)
            let ss = String(format: "%02d", seconds % 60)

            Text("\(mm):\(ss)")
                .font(.system(size: 57, weight: .ultraLight).monospacedDigit())
                .tracking(6)
                .foregroundStyle(.white)
                .accessibilityIdentifier("workout.camera.metric")
        }
    }
}

// MARK: - Action buttons

private struct ActionButtons: View {
    let state: WorkoutState
    let vm: WorkoutViewModel

    var body: some View {
        switch state {
        case .idle:
            VStack(spacing: FMFSpacing.sm) {
                if vm.shouldShowManualStart {
                    GlassPillButton(
                        label: String(localized: "workout_start_manual"),
                        systemImage: "play.fill",
                        color: FMFColors.brandAccent
                    ) { vm.manualStart() }
                }

                Text(vm.statusHint)
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(.white.opacity(0.4))
            }

        case .active, .paused:
            GlassPillButton(
                label: String(localized: "workout_stop_save"),
                systemImage: "stop.fill",
                color: FMFColors.error
            ) { Task { await vm.stopSession() } }

        default:
            EmptyView()
        }
    }
}

// MARK: - Glass widgets

private struct GlassPillButton: View {
    let label: String
    let systemImage: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FMFSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                Text(label)
                    .font(FMFTypography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, FMFSpacing.xl)
            .padding(.vertical, FMFSpacing.md)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
            .overlay { Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1) }
            .shadow(color: color.opacity(0.3), radius: 20)
        }
        .buttonStyle(.plain)
    }
}

private struct GlassIconButton: View {
    let systemImage: String
    let accessibilityIdentifier: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: FMFRadius.sm))
                .overlay {
                    RoundedRectangle(cornerRadius: FMFRadius.sm)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}

private struct ScanningPlaceholder: View {
    let vm: WorkoutViewModel

    var body: some View {
        ZStack {
            Color(hex: 0x0D1628).ignoresSafeArea()
            VStack(spacing: FMFSpacing.md) {
                #if targetEnvironment(simulator)
                Image(systemName: "camera.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(FMFColors.neutral500)
                Text(String(localized: "workout_no_camera_simulator"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral300)
                Text(vm.allowsManualMode ? String(localized: "workout_use_manual") : String(localized: "workout_camera_required"))
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(FMFColors.neutral500)
                #else
                ProgressView()
                    .tint(FMFColors.brandAccent)
                Text(String(localized: "workout_starting_camera"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral300)
                #endif
            }
        }
    }
}
