import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class WorkoutViewModel {
    private static let gracePeriodSeconds = 3

    // Exposed state
    internal(set) var state: WorkoutState = .modeSelection
    private(set) var captureSession: AVCaptureSession?

    // Private
    private let skillId: String
    private let repo: any PracticeSessionRepository
    private var poseService: PoseDetectionService?
    private var poseStreamTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var gracePeriodTask: Task<Void, Never>?
    private var sessionStart: Date?
    var elapsed = 0 // internal for test seam
    private var mode: WorkoutMode = .smart

    init(skillId: String, repo: any PracticeSessionRepository) {
        self.skillId = skillId
        self.repo = repo
    }

    // MARK: - Mode selection

    func selectMode(_ mode: WorkoutMode) async {
        self.mode = mode
        await initCamera()
    }

    // MARK: - Camera init

    private func initCamera() async {
        // Request camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            state = .error(message: "Camera access denied")
            return
        }

        let service = PoseDetectionService()
        poseService = service
        let stream = service.start()

        // Check if session was created (nil = simulator / no camera)
        try? await Task.sleep(for: .milliseconds(300))
        if service.captureSession == nil && mode == .smart {
            state = .error(message: "No camera available")
            return
        }

        captureSession = service.captureSession
        state = .idle

        if mode == .smart {
            poseStreamTask = Task { [weak self] in
                for await isHandstand in stream {
                    guard let self else { return }
                    await self.handlePoseEvent(isHandstand)
                }
            }
        }
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

    private func handlePoseEvent(_ isHandstand: Bool) async {
        if isHandstand {
            onHandstandDetected()
        } else {
            onPoseLost()
        }
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
        guard elapsed > 0 else { return }
        let session = PracticeSession(
            id: UUID().uuidString,
            skillId: skillId,
            date: sessionStart ?? Date(),
            durationMinutes: max(1, elapsed / 60),
            notes: "\(elapsed) sec",
            completedAt: Date()
        )
        try? await repo.logSession(session)
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
