import SwiftUI
import AVFoundation

struct WorkoutView: View {
    let skillId: String
    @Environment(\.practiceSessionRepository) private var repo
    @Environment(\.dismiss) private var dismiss
    @State private var vm: WorkoutViewModel?

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
                    .onChange(of: vm.state) { _, newState in
                        if case .complete(let total) = newState {
                            vm.cleanup()
                            dismiss()
                            // Toast shown by parent — pass total via notification or callback if needed
                            _ = total
                        }
                    }
            }
        }
        .task {
            let viewModel = WorkoutViewModel(skillId: skillId, repo: repo)
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
            ModeSelectionView { mode in
                Task { await vm.selectMode(mode) }
            }
        default:
            WorkoutCameraView(vm: vm, dismiss: { dismiss() })
        }
    }
}

// MARK: - Mode selection

private struct ModeSelectionView: View {
    let onSelect: (WorkoutMode) -> Void

    var body: some View {
        ZStack {
            Color(hex: 0x0D1628).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: FMFSpacing.xl)

                Text("Choose Timer Mode")
                    .font(FMFTypography.headlineSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: FMFSpacing.xs)

                Text("How do you want to track your session?")
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral500)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: FMFSpacing.xl)

                ModeCard(
                    systemImage: "sparkles",
                    title: "Smart",
                    subtitle: "Auto-detects your handstand via camera",
                    color: FMFColors.skillBalance
                ) { onSelect(.smart) }

                Spacer().frame(height: FMFSpacing.md)

                ModeCard(
                    systemImage: "hand.tap",
                    title: "Manual",
                    subtitle: "You control start & stop",
                    color: FMFColors.brandAccent
                ) { onSelect(.manual) }

                Spacer()
            }
            .padding(.horizontal, FMFSpacing.lg)
        }
    }
}

private struct ModeCard: View {
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
                ScanningPlaceholder()
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
            SafeAreaOverlay(vm: vm, dismiss: dismiss)
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

private struct SafeAreaOverlay: View {
    let vm: WorkoutViewModel
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                GlassIconButton(systemImage: "chevron.backward") { dismiss() }
                Spacer()
            }
            .padding(.horizontal, FMFSpacing.md)
            .padding(.top, FMFSpacing.sm)

            Spacer()

            StatusBadge(state: vm.state)
            Spacer().frame(height: FMFSpacing.md)
            TimerDisplay(state: vm.state)
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
        case .idle:                          return ("SCANNING...", FMFColors.neutral300)
        case .active:                        return ("HANDSTAND ●", FMFColors.skillBalance)
        case .paused:                        return ("PAUSED", FMFColors.warning)
        case .complete:                      return ("DONE", FMFColors.success)
        case .error(let msg):                return ("ERROR: \(msg)", FMFColors.error)
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
    }
}

// MARK: - Timer display

private struct TimerDisplay: View {
    let state: WorkoutState

    var body: some View {
        let seconds = state.elapsedSeconds
        let mm = String(format: "%02d", seconds / 60)
        let ss = String(format: "%02d", seconds % 60)

        Text("\(mm):\(ss)")
            .font(.system(size: 57, weight: .ultraLight).monospacedDigit())
            .tracking(6)
            .foregroundStyle(.white)
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
                GlassPillButton(
                    label: "Start Manually",
                    systemImage: "play.fill",
                    color: FMFColors.brandAccent
                ) { vm.manualStart() }

                Text("or go into a handstand — auto-detected")
                    .font(FMFTypography.bodySmall)
                    .foregroundStyle(.white.opacity(0.4))
            }

        case .active, .paused:
            GlassPillButton(
                label: "Stop & Save",
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
    }
}

private struct ScanningPlaceholder: View {
    var body: some View {
        ZStack {
            Color(hex: 0x0D1628).ignoresSafeArea()
            VStack(spacing: FMFSpacing.md) {
                ProgressView()
                    .tint(FMFColors.brandAccent)
                Text("Starting camera...")
                    .font(FMFTypography.bodyMedium)
                    .foregroundStyle(FMFColors.neutral300)
            }
        }
    }
}
