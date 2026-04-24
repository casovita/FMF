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

@Suite("WorkoutViewModel state machine")
@MainActor
struct WorkoutStateMachineTests {
    private func makeDurationVM(
        skillId: String = "handstand",
        completionService: MockWorkoutCompletionService = MockWorkoutCompletionService()
    ) -> WorkoutViewModel {
        WorkoutViewModel(
            skillId: skillId,
            prescriptionType: .duration,
            completionService: completionService
        )
    }

    private func makeRepVM(
        skillId: String = "pullups",
        completionService: MockWorkoutCompletionService = MockWorkoutCompletionService()
    ) -> WorkoutViewModel {
        WorkoutViewModel(
            skillId: skillId,
            prescriptionType: .reps,
            completionService: completionService
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

    @Test("rep skills do not allow manual mode")
    func repSkillsSkipManualMode() async {
        let vm = makeRepVM()
        await vm.selectMode(.manual)
        #expect(vm.state == .modeSelection)
        #expect(vm.allowsManualMode == false)
    }

    @Test("stopSession from active transitions to complete and saves session")
    func stopFromActive() async throws {
        let completionService = MockWorkoutCompletionService()
        let vm = makeDurationVM(completionService: completionService)
        vm.testForceState(.idle)
        vm.manualStart()
        vm.testSetElapsed(30)
        await vm.stopSession()
        #expect(vm.state == .complete(totalSeconds: 30))
        #expect(completionService.completedSessions.count == 1)
        #expect(completionService.completedSessions[0].skillId == "handstand")
        #expect(completionService.completedSessions[0].durationMinutes == 1) // max(1, 30/60) = 1
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
        let vm = makeDurationVM(completionService: completionService)
        vm.testForceState(.idle)
        await vm.stopSession()
        #expect(completionService.completedSessions.isEmpty)
    }

    @Test("manualStart is idempotent when already active")
    func manualStartIdempotent() {
        let vm = makeDurationVM()
        vm.testForceState(.active(elapsedSeconds: 10))
        vm.manualStart()
        #expect(vm.state == .active(elapsedSeconds: 10))
    }
}
