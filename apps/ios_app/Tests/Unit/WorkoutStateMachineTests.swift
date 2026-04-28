import Testing
import Foundation
@testable import FMF

// Tests the WorkoutViewModel state machine in isolation using a mock repository.
// Camera/Vision not tested here — PoseDetectionService has no device on simulator.

private final class MockWorkoutCompletionService: PracticeSessionCompleting, @unchecked Sendable {
    private(set) var completedSessions: [PracticeSession] = []

    func completeSession(_ session: PracticeSession) async throws -> PracticeSession {
        completedSessions.append(session)
        return session
    }
}

@MainActor
private final class MockWorkoutSoundPlayer: WorkoutSoundPlaying {
    private(set) var playedEffects: [WorkoutSoundEffect] = []

    func play(_ effect: WorkoutSoundEffect) {
        playedEffects.append(effect)
    }
}

@MainActor
private final class MockVoiceCommandService: VoiceCommandListening {
    var permissionsGranted = true
    private(set) var isListening = false
    private var onCommand: (@MainActor (VoiceCommand) -> Void)?

    func requestPermissions() async -> Bool {
        permissionsGranted
    }

    func startListening(onCommand: @escaping @MainActor (VoiceCommand) -> Void) async throws {
        isListening = true
        self.onCommand = onCommand
    }

    func stopListening() {
        isListening = false
        onCommand = nil
    }

    func send(_ command: VoiceCommand) {
        guard let onCommand else { return }
        onCommand(command)
    }
}

@Suite("WorkoutViewModel state machine")
@MainActor
struct WorkoutStateMachineTests {
    private func makeDurationVM(
        skillId: String = "handstand",
        completionService: MockWorkoutCompletionService = MockWorkoutCompletionService(),
        sessionDraft: PracticeSessionDraft? = nil,
        voiceCommandService: MockVoiceCommandService? = nil,
        soundPlayer: MockWorkoutSoundPlayer? = nil,
        timingConfiguration: WorkoutTimingConfiguration = .standard
    ) -> WorkoutViewModel {
        WorkoutViewModel(
            skillId: skillId,
            prescriptionType: .duration,
            completionService: completionService,
            sessionDraft: sessionDraft,
            voiceCommandService: voiceCommandService,
            soundPlayer: soundPlayer,
            timingConfiguration: timingConfiguration
        )
    }

    private func makeRepVM(
        skillId: String = "pullups",
        completionService: MockWorkoutCompletionService = MockWorkoutCompletionService(),
        soundPlayer: MockWorkoutSoundPlayer? = nil
    ) -> WorkoutViewModel {
        WorkoutViewModel(
            skillId: skillId,
            prescriptionType: .reps,
            completionService: completionService,
            soundPlayer: soundPlayer
        )
    }

    @Test("initial state is modeSelection")
    func initialState() {
        let vm = makeDurationVM()
        #expect(vm.state == .modeSelection)
    }

    @Test("manualStart from idle transitions to active")
    func manualStartFromIdle() async throws {
        let completionService = MockWorkoutCompletionService()
        let vm = makeDurationVM(completionService: completionService)
        // Force idle state directly (bypasses camera init)
        vm.testForceState(.idle)
        vm.manualStart()
        if case .active(let s) = vm.state {
            #expect(s == 0)
        } else {
            Issue.record("Expected .active, got \(vm.state)")
        }
    }

    @Test("selecting manual mode skips camera setup")
    func manualModeSkipsCamera() async {
        let vm = makeDurationVM()
        await vm.selectMode(.manual)
        #expect(vm.state == .idle)
        #expect(vm.captureSession == nil)
    }

    @Test("manual mode starts with 10 second get ready countdown")
    func manualModeStartsInitialCountdown() async {
        let draft = PracticeSessionDraft(
            skillId: "handstand",
            prescriptionType: .duration,
            setsCompleted: 3,
            targetValuePerSet: 15,
            restSeconds: 45,
            durationSetValues: [15, 15, 15],
            notes: nil,
            plannedSessionId: nil
        )
        let vm = makeDurationVM(sessionDraft: draft)
        await vm.selectMode(.manual)

        vm.manualStart()
        await Task.yield()

        #expect(vm.state == .countdown(secondsRemaining: 10, phase: .initialCountdown))
    }

    @Test("countdown effect map uses tick then final tick")
    func countdownEffectMap() {
        let vm = makeDurationVM()
        let effects = stride(from: 10, through: 1, by: -1).map { vm.testCountdownEffect(for: $0) }

        #expect(Array(effects.prefix(7)) == Array(repeating: .countdownTick, count: 7))
        #expect(Array(effects.suffix(3)) == Array(repeating: .countdownFinalTick, count: 3))
    }

    @Test("rep skills allow manual mode with rep-set flow")
    func repSkillsAllowManualMode() async {
        let vm = makeRepVM()
        await vm.selectMode(.manual)
        #expect(vm.state == .idle)
        #expect(vm.allowsManualMode == true)
        #expect(vm.isRepManualMode == true)
    }

    @Test("sound mode starts listening and responds to voice commands")
    func soundModeHandlesVoiceCommands() async {
        let completionService = MockWorkoutCompletionService()
        let voiceCommandService = MockVoiceCommandService()
        let soundPlayer = MockWorkoutSoundPlayer()
        let vm = makeDurationVM(
            completionService: completionService,
            voiceCommandService: voiceCommandService,
            soundPlayer: soundPlayer
        )

        await vm.selectMode(.sound)
        #expect(vm.state == .idle)
        #expect(voiceCommandService.isListening == true)

        voiceCommandService.send(.start)
        await Task.yield()
        #expect(vm.state == .active(elapsedSeconds: 0))

        vm.testSetElapsed(18)
        voiceCommandService.send(.stop)
        for _ in 0..<5 {
            await Task.yield()
        }

        #expect(vm.state == .complete(totalSeconds: 18))
        #expect(completionService.completedSessions.count == 1)
        #expect(soundPlayer.playedEffects.contains(.sessionComplete) == false)
    }

    @Test("stopSession from active transitions to complete and saves session")
    func stopFromActive() async throws {
        let completionService = MockWorkoutCompletionService()
        let soundPlayer = MockWorkoutSoundPlayer()
        let vm = makeDurationVM(completionService: completionService, soundPlayer: soundPlayer)
        vm.testForceState(.idle)
        vm.manualStart()
        vm.testSetElapsed(30)
        await vm.stopSession()
        #expect(vm.state == .complete(totalSeconds: 30))
        #expect(completionService.completedSessions.count == 1)
        #expect(completionService.completedSessions[0].skillId == "handstand")
        #expect(completionService.completedSessions[0].durationMinutes == 1) // max(1, 30/60) = 1
        #expect(soundPlayer.playedEffects == [.sessionComplete])
    }

    @Test("rep skills save rep count instead of elapsed seconds")
    func stopFromActiveSavesRepCount() async {
        let completionService = MockWorkoutCompletionService()
        let vm = makeRepVM(completionService: completionService)
        vm.testForceState(.idle)
        vm.testSetRepCount(7)
        vm.testSetElapsed(90)

        await vm.stopSession()

        #expect(vm.state == .complete(totalSeconds: 90))
        #expect(completionService.completedSessions.count == 1)
        #expect(completionService.completedSessions[0].sessionScore == 7)
    }

    @Test("stopSession with zero elapsed does not save session")
    func stopWithZeroElapsed() async throws {
        let completionService = MockWorkoutCompletionService()
        let soundPlayer = MockWorkoutSoundPlayer()
        let vm = makeDurationVM(completionService: completionService, soundPlayer: soundPlayer)
        vm.testForceState(.idle)
        await vm.stopSession()
        #expect(completionService.completedSessions.isEmpty)
        #expect(soundPlayer.playedEffects == [.sessionComplete])
    }

    @Test("manualStart is idempotent when already active")
    func manualStartIdempotent() {
        let vm = makeDurationVM()
        vm.testForceState(.active(elapsedSeconds: 10))
        vm.manualStart()
        #expect(vm.state == .active(elapsedSeconds: 10))
    }

    @Test("execution saves edited session draft values")
    func executionUsesSessionDraft() async throws {
        let completionService = MockWorkoutCompletionService()
        let draft = PracticeSessionDraft(
            skillId: "handstand",
            prescriptionType: .duration,
            setsCompleted: 4,
            targetValuePerSet: 20,
            restSeconds: 75,
            durationSetValues: [20, 22, 24, 26],
            notes: "Felt solid",
            plannedSessionId: "planned-1"
        )
        let vm = makeDurationVM(
            completionService: completionService,
            sessionDraft: draft
        )

        vm.testForceState(.idle)
        vm.manualStart()
        vm.testSetElapsed(26)
        await vm.stopSession()

        let saved = try #require(completionService.completedSessions.first)
        #expect(saved.setsCompleted == 1)
        #expect(saved.targetValuePerSet == 26)
        #expect(saved.restSeconds == 75)
        #expect(saved.plannedSessionId == "planned-1")
        #expect(saved.durationSetValues == [26])
        #expect(saved.notes?.contains("Felt solid") == true)
        #expect(saved.sessionScore == 26)
    }

    @Test("timer executed session duration includes rests and middle get ready only")
    func timerExecutedSessionDurationIncludesMiddleCountdowns() {
        let draft = PracticeSessionDraft(
            skillId: "handstand",
            prescriptionType: .duration,
            setsCompleted: 3,
            targetValuePerSet: 20,
            restSeconds: 45,
            durationSetValues: [20, 20, 20],
            notes: nil,
            plannedSessionId: nil
        )

        let session = draft.makeTimerExecutedSession(
            completedDurations: [20, 20, 20],
            totalSessionSeconds: 20 + 20 + 20 + 45 + 45 + 5 + 5
        )

        #expect(session.durationMinutes == 3)
        #expect(session.sessionScore == 20)
        #expect(session.restSeconds == 45)
    }

    @Test("duration draft estimate includes middle get ready but not initial countdown")
    func durationDraftEstimateIncludesMiddleCountdownsOnly() {
        let draft = PracticeSessionDraft(
            skillId: "handstand",
            prescriptionType: .duration,
            setsCompleted: 3,
            targetValuePerSet: 20,
            restSeconds: 45,
            durationSetValues: [20, 20, 20],
            notes: nil,
            plannedSessionId: nil
        )

        #expect(draft.estimatedDurationMinutes == 3)
    }

    @Test("timer start emits countdown and work sounds")
    func timerStartEmitsCountdownAndWorkSounds() async {
        let draft = PracticeSessionDraft(
            skillId: "handstand",
            prescriptionType: .duration,
            setsCompleted: 1,
            targetValuePerSet: 1,
            restSeconds: 0,
            durationSetValues: [1],
            notes: nil,
            plannedSessionId: nil
        )
        let soundPlayer = MockWorkoutSoundPlayer()
        let vm = makeDurationVM(
            sessionDraft: draft,
            soundPlayer: soundPlayer,
            timingConfiguration: WorkoutTimingConfiguration(
                gracePeriodSeconds: 1,
                initialGetReadySeconds: 4,
                betweenSetsGetReadySeconds: 2
            )
        )

        await vm.selectMode(.manual)
        vm.manualStart()
        try? await Task.sleep(for: .seconds(4.6))

        #expect(soundPlayer.playedEffects.starts(with: [
            .countdownTick,
            .countdownFinalTick,
            .countdownFinalTick,
            .countdownFinalTick,
            .countdownGo,
            .workStart
        ]))
    }

    @Test("timer sequence emits rest next-set and completion sounds")
    func timerSequenceEmitsRestAndCompletionSounds() async {
        let completionService = MockWorkoutCompletionService()
        let draft = PracticeSessionDraft(
            skillId: "handstand",
            prescriptionType: .duration,
            setsCompleted: 2,
            targetValuePerSet: 1,
            restSeconds: 1,
            durationSetValues: [1, 1],
            notes: nil,
            plannedSessionId: nil
        )
        let soundPlayer = MockWorkoutSoundPlayer()
        let vm = makeDurationVM(
            completionService: completionService,
            sessionDraft: draft,
            soundPlayer: soundPlayer,
            timingConfiguration: WorkoutTimingConfiguration(
                gracePeriodSeconds: 1,
                initialGetReadySeconds: 1,
                betweenSetsGetReadySeconds: 1
            )
        )

        await vm.selectMode(.manual)
        vm.manualStart()
        try? await Task.sleep(for: .seconds(5.5))

        #expect(vm.state == .complete(totalSeconds: 2))
        #expect(soundPlayer.playedEffects.contains(.restStart))
        #expect(soundPlayer.playedEffects.filter { $0 == .workStart }.count == 2)
        #expect(soundPlayer.playedEffects.last == .sessionComplete)
        #expect(completionService.completedSessions.count == 1)
    }

    @Test("smart duration mode emits acquire pause resume complete sounds")
    func smartDurationModeEmitsExpectedSounds() async {
        let completionService = MockWorkoutCompletionService()
        let soundPlayer = MockWorkoutSoundPlayer()
        let vm = makeDurationVM(
            completionService: completionService,
            soundPlayer: soundPlayer,
            timingConfiguration: WorkoutTimingConfiguration(
                gracePeriodSeconds: 1,
                initialGetReadySeconds: 10,
                betweenSetsGetReadySeconds: 5
            )
        )

        vm.testForceState(.idle)
        await vm.testHandlePoseEvent(.holdDetected(true))
        #expect(soundPlayer.playedEffects == [.poseAcquired])

        await vm.testHandlePoseEvent(.holdDetected(false))
        #expect(soundPlayer.playedEffects == [.poseAcquired, .poseLostWarning])

        await vm.testHandlePoseEvent(.holdDetected(true))
        #expect(soundPlayer.playedEffects == [.poseAcquired, .poseLostWarning, .poseResumed])

        await vm.testHandlePoseEvent(.holdDetected(false))
        try? await Task.sleep(for: .seconds(1.2))

        if case .complete(let totalSeconds) = vm.state {
            #expect((0...1).contains(totalSeconds))
        } else {
            Issue.record("Expected complete state, got \(vm.state)")
        }
        #expect(soundPlayer.playedEffects.suffix(2) == [.poseLostWarning, .sessionComplete])
    }

    @Test("smart rep mode emits acquire and rep sounds once per increment")
    func smartRepModeEmitsRepSounds() async {
        let soundPlayer = MockWorkoutSoundPlayer()
        let vm = makeRepVM(soundPlayer: soundPlayer)

        vm.testForceState(.idle)
        await vm.testHandlePoseEvent(.repCount(1))
        await vm.testHandlePoseEvent(.repCount(1))
        await vm.testHandlePoseEvent(.repCount(2))

        #expect(soundPlayer.playedEffects == [
            .poseAcquired,
            .repCounted,
            .repCounted
        ])
    }

    @Test("rep manual mode — confirmRepSet advances set and saves on last set")
    func repManualModeAdvancesSetAndSaves() async {
        let completionService = MockWorkoutCompletionService()
        let draft = PracticeSessionDraft(
            skillId: "pullups",
            prescriptionType: .reps,
            setsCompleted: 2,
            targetValuePerSet: 8,
            restSeconds: 0,
            durationSetValues: [],
            notes: nil,
            plannedSessionId: nil
        )
        let vm = WorkoutViewModel(
            skillId: "pullups",
            prescriptionType: .reps,
            completionService: completionService,
            sessionDraft: draft,
            soundPlayer: MockWorkoutSoundPlayer()
        )

        await vm.selectMode(.manual)
        #expect(vm.state == .idle)
        #expect(vm.manualCurrentSet == 1)
        #expect(vm.isRepManualMode == true)

        vm.manualStart()
        let isActiveAfterStart: Bool
        if case .active = vm.state {
            isActiveAfterStart = true
        } else {
            isActiveAfterStart = false
        }
        #expect(isActiveAfterStart)

        vm.doneWithSet()
        #expect(vm.repEntryPending == true)

        await vm.confirmRepSet(reps: 7)
        #expect(vm.manualCurrentSet == 2)
        #expect(vm.repEntryPending == false)
        #expect(vm.state == .idle)

        vm.manualStart()
        vm.doneWithSet()
        await vm.confirmRepSet(reps: 9)

        let isCompleteAfterFinalSet: Bool
        if case .complete = vm.state {
            isCompleteAfterFinalSet = true
        } else {
            isCompleteAfterFinalSet = false
        }
        #expect(isCompleteAfterFinalSet)
        #expect(completionService.completedSessions.count == 1)
        #expect(completionService.completedSessions[0].sessionScore == 16)
        #expect(completionService.completedSessions[0].setsCompleted == 2)
        #expect(completionService.completedSessions[0].durationSetValues == [7, 9])
        #expect(completionService.completedSessions[0].targetValuePerSet == 8)
        #expect(completionService.completedSessions[0].restSeconds == 0)
    }

    @Test("rep manual mode — cancelRepEntry resumes active state")
    func repManualModeCancelRepEntryResumesActive() async {
        let draft = PracticeSessionDraft(
            skillId: "pullups",
            prescriptionType: .reps,
            setsCompleted: 2,
            targetValuePerSet: 8,
            restSeconds: 60,
            durationSetValues: [],
            notes: nil,
            plannedSessionId: nil
        )
        let vm = WorkoutViewModel(
            skillId: "pullups",
            prescriptionType: .reps,
            completionService: MockWorkoutCompletionService(),
            sessionDraft: draft,
            soundPlayer: MockWorkoutSoundPlayer()
        )

        await vm.selectMode(.manual)
        vm.manualStart()
        vm.doneWithSet()
        #expect(vm.repEntryPending == true)

        vm.cancelRepEntry()
        #expect(vm.repEntryPending == false)
        let isActiveAfterCancel: Bool
        if case .active = vm.state {
            isActiveAfterCancel = true
        } else {
            isActiveAfterCancel = false
        }
        #expect(isActiveAfterCancel)
    }

    @Test("camera guide spec uses skill-specific markers")
    func cameraGuideSpecMatchesSkill() {
        let handstand = Skill(
            id: "handstand",
            name: "Handstand",
            description: "",
            category: .balance,
            prescriptionType: .duration
        )
        let handstandSpec = cameraGuideSpec(for: handstand)
        #expect(handstandSpec.badgeTitle == "Handstand")
        #expect(handstandSpec.markers.map(\.id) == ["hands", "hips", "toes"])

        let pullups = Skill(
            id: "pullups",
            name: "Pull-ups",
            description: "",
            category: .strength,
            prescriptionType: .reps
        )
        let pullupSpec = cameraGuideSpec(for: pullups)
        #expect(pullupSpec.markers.map(\.id) == ["bar", "chest", "feet"])
        #expect(pullupSpec.frameOffsetY < 0)

        let hspu = Skill(
            id: "handstand_pushups",
            name: "Handstand Push-ups",
            description: "",
            category: .bodyweight,
            prescriptionType: .reps
        )
        let hspuSpec = cameraGuideSpec(for: hspu)
        #expect(hspuSpec.markers.map(\.id) == ["hands", "head", "toes"])

        let genericSpec = cameraGuideSpec(for: nil)
        #expect(genericSpec.markers.map(\.id) == ["head", "center", "feet"])
    }

    @Test("error paths emit error sound")
    func errorPathsEmitErrorSound() async {
        let soundPlayer = MockWorkoutSoundPlayer()
        let vm = makeDurationVM(soundPlayer: soundPlayer)

        await vm.selectMode(.smart)

        #if targetEnvironment(simulator)
        #expect(soundPlayer.playedEffects.isEmpty)
        #else
        Issue.record("This test only asserts simulator behavior directly.")
        #endif

        let unavailableSmartVM = WorkoutViewModel(
            skillId: "handstand",
            prescriptionType: .duration,
            completionService: MockWorkoutCompletionService(),
            supportsSmartTracking: false,
            soundPlayer: soundPlayer
        )

        await unavailableSmartVM.selectMode(.smart)
        #expect(soundPlayer.playedEffects.contains(.error))
    }
}
