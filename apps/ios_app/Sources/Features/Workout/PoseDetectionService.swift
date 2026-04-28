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

struct PoseJoint: Sendable {
    let location: CGPoint
    let confidence: Float
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
        guard let device = preferredCamera() else {
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

    private func preferredCamera() -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera
        ]

        for position in [AVCaptureDevice.Position.back, .unspecified] {
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: position
            )

            if let device = discovery.devices.first {
                return device
            }
        }

        return nil
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
    private func isHandstand(_ observation: VNHumanBodyPoseObservation) -> Bool {
        Self.isHandstandHold(
            leftShoulder: joint(.leftShoulder, in: observation),
            rightShoulder: joint(.rightShoulder, in: observation),
            leftHip: joint(.leftHip, in: observation),
            rightHip: joint(.rightHip, in: observation),
            leftAnkle: joint(.leftAnkle, in: observation),
            rightAnkle: joint(.rightAnkle, in: observation)
        )
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
        Self.isInverted(
            leftShoulder: joint(.leftShoulder, in: observation),
            rightShoulder: joint(.rightShoulder, in: observation),
            leftHip: joint(.leftHip, in: observation),
            rightHip: joint(.rightHip, in: observation),
            leftAnkle: joint(.leftAnkle, in: observation),
            rightAnkle: joint(.rightAnkle, in: observation)
        )
    }

    private func joint(
        _ name: VNHumanBodyPoseObservation.JointName,
        in observation: VNHumanBodyPoseObservation
    ) -> PoseJoint? {
        guard let point = try? observation.recognizedPoint(name) else { return nil }
        return PoseJoint(location: point.location, confidence: point.confidence)
    }

    static func isHandstandHold(
        leftShoulder: PoseJoint?,
        rightShoulder: PoseJoint?,
        leftHip: PoseJoint?,
        rightHip: PoseJoint?,
        leftAnkle: PoseJoint?,
        rightAnkle: PoseJoint?
    ) -> Bool {
        isInverted(
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            leftHip: leftHip,
            rightHip: rightHip,
            leftAnkle: leftAnkle,
            rightAnkle: rightAnkle
        )
    }

    static func isInverted(
        leftShoulder: PoseJoint?,
        rightShoulder: PoseJoint?,
        leftHip: PoseJoint?,
        rightHip: PoseJoint?,
        leftAnkle: PoseJoint?,
        rightAnkle: PoseJoint?
    ) -> Bool {
        guard
            let leftShoulder, leftShoulder.confidence > 0.2,
            let rightShoulder, rightShoulder.confidence > 0.2,
            let leftHip, leftHip.confidence > 0.2,
            let rightHip, rightHip.confidence > 0.2,
            let leftAnkle, leftAnkle.confidence > 0.2,
            let rightAnkle, rightAnkle.confidence > 0.2
        else { return false }

        let shoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        let hipY = (leftHip.location.y + rightHip.location.y) / 2
        let ankleY = (leftAnkle.location.y + rightAnkle.location.y) / 2
        return shoulderY < hipY && hipY < ankleY
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
