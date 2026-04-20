import AVFoundation
import Vision
import Foundation

/// Wraps AVCaptureSession + Vision pose detection.
/// Delivers a Bool stream: true = handstand detected in this frame.
/// Safe to create/use from @MainActor — all AVFoundation work runs on sessionQueue.
final class PoseDetectionService: NSObject, @unchecked Sendable {
    private(set) var captureSession: AVCaptureSession?

    private let sessionQueue = DispatchQueue(label: "fmf.pose.session")
    private let requestHandler = VNSequenceRequestHandler()
    private var continuation: AsyncStream<Bool>.Continuation?
    private var processingFrame = false

    // MARK: - Stream

    /// One Bool per processed frame. true = handstand detected.
    func start() -> AsyncStream<Bool> {
        AsyncStream { [weak self] continuation in
            guard let self else { continuation.finish(); return }
            self.continuation = continuation
            self.sessionQueue.async { self.configureSession() }
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
            continuation?.yield(false)
            continuation?.finish()
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .medium

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                continuation?.finish(); return
            }
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: sessionQueue)

            guard session.canAddOutput(output) else {
                continuation?.finish(); return
            }
            session.addOutput(output)

            captureSession = session
            session.startRunning()
        } catch {
            continuation?.finish()
        }
    }

    private func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.captureSession = nil
            self?.continuation?.finish()
            self?.continuation = nil
        }
    }

    // MARK: - Handstand detection

    /// ⚠️ Vision uses bottom-left origin (y increases upward).
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

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            continuation.yield(false)
            return
        }

        let request = VNDetectHumanBodyPoseRequest()
        do {
            try requestHandler.perform([request], on: pixelBuffer)
            let detected = request.results?.first.map { isHandstand($0) } ?? false
            continuation.yield(detected)
        } catch {
            continuation.yield(false)
        }
    }
}
