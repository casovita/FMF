import SwiftUI
import AVFoundation

struct WorkoutView: View {
    let skillId: String
    let plannedSession: PlannedSession?
    let sessionDraft: PracticeSessionDraft?
    let initialMode: WorkoutMode?
    let onSessionFinished: (() -> Void)?

    @Environment(\.practiceSessionRepository) private var repo
    @Environment(\.skillRepository) private var skillRepo
    @Environment(\.trainingProgramRepository) private var trainingProgramRepo
    @Environment(\.workoutSoundPlayer) private var workoutSoundPlayer
    @Environment(\.dismiss) private var dismiss
    @State private var vm: WorkoutViewModel?
    @State private var skill: Skill?

    init(
        skillId: String,
        plannedSession: PlannedSession? = nil,
        sessionDraft: PracticeSessionDraft? = nil,
        initialMode: WorkoutMode? = nil,
        onSessionFinished: (() -> Void)? = nil
    ) {
        self.skillId = skillId
        self.plannedSession = plannedSession
        self.sessionDraft = sessionDraft
        self.initialMode = initialMode
        self.onSessionFinished = onSessionFinished
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
                            onSessionFinished?()
                        }
                    }
            } else {
                ProgressView().tint(FMFColors.brandPrimary)
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
                supportsSmartTracking: loadedSkill.map(supportsSmartTracking(for:)) ?? false,
                sessionDraft: sessionDraft,
                soundPlayer: workoutSoundPlayer
            )
            if let initialMode {
                await viewModel.selectMode(initialMode)
            }
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
            WorkoutCameraView(vm: vm, skill: skill, dismiss: { dismiss() })
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
                FMFColors.background.ignoresSafeArea()

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
                            color: FMFColors.brandPrimary
                        ) { onSelect(.manual) }

                        Spacer().frame(height: FMFSpacing.md)

                        ModeCard(
                            accessibilityIdentifier: "workout.mode.sound",
                            systemImage: "waveform.and.mic",
                            title: String(localized: "workout_mode_sound_title"),
                            subtitle: String(localized: "workout_mode_sound_subtitle"),
                            color: FMFColors.skillStrength
                        ) { onSelect(.sound) }
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
    let skill: Skill?
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            // Camera layer
            if let session = vm.captureSession, vm.modeUsesCamera {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else if vm.modeUsesGuidedTimer {
                if vm.isRepManualMode {
                    RepManualPlaceholder(vm: vm)
                } else {
                    GuidedTimerPlaceholder(vm: vm)
                }
            } else if vm.modeUsesVoiceCommands {
                VoiceCommandPlaceholder(vm: vm)
            } else {
                ScanningPlaceholder(vm: vm)
            }

            if vm.modeUsesCamera {
                CameraPositionGuide(skill: skill)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
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
        .sheet(isPresented: Binding(
            get: { vm.repEntryPending },
            set: { isPresented in
                if !isPresented && vm.repEntryPending {
                    vm.cancelRepEntry()
                }
            }
        )) {
            RepSetEntrySheet(vm: vm)
        }
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

struct WorkoutCameraGuideMarker: Identifiable {
    let id: String
    let systemImage: String
    let labelKey: LocalizedStringResource
    let normalizedX: CGFloat
    let normalizedY: CGFloat
}

struct WorkoutCameraGuideSpec {
    let badgeTitle: String
    let titleKey: LocalizedStringResource
    let subtitleKey: LocalizedStringResource
    let markers: [WorkoutCameraGuideMarker]
    let frameWidthRatio: CGFloat
    let frameHeightRatio: CGFloat
    let frameOffsetY: CGFloat
}

func cameraGuideSpec(for skill: Skill?) -> WorkoutCameraGuideSpec {
    let skillName = skill?.name ?? String(localized: "workout_camera_guide_generic_badge")

    switch skill?.id {
    case "handstand":
        return WorkoutCameraGuideSpec(
            badgeTitle: skillName,
            titleKey: "workout_camera_guide_title",
            subtitleKey: "workout_camera_guide_handstand_subtitle",
            markers: [
                WorkoutCameraGuideMarker(
                    id: "hands",
                    systemImage: "hand.raised",
                    labelKey: "workout_camera_guide_handstand_hands",
                    normalizedX: 0.5,
                    normalizedY: 0.84
                ),
                WorkoutCameraGuideMarker(
                    id: "hips",
                    systemImage: "arrow.up.and.down",
                    labelKey: "workout_camera_guide_handstand_hips",
                    normalizedX: 0.5,
                    normalizedY: 0.5
                ),
                WorkoutCameraGuideMarker(
                    id: "toes",
                    systemImage: "figure.flexibility",
                    labelKey: "workout_camera_guide_handstand_toes",
                    normalizedX: 0.5,
                    normalizedY: 0.12
                )
            ],
            frameWidthRatio: 0.62,
            frameHeightRatio: 0.62,
            frameOffsetY: -24
        )
    case "pullups":
        return WorkoutCameraGuideSpec(
            badgeTitle: skillName,
            titleKey: "workout_camera_guide_title",
            subtitleKey: "workout_camera_guide_pullups_subtitle",
            markers: [
                WorkoutCameraGuideMarker(
                    id: "bar",
                    systemImage: "line.3.horizontal",
                    labelKey: "workout_camera_guide_pullups_bar",
                    normalizedX: 0.5,
                    normalizedY: 0.08
                ),
                WorkoutCameraGuideMarker(
                    id: "chest",
                    systemImage: "figure.strengthtraining.traditional",
                    labelKey: "workout_camera_guide_pullups_chest",
                    normalizedX: 0.5,
                    normalizedY: 0.34
                ),
                WorkoutCameraGuideMarker(
                    id: "feet",
                    systemImage: "figure.walk",
                    labelKey: "workout_camera_guide_pullups_feet",
                    normalizedX: 0.5,
                    normalizedY: 0.7
                )
            ],
            frameWidthRatio: 0.66,
            frameHeightRatio: 0.54,
            frameOffsetY: -72
        )
    case "handstand_pushups":
        return WorkoutCameraGuideSpec(
            badgeTitle: skillName,
            titleKey: "workout_camera_guide_title",
            subtitleKey: "workout_camera_guide_hspu_subtitle",
            markers: [
                WorkoutCameraGuideMarker(
                    id: "hands",
                    systemImage: "hand.raised",
                    labelKey: "workout_camera_guide_hspu_hands",
                    normalizedX: 0.5,
                    normalizedY: 0.84
                ),
                WorkoutCameraGuideMarker(
                    id: "head",
                    systemImage: "person.crop.circle",
                    labelKey: "workout_camera_guide_hspu_head",
                    normalizedX: 0.5,
                    normalizedY: 0.54
                ),
                WorkoutCameraGuideMarker(
                    id: "toes",
                    systemImage: "figure.flexibility",
                    labelKey: "workout_camera_guide_hspu_toes",
                    normalizedX: 0.5,
                    normalizedY: 0.14
                )
            ],
            frameWidthRatio: 0.62,
            frameHeightRatio: 0.64,
            frameOffsetY: -32
        )
    default:
        return WorkoutCameraGuideSpec(
            badgeTitle: skillName,
            titleKey: "workout_camera_guide_title",
            subtitleKey: "workout_camera_guide_subtitle",
            markers: [
                WorkoutCameraGuideMarker(
                    id: "head",
                    systemImage: "person.crop.circle",
                    labelKey: "workout_camera_guide_head",
                    normalizedX: 0.5,
                    normalizedY: 0.1
                ),
                WorkoutCameraGuideMarker(
                    id: "center",
                    systemImage: "arrow.up.and.down",
                    labelKey: "workout_camera_guide_midline",
                    normalizedX: 0.5,
                    normalizedY: 0.5
                ),
                WorkoutCameraGuideMarker(
                    id: "feet",
                    systemImage: "figure.walk",
                    labelKey: "workout_camera_guide_feet",
                    normalizedX: 0.5,
                    normalizedY: 0.92
                )
            ],
            frameWidthRatio: 0.62,
            frameHeightRatio: 0.62,
            frameOffsetY: -24
        )
    }
}

private struct CameraPositionGuide: View {
    let skill: Skill?

    var body: some View {
        GeometryReader { proxy in
            let spec = cameraGuideSpec(for: skill)
            let width = proxy.size.width
            let height = proxy.size.height
            let guideWidth = min(width * spec.frameWidthRatio, 300)
            let guideHeight = min(height * spec.frameHeightRatio, 520)
            let guideRect = CGRect(
                x: (width - guideWidth) / 2,
                y: max(100, (height - guideHeight) / 2 + spec.frameOffsetY),
                width: guideWidth,
                height: guideHeight
            )

            ZStack {
                RoundedRectangle(cornerRadius: 34)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [12, 10])
                    )
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: guideRect.width, height: guideRect.height)
                    .position(x: guideRect.midX, y: guideRect.midY)

                Path { path in
                    path.move(to: CGPoint(x: guideRect.midX, y: guideRect.minY + 18))
                    path.addLine(to: CGPoint(x: guideRect.midX, y: guideRect.maxY - 18))
                }
                .stroke(.white.opacity(0.24), style: StrokeStyle(lineWidth: 1, dash: [6, 8]))

                guideBadge(title: spec.badgeTitle)
                    .position(x: guideRect.midX, y: guideRect.minY - 16)

                ForEach(spec.markers) { marker in
                    guideMarker(
                        systemImage: marker.systemImage,
                        label: String(localized: marker.labelKey)
                    )
                    .position(
                        x: guideRect.minX + (guideRect.width * marker.normalizedX),
                        y: guideRect.minY + (guideRect.height * marker.normalizedY)
                    )
                }

                VStack(spacing: FMFSpacing.xs) {
                    Text(String(localized: spec.titleKey))
                        .font(FMFTypography.labelMedium)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.92))

                    Text(String(localized: spec.subtitleKey))
                        .font(FMFTypography.bodySmall)
                        .foregroundStyle(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, FMFSpacing.md)
                .padding(.vertical, FMFSpacing.sm)
                .background(.black.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: FMFRadius.md))
                .overlay {
                    RoundedRectangle(cornerRadius: FMFRadius.md)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                }
                .position(x: guideRect.midX, y: guideRect.maxY + 54)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func guideBadge(title: String) -> some View {
        Text(title)
            .font(FMFTypography.labelMedium)
            .fontWeight(.bold)
            .foregroundStyle(.white.opacity(0.94))
            .padding(.horizontal, FMFSpacing.md)
            .padding(.vertical, FMFSpacing.xs)
            .background(.black.opacity(0.32))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
    }

    @ViewBuilder
    private func guideMarker(systemImage: String, label: String) -> some View {
        HStack(spacing: FMFSpacing.xs) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(FMFTypography.labelSmall)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, FMFSpacing.sm)
        .padding(.vertical, 6)
        .background(.black.opacity(0.32))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct SafeAreaOverlay: View {
    let vm: WorkoutViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            StatusBadge(vm: vm)
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
    let vm: WorkoutViewModel

    private var labelAndColor: (String, Color) {
        let state = vm.state
        switch state {
        case .modeSelection:                 return ("", FMFColors.neutral300)
        case .idle:                          return (vm.idleStatusLabel, FMFColors.neutral300)
        case .countdown(_, let phase):
            switch phase {
            case .initialCountdown:
                return (String(localized: "workout_status_get_ready"), FMFColors.warning)
            case .setCountdown(let setNumber):
                let format = String(localized: "workout_status_set_ready_format")
                return (String(format: format, setNumber), FMFColors.warning)
            case .work(let setNumber):
                let format = String(localized: "workout_status_set_live_format")
                return (String(format: format, setNumber), FMFColors.skillBalance)
            case .rest(let nextSetNumber):
                let format = String(localized: "workout_status_rest_format")
                return (String(format: format, nextSetNumber), FMFColors.brandPrimary)
            }
        case .active:
            return (String(localized: "workout_status_active"), FMFColors.skillBalance)
        case .resting(_, let nextSetNumber):
            let format = String(localized: "workout_status_rest_format")
            return (String(format: format, nextSetNumber), FMFColors.brandPrimary)
        case .paused:                        return (String(localized: "workout_status_paused"), FMFColors.warning)
        case .complete:                      return (String(localized: "workout_status_done"), FMFColors.success)
        case .error(let msg):                return ("\(String(localized: "workout_status_error")) \(msg)", FMFColors.error)
        }
    }

    var body: some View {
        let (label, color) = labelAndColor
        let isActive = if case .active = vm.state { true } else { false }

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
        if vm.usesRepCounting && vm.modeUsesCamera {
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
            let seconds = vm.displaySeconds
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
                    let label = vm.isRepManualMode
                        ? String(format: String(localized: "workout_start_set_format"), vm.manualCurrentSet)
                        : String(localized: "workout_start_timer")
                    GlassPillButton(
                        label: label,
                        systemImage: "play.fill",
                        color: FMFColors.brandPrimary
                    ) { vm.manualStart() }
                }

                Text(vm.statusHint)
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(.white.opacity(0.4))
            }

        case .active where vm.isRepManualMode:
            GlassPillButton(
                label: String(localized: "workout_done_with_set"),
                systemImage: "checkmark",
                color: FMFColors.success
            ) { vm.doneWithSet() }

        case .countdown, .resting, .active, .paused:
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
            FMFColors.background.ignoresSafeArea()
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
                    .tint(FMFColors.brandPrimary)
                Text(String(localized: "workout_starting_camera"))
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral300)
                #endif
            }
        }
    }
}

private struct VoiceCommandPlaceholder: View {
    let vm: WorkoutViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FMFColors.background, FMFColors.surfaceLow],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: FMFSpacing.md) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 42))
                    .foregroundStyle(FMFColors.skillStrength)

                Text(String(localized: "workout_sound_ready_title"))
                    .font(FMFTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(vm.statusHint)
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral300)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FMFSpacing.xl)
            }
        }
    }
}

private struct GuidedTimerPlaceholder: View {
    let vm: WorkoutViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FMFColors.background, FMFColors.surfaceLow],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: FMFSpacing.md) {
                Image(systemName: "timer")
                    .font(.system(size: 42))
                    .foregroundStyle(FMFColors.brandPrimary)

                Text(String(localized: "workout_timer_ready_title"))
                    .font(FMFTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(vm.statusHint)
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral300)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FMFSpacing.xl)
            }
        }
    }
}

private struct RepManualPlaceholder: View {
    let vm: WorkoutViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FMFColors.background, FMFColors.surfaceLow],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: FMFSpacing.md) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 42))
                    .foregroundStyle(FMFColors.brandPrimary)

                Text(String(localized: "workout_rep_manual_ready_title"))
                    .font(FMFTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(vm.statusHint)
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral300)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FMFSpacing.xl)
            }
        }
    }
}

private struct RepSetEntrySheet: View {
    let vm: WorkoutViewModel

    @State private var reps: Int

    init(vm: WorkoutViewModel) {
        self.vm = vm
        _reps = State(initialValue: max(1, vm.manualTargetRepsPerSet))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: FMFSpacing.xl) {
                Text(String(format: String(localized: "workout_rep_entry_title_format"), vm.manualCurrentSet))
                    .font(FMFTypography.headlineSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top, FMFSpacing.xl)

                Stepper(
                    value: $reps,
                    in: 1...999
                ) {
                    HStack(alignment: .firstTextBaseline, spacing: FMFSpacing.xs) {
                        Text("\(reps)")
                            .font(.system(size: 56, weight: .bold).monospacedDigit())
                            .foregroundStyle(.white)
                        Text(String(localized: "workout_reps_label"))
                            .font(FMFTypography.bodyMedium)
                            .foregroundStyle(FMFColors.neutral500)
                    }
                }
                .padding(.horizontal, FMFSpacing.xl)

                Button {
                    Task { await vm.confirmRepSet(reps: reps) }
                } label: {
                    Text(String(localized: "workout_rep_entry_confirm"))
                        .font(FMFTypography.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(FMFSpacing.md)
                        .background(FMFColors.brandPrimary.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: FMFRadius.lg))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, FMFSpacing.lg)

                Spacer()
            }
            .atmosphericScreenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "workout_rep_entry_cancel")) {
                        vm.cancelRepEntry()
                    }
                    .foregroundStyle(FMFColors.neutral300)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
