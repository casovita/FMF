import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class WorkoutViewModel {
    private static let gracePeriodSeconds = 3

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
    private var poseService: PoseDetectionService?
    private var poseStreamTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var gracePeriodTask: Task<Void, Never>?
    private var sessionStart: Date?
    var elapsed = 0 // internal for test seam
    private var mode: WorkoutMode = .smart

    init(
        skillId: String,
        prescriptionType: PrescriptionType,
        completionService: any PracticeSessionCompleting,
        plannedSession: PlannedSession? = nil,
        supportsSmartTracking: Bool = true
    ) {
        self.skillId = skillId
        self.prescriptionType = prescriptionType
        self.completionService = completionService
        self.plannedSession = plannedSession
        self.supportsSmartTracking = supportsSmartTracking
    }

    var allowsManualMode: Bool {
        prescriptionType == .duration
    }

    var usesRepCounting: Bool {
        prescriptionType == .reps
    }

    var shouldShowManualStart: Bool {
        mode == .manual && allowsManualMode
    }

    var statusHint: String {
        if usesRepCounting {
            return String(localized: "workout_auto_count_reps_hint")
        }
        return mode == .manual
            ? String(localized: "workout_manual_start_hint")
            : String(localized: "workout_auto_detect_hint")
    }

    // MARK: - Mode selection

    func selectMode(_ mode: WorkoutMode) async {
        guard mode != .manual || allowsManualMode else { return }
        guard mode != .smart || supportsSmartTracking else {
            state = .error(message: String(localized: "workout_error_smart_unavailable"))
            return
        }
        self.mode = mode
        switch mode {
        case .manual:
            enterManualMode()
        case .smart:
            await initCamera()
        }
    }

    private func enterManualMode() {
        cleanup()
        repCount = 0
        elapsed = 0
        sessionStart = nil
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
            state = .error(message: String(localized: "workout_error_camera_denied"))
            return
        }

        let service = PoseDetectionService(trackingType: trackingType)
        poseService = service

        let ready = await service.configure()

        if !ready && mode == .smart {
            state = .error(message: String(localized: "workout_error_no_camera"))
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

    // MARK: - Manual controls

    func manualStart() {
        guard case .idle = state else { return }
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
        state = .complete(totalSeconds: total)
    }

    // MARK: - Pose events (called from poseStreamTask on main actor via await)

    private func handlePoseEvent(_ event: PoseEvent) async {
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

    private func onHandstandDetected() {
        cancelGracePeriod()
        guard case .active = state else {
            sessionStart = sessionStart ?? Date()
            startTicker()
            state = .active(elapsedSeconds: elapsed)
            return
        }
    }

    private func onPoseLost() {
        guard case .active = state else { return }
        guard gracePeriodTask == nil else { return }
        state = .paused(elapsedSeconds: elapsed)
        gracePeriodTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(Self.gracePeriodSeconds))
            guard !Task.isCancelled else { return }
            self.cancelTicker()
            let total = self.elapsed
            await self.saveSession()
            self.state = .complete(totalSeconds: total)
        }
    }

    private func onRepCountDetected(_ count: Int) {
        repCount = count
        cancelGracePeriod()
        guard case .active = state else {
            sessionStart = sessionStart ?? Date()
            startTicker()
            state = .active(elapsedSeconds: elapsed)
            return
        }
    }

    // MARK: - Timer

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
        let session = PracticeSession(
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
        poseService = nil
        captureSession = nil
    }
}
