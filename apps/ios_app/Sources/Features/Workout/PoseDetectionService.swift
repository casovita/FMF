import AVFoundation
import Vision
import Foundation

enum PoseTrackingType: Sendable {
    case handstandHold
    case pullupReps
    case handstandPushupReps
}

enum PoseEvent: Sendable {
    case holdDetected(Bool)
    case repCount(Int)
}

/// Wraps AVCaptureSession + Vision pose detection.
/// Usage: call configure() first (async), then stream() to get pose events.
final class PoseDetectionService: NSObject, @unchecked Sendable {
    private(set) var captureSession: AVCaptureSession?

    private let trackingType: PoseTrackingType
    private let sessionQueue = DispatchQueue(label: "fmf.pose.session")
    private let requestHandler = VNSequenceRequestHandler()
    private var continuation: AsyncStream<PoseEvent>.Continuation?
    private var readyContinuation: CheckedContinuation<Bool, Never>?
    private var processingFrame = false
    private var pullupPhase: PullupPhase = .waitingForExtension
    private var handstandPushupPhase: HandstandPushupPhase = .waitingForDip
    private var repCount = 0

    init(trackingType: PoseTrackingType) {
        self.trackingType = trackingType
    }

    // MARK: - Public API

    /// Configures and starts the capture session.
    /// Returns true if the session is running, false if device has no camera or startup failed.
    func configure() async -> Bool {
        await withCheckedContinuation { cont in
            self.readyContinuation = cont
            sessionQueue.async { self.configureSession() }
        }
    }

    func stream() -> AsyncStream<PoseEvent> {
        AsyncStream { [weak self] continuation in
            guard let self else { continuation.finish(); return }
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in self?.stopSession() }
        }
    }

    func stop() {
        stopSession()
    }

    // MARK: - Private

    private func configureSession() {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            resolveReady(false)
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .medium

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { resolveReady(false); return }
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: sessionQueue)

            guard session.canAddOutput(output) else { resolveReady(false); return }
            session.addOutput(output)

            session.startRunning()

            if session.isRunning {
                captureSession = session
                resolveReady(true)
            } else {
                resolveReady(false)
            }
        } catch {
            resolveReady(false)
        }
    }

    private func resolveReady(_ ready: Bool) {
        readyContinuation?.resume(returning: ready)
        readyContinuation = nil
    }

    private func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.captureSession = nil
            self?.continuation?.finish()
            self?.continuation = nil
        }
    }

    // MARK: - Detection

    private func event(for observation: VNHumanBodyPoseObservation) -> PoseEvent? {
        switch trackingType {
        case .handstandHold:
            return .holdDetected(isHandstand(observation))
        case .pullupReps:
            return detectPullupRep(in: observation)
        case .handstandPushupReps:
            return detectHandstandPushupRep(in: observation)
        }
    }

    /// Vision uses bottom-left origin (y increases upward).
    /// Handstand = nose is at bottom of image = lower y than hips.
    private func isHandstand(_ observation: VNHumanBodyPoseObservation) -> Bool {
        guard
            let nose = try? observation.recognizedPoint(.nose),
            let lHip = try? observation.recognizedPoint(.leftHip),
            let rHip = try? observation.recognizedPoint(.rightHip),
            nose.confidence > 0.3,
            lHip.confidence > 0.3,
            rHip.confidence > 0.3
        else { return false }

        return nose.location.y < lHip.location.y && nose.location.y < rHip.location.y
    }

    private func detectPullupRep(in observation: VNHumanBodyPoseObservation) -> PoseEvent? {
        guard let averageElbowAngle = averageElbowAngle(in: observation) else { return nil }

        if averageElbowAngle > 145 {
            pullupPhase = .readyToCount
            return nil
        }

        guard averageElbowAngle < 80, pullupPhase == .readyToCount else { return nil }
        pullupPhase = .waitingForExtension
        repCount += 1
        return .repCount(repCount)
    }

    private func detectHandstandPushupRep(in observation: VNHumanBodyPoseObservation) -> PoseEvent? {
        guard
            isInverted(observation),
            let averageElbowAngle = averageElbowAngle(in: observation)
        else { return nil }

        if averageElbowAngle < 95 {
            handstandPushupPhase = .readyToLockout
            return nil
        }

        guard averageElbowAngle > 155, handstandPushupPhase == .readyToLockout else { return nil }
        handstandPushupPhase = .waitingForDip
        repCount += 1
        return .repCount(repCount)
    }

    private func averageElbowAngle(in observation: VNHumanBodyPoseObservation) -> Double? {
        guard
            let left = elbowAngle(in: observation, side: .left),
            let right = elbowAngle(in: observation, side: .right)
        else { return nil }
        return (left + right) / 2
    }

    private enum BodySide {
        case left
        case right
    }

    private func elbowAngle(in observation: VNHumanBodyPoseObservation, side: BodySide) -> Double? {
        let shoulderName: VNHumanBodyPoseObservation.JointName = side == .left ? .leftShoulder : .rightShoulder
        let elbowName: VNHumanBodyPoseObservation.JointName = side == .left ? .leftElbow : .rightElbow
        let wristName: VNHumanBodyPoseObservation.JointName = side == .left ? .leftWrist : .rightWrist

        guard
            let shoulder = try? observation.recognizedPoint(shoulderName),
            let elbow = try? observation.recognizedPoint(elbowName),
            let wrist = try? observation.recognizedPoint(wristName),
            shoulder.confidence > 0.25,
            elbow.confidence > 0.25,
            wrist.confidence > 0.25
        else { return nil }

        return angle(shoulder.location, elbow.location, wrist.location)
    }

    private func isInverted(_ observation: VNHumanBodyPoseObservation) -> Bool {
        guard
            let leftAnkle = try? observation.recognizedPoint(.leftAnkle),
            let rightAnkle = try? observation.recognizedPoint(.rightAnkle),
            let leftHip = try? observation.recognizedPoint(.leftHip),
            let rightHip = try? observation.recognizedPoint(.rightHip),
            let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
            let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
            leftAnkle.confidence > 0.2,
            rightAnkle.confidence > 0.2,
            leftHip.confidence > 0.2,
            rightHip.confidence > 0.2,
            leftShoulder.confidence > 0.2,
            rightShoulder.confidence > 0.2
        else { return false }

        let ankleY = (leftAnkle.location.y + rightAnkle.location.y) / 2
        let hipY = (leftHip.location.y + rightHip.location.y) / 2
        let shoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        return ankleY > hipY && hipY > shoulderY
    }

    private func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let cb = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = ab.dx * cb.dx + ab.dy * cb.dy
        let magnitude = hypot(ab.dx, ab.dy) * hypot(cb.dx, cb.dy)
        guard magnitude > 0 else { return 0 }
        let cosine = max(-1.0, min(1.0, dot / magnitude))
        return acos(cosine) * 180 / .pi
    }
}

private enum PullupPhase {
    case waitingForExtension
    case readyToCount
}

private enum HandstandPushupPhase {
    case waitingForDip
    case readyToLockout
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension PoseDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !processingFrame, let continuation else { return }
        processingFrame = true
        defer { processingFrame = false }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest()
        do {
            try requestHandler.perform([request], on: pixelBuffer)
            if let event = request.results?.first.flatMap(event(for:)) {
                continuation.yield(event)
            } else if trackingType == .handstandHold {
                continuation.yield(.holdDetected(false))
            }
        } catch {
            if trackingType == .handstandHold {
                continuation.yield(.holdDetected(false))
            }
        }
    }
}
