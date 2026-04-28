import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class WorkoutViewModel {
    // Exposed state
    var state: WorkoutState = .modeSelection
    private(set) var captureSession: AVCaptureSession?
    var repCount = 0

    // Private
    private let skillId: String
    private let prescriptionType: PrescriptionType
    private let completionService: any PracticeSessionCompleting
    private let plannedSession: PlannedSession?
    private let supportsSmartTracking: Bool
    private let sessionDraft: PracticeSessionDraft?
    private let voiceCommandService: (any VoiceCommandListening)?
    private let soundPlayer: any WorkoutSoundPlaying
    private let timingConfiguration: WorkoutTimingConfiguration
    private var poseService: PoseDetectionService?
    private var activeVoiceCommandService: (any VoiceCommandListening)?
    private var poseStreamTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var gracePeriodTask: Task<Void, Never>?
    private var sessionStart: Date?
    var elapsed = 0 // internal for test seam
    private var mode: WorkoutMode = .smart
    private var completedTimerSetDurations: [Int] = []
    private var guidedTimerEffectiveRestSeconds = 0

    init(
        skillId: String,
        prescriptionType: PrescriptionType,
        completionService: any PracticeSessionCompleting,
        plannedSession: PlannedSession? = nil,
        supportsSmartTracking: Bool = true,
        sessionDraft: PracticeSessionDraft? = nil,
        voiceCommandService: (any VoiceCommandListening)? = nil,
        soundPlayer: (any WorkoutSoundPlaying)? = nil,
        timingConfiguration: WorkoutTimingConfiguration = .standard
    ) {
        self.skillId = skillId
        self.prescriptionType = prescriptionType
        self.completionService = completionService
        self.plannedSession = plannedSession
        self.supportsSmartTracking = supportsSmartTracking
        self.sessionDraft = sessionDraft
        self.voiceCommandService = voiceCommandService
        self.soundPlayer = soundPlayer ?? NoOpWorkoutSoundPlayer()
        self.timingConfiguration = timingConfiguration
    }

    var allowsManualMode: Bool {
        prescriptionType == .duration
    }

    var allowsSoundMode: Bool {
        prescriptionType == .duration
    }

    var usesRepCounting: Bool {
        prescriptionType == .reps
    }

    var modeUsesCamera: Bool {
        mode == .smart
    }

    var modeUsesVoiceCommands: Bool {
        mode == .sound
    }

    var modeUsesGuidedTimer: Bool {
        mode == .timer
    }

    var shouldShowManualStart: Bool {
        mode == .timer && allowsManualMode
    }

    var displaySeconds: Int {
        switch state {
        case .countdown(let secondsRemaining, _):
            return secondsRemaining
        case .resting(let secondsRemaining, _):
            return secondsRemaining
        default:
            return state.elapsedSeconds
        }
    }

    var idleStatusLabel: String {
        switch mode {
        case .timer:
            return String(localized: "workout_status_ready")
        case .smart:
            return String(localized: "workout_status_scanning")
        case .sound:
            return String(localized: "workout_status_listening")
        }
    }

    var statusHint: String {
        if usesRepCounting {
            return String(localized: "workout_auto_count_reps_hint")
        }
        switch mode {
        case .timer:
            return timerHint
        case .smart:
            return String(localized: "workout_auto_detect_hint")
        case .sound:
            return String(localized: "workout_sound_hint")
        }
    }

    // MARK: - Mode selection

    func selectMode(_ mode: WorkoutMode) async {
        guard mode != .timer || allowsManualMode else { return }
        guard mode != .sound || allowsSoundMode else { return }
        guard mode != .smart || supportsSmartTracking else {
            transitionToError(message: String(localized: "workout_error_smart_unavailable"))
            return
        }
        self.mode = mode
        switch mode {
        case .timer:
            enterTimerMode()
        case .smart:
            await initCamera()
        case .sound:
            await initVoiceCommands()
        }
    }

    private func enterTimerMode() {
        cleanup()
        repCount = 0
        elapsed = 0
        sessionStart = nil
        completedTimerSetDurations = []
        guidedTimerEffectiveRestSeconds = 0
        state = .idle
    }

    // MARK: - Camera init

    private func initCamera() async {
        #if targetEnvironment(simulator)
        repCount = 0
        elapsed = 0
        sessionStart = nil
        state = .idle
        #else
        // Request camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            transitionToError(message: String(localized: "workout_error_camera_denied"))
            return
        }

        let service = PoseDetectionService(trackingType: trackingType)
        poseService = service

        let ready = await service.configure()

        if !ready && mode == .smart {
            transitionToError(message: String(localized: "workout_error_no_camera"))
            return
        }

        captureSession = service.captureSession
        state = .idle

        if mode == .smart {
            let stream = service.stream()
            poseStreamTask = Task { [weak self] in
                for await event in stream {
                    guard let self else { return }
                    await self.handlePoseEvent(event)
                }
            }
        }
        #endif
    }

    private func initVoiceCommands() async {
        cleanup()
        repCount = 0
        elapsed = 0
        sessionStart = nil
        completedTimerSetDurations = []
        guidedTimerEffectiveRestSeconds = 0

        let service = voiceCommandService ?? SpeechVoiceCommandService()
        activeVoiceCommandService = service
        let granted = await service.requestPermissions()
        guard granted else {
            activeVoiceCommandService = nil
            transitionToError(message: String(localized: "workout_error_sound_denied"))
            return
        }

        do {
            try await service.startListening { [weak self] command in
                self?.handleVoiceCommand(command)
            }
            state = .idle
        } catch let error as VoiceCommandError {
            activeVoiceCommandService = nil
            transitionToError(message: voiceCommandErrorMessage(error))
        } catch {
            activeVoiceCommandService = nil
            transitionToError(message: String(localized: "workout_error_sound_unavailable"))
        }
    }

    // MARK: - Manual controls

    func manualStart() {
        guard case .idle = state else { return }
        if mode == .timer {
            startGuidedTimer()
            return
        }

        cancelGracePeriod()
        sessionStart = sessionStart ?? Date()
        startTicker()
        state = .active(elapsedSeconds: elapsed)
    }

    func stopSession() async {
        cancelTicker()
        cancelGracePeriod()
        let total = elapsed
        await saveSession()
        if mode != .sound {
            soundPlayer.play(.sessionComplete)
        }
        state = .complete(totalSeconds: total)
    }

    // MARK: - Pose events (called from poseStreamTask on main actor via await)

    func handlePoseEvent(_ event: PoseEvent) async {
        switch event {
        case .holdDetected(let isHandstand):
            if isHandstand {
                onHandstandDetected()
            } else {
                onPoseLost()
            }
        case .repCount(let count):
            onRepCountDetected(count)
        }
    }

    private var trackingType: PoseTrackingType {
        if prescriptionType == .duration {
            return .handstandHold
        }
        if skillId == "handstand_pushups" {
            return .handstandPushupReps
        }
        return .pullupReps
    }

    func onHandstandDetected() {
        cancelGracePeriod()
        if case .paused = state {
            startTicker()
            state = .active(elapsedSeconds: elapsed)
            soundPlayer.play(.poseResumed)
            return
        }
        guard case .active = state else {
            sessionStart = sessionStart ?? Date()
            startTicker()
            state = .active(elapsedSeconds: elapsed)
            soundPlayer.play(.poseAcquired)
            return
        }
    }

    func onPoseLost() {
        guard case .active = state else { return }
        guard gracePeriodTask == nil else { return }
        state = .paused(elapsedSeconds: elapsed)
        soundPlayer.play(.poseLostWarning)
        gracePeriodTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(timingConfiguration.gracePeriodSeconds))
            guard !Task.isCancelled else { return }
            self.cancelTicker()
            let total = self.elapsed
            await self.saveSession()
            if self.mode == .smart {
                self.soundPlayer.play(.sessionComplete)
            }
            self.state = .complete(totalSeconds: total)
        }
    }

    func onRepCountDetected(_ count: Int) {
        guard count > repCount else { return }
        repCount = count
        cancelGracePeriod()
        guard case .active = state else {
            sessionStart = sessionStart ?? Date()
            startTicker()
            state = .active(elapsedSeconds: elapsed)
            soundPlayer.play(.poseAcquired)
            soundPlayer.play(.repCounted)
            return
        }
        soundPlayer.play(.repCounted)
    }

    private func handleVoiceCommand(_ command: VoiceCommand) {
        switch command {
        case .start:
            manualStart()
        case .stop:
            guard case .active = state else { return }
            Task { await stopSession() }
        }
    }

    // MARK: - Timer

    private var timerHint: String {
        switch state {
        case .idle:
            return String(localized: "workout_timer_sequence_hint")
        case .countdown(_, .initialCountdown):
            return String(localized: "workout_timer_initial_countdown_hint")
        case .countdown(_, .setCountdown(let setNumber)):
            let format = String(localized: "workout_timer_next_set_hint")
            return String(format: format, setNumber)
        case .active:
            return String(localized: "workout_timer_work_hint")
        case .resting(_, let nextSetNumber):
            let format = String(localized: "workout_timer_rest_hint")
            return String(format: format, nextSetNumber)
        default:
            return String(localized: "workout_manual_start_hint")
        }
    }

    private func startGuidedTimer() {
        guard let sessionDraft, prescriptionType == .duration else {
            sessionStart = sessionStart ?? Date()
            startTicker()
            state = .active(elapsedSeconds: elapsed)
            return
        }

        cancelTicker()
        cancelGracePeriod()
        completedTimerSetDurations = []
        guidedTimerEffectiveRestSeconds = 0
        elapsed = 0
        repCount = 0
        sessionStart = Date()

        timerTask = Task { [weak self] in
            guard let self else { return }
            await self.runGuidedTimer(using: sessionDraft)
        }
    }

    private func runGuidedTimer(using draft: PracticeSessionDraft) async {
        let durations = draft.durationSetValues.isEmpty
            ? Array(repeating: max(1, draft.targetValuePerSet), count: max(1, draft.setsCompleted))
            : draft.durationSetValues

        let started = await runCountdown(
            seconds: timingConfiguration.initialGetReadySeconds,
            phase: .initialCountdown
        )
        guard started else { return }

        for (index, duration) in durations.enumerated() {
            let setNumber = index + 1

            if index > 0 {
                let getReady = await runCountdown(
                    seconds: timingConfiguration.betweenSetsGetReadySeconds,
                    phase: .setCountdown(setNumber: setNumber)
                )
                guard getReady else { return }
                guidedTimerEffectiveRestSeconds += timingConfiguration.betweenSetsGetReadySeconds
            }

            let worked = await runWorkSet(seconds: duration, setNumber: setNumber)
            guard worked else { return }
            completedTimerSetDurations.append(duration)

            if index < durations.count - 1, draft.restSeconds > 0 {
                let rested = await runRest(seconds: draft.restSeconds, nextSetNumber: setNumber + 1)
                guard rested else { return }
                guidedTimerEffectiveRestSeconds += draft.restSeconds
            }
        }

        await saveSession()
        soundPlayer.play(.sessionComplete)
        state = .complete(totalSeconds: elapsed)
    }

    func runCountdown(seconds: Int, phase: WorkoutTimerPhase) async -> Bool {
        guard seconds > 0 else { return true }

        for remaining in stride(from: seconds, through: 1, by: -1) {
            guard !Task.isCancelled else { return false }
            soundPlayer.play(countdownEffect(for: remaining))
            state = .countdown(secondsRemaining: remaining, phase: phase)
            try? await Task.sleep(for: .seconds(1))
        }

        guard !Task.isCancelled else { return false }
        soundPlayer.play(.countdownGo)
        return !Task.isCancelled
    }

    func runWorkSet(seconds: Int, setNumber: Int) async -> Bool {
        guard seconds > 0 else { return true }
        soundPlayer.play(.workStart)

        for remaining in stride(from: seconds, through: 1, by: -1) {
            guard !Task.isCancelled else { return false }
            elapsed += 1
            state = .active(elapsedSeconds: remaining)
            try? await Task.sleep(for: .seconds(1))
        }

        return !Task.isCancelled
    }

    func runRest(seconds: Int, nextSetNumber: Int) async -> Bool {
        guard seconds > 0 else { return true }
        soundPlayer.play(.restStart)

        for remaining in stride(from: seconds, through: 1, by: -1) {
            guard !Task.isCancelled else { return false }
            state = .resting(secondsRemaining: remaining, nextSetNumber: nextSetNumber)
            try? await Task.sleep(for: .seconds(1))
        }

        return !Task.isCancelled
    }

    private func startTicker() {
        cancelTicker()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                self.elapsed += 1
                if case .active = self.state {
                    self.state = .active(elapsedSeconds: self.elapsed)
                }
            }
        }
    }

    private func cancelTicker() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func cancelGracePeriod() {
        gracePeriodTask?.cancel()
        gracePeriodTask = nil
    }

    // MARK: - Session persistence

    private func saveSession() async {
        let score = prescriptionType == .duration ? elapsed : repCount
        guard score > 0 else { return }
        let session: PracticeSession

        if let sessionDraft {
            if mode == .timer, prescriptionType == .duration {
                session = sessionDraft.makeTimerExecutedSession(
                    completedDurations: completedTimerSetDurations,
                    totalSessionSeconds: elapsed + guidedTimerEffectiveRestSeconds,
                    date: sessionStart ?? Date(),
                    completedAt: Date()
                )
            } else {
                session = sessionDraft.makeExecutedSession(
                    mode: mode,
                    elapsedSeconds: elapsed,
                    repCount: repCount,
                    date: sessionStart ?? Date(),
                    completedAt: Date()
                )
            }
        } else {
            session = PracticeSession(
                id: UUID().uuidString,
                skillId: skillId,
                date: sessionStart ?? Date(),
                durationMinutes: max(1, elapsed / 60),
                notes: sessionNotes(score: score),
                completedAt: Date(),
                setsCompleted: plannedSession?.prescription.sets ?? 1,
                plannedSessionId: plannedSession?.id,
                isPersonalRecord: false,
                sessionScore: score
            )
        }
        _ = try? await completionService.completeSession(session)
    }

    private func sessionNotes(score: Int) -> String {
        if prescriptionType == .duration {
            return "\(score) sec"
        }
        return "\(score) reps in \(elapsed) sec"
    }

    // MARK: - Cleanup

    func cleanup() {
        poseStreamTask?.cancel()
        timerTask?.cancel()
        gracePeriodTask?.cancel()
        poseService?.stop()
        activeVoiceCommandService?.stopListening()
        activeVoiceCommandService = nil
        poseService = nil
        captureSession = nil
        completedTimerSetDurations = []
        guidedTimerEffectiveRestSeconds = 0
    }

    private func voiceCommandErrorMessage(_ error: VoiceCommandError) -> String {
        switch error {
        case .permissionsDenied:
            return String(localized: "workout_error_sound_denied")
        case .recognizerUnavailable, .audioSetupFailed:
            return String(localized: "workout_error_sound_unavailable")
        }
    }

    func countdownEffect(for remaining: Int) -> WorkoutSoundEffect {
        remaining <= 3 ? .countdownFinalTick : .countdownTick
    }

    private func transitionToError(message: String) {
        state = .error(message: message)
        soundPlayer.play(.error)
    }
}
