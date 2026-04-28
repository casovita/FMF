import AVFoundation
import Foundation
import Speech

enum VoiceCommand: Sendable, Equatable {
    case start
    case stop
}

enum VoiceCommandError: Error {
    case permissionsDenied
    case recognizerUnavailable
    case audioSetupFailed
}

@MainActor
protocol VoiceCommandListening: AnyObject {
    func requestPermissions() async -> Bool
    func startListening(onCommand: @escaping @MainActor (VoiceCommand) -> Void) async throws
    func stopListening()
}

@MainActor
final class SpeechVoiceCommandService: VoiceCommandListening {
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var lastRecognizedCommand: VoiceCommand?

    func requestPermissions() async -> Bool {
        let speechAuthorized = await speechAuthorizationGranted()
        let microphoneAuthorized = await microphoneAuthorizationGranted()
        return speechAuthorized && microphoneAuthorized
    }

    func startListening(onCommand: @escaping @MainActor (VoiceCommand) -> Void) async throws {
        stopListening()

        guard let recognizer, recognizer.isAvailable else {
            throw VoiceCommandError.recognizerUnavailable
        }

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw VoiceCommandError.audioSetupFailed
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        lastRecognizedCommand = nil

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            stopListening()
            throw VoiceCommandError.audioSetupFailed
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let transcript = result.bestTranscription.formattedString.lowercased()
                if transcript.contains("start"), self.lastRecognizedCommand != .start {
                    self.lastRecognizedCommand = .start
                    Task { @MainActor in onCommand(.start) }
                } else if transcript.contains("stop"), self.lastRecognizedCommand != .stop {
                    self.lastRecognizedCommand = .stop
                    Task { @MainActor in onCommand(.stop) }
                }
            }

            if error != nil {
                self.stopListening()
            }
        }
    }

    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func speechAuthorizationGranted() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func microphoneAuthorizationGranted() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
