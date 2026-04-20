import Testing
import Foundation
@testable import FMF

// Tests the WorkoutViewModel state machine in isolation using a mock repository.
// Camera/Vision not tested here — PoseDetectionService has no device on simulator.

private final class MockPracticeSessionRepository: PracticeSessionRepository, @unchecked Sendable {
    private(set) var loggedSessions: [PracticeSession] = []

    func logSession(_ session: PracticeSession) async throws {
        loggedSessions.append(session)
    }
    func getSessionsForSkill(_ skillId: String) async throws -> [PracticeSession] { [] }
    func getRecentSessions(limit: Int) async throws -> [PracticeSession] { [] }
}

@Suite("WorkoutViewModel state machine")
@MainActor
struct WorkoutStateMachineTests {

    @Test("initial state is modeSelection")
    func initialState() {
        let vm = WorkoutViewModel(skillId: "handstand", repo: MockPracticeSessionRepository())
        #expect(vm.state == .modeSelection)
    }

    @Test("manualStart from idle transitions to active")
    func manualStartFromIdle() async throws {
        let repo = MockPracticeSessionRepository()
        let vm = WorkoutViewModel(skillId: "handstand", repo: repo)
        // Force idle state directly (bypasses camera init)
        vm.testForceState(.idle)
        vm.manualStart()
        if case .active(let s) = vm.state {
            #expect(s == 0)
        } else {
            Issue.record("Expected .active, got \(vm.state)")
        }
    }

    @Test("stopSession from active transitions to complete and saves session")
    func stopFromActive() async throws {
        let repo = MockPracticeSessionRepository()
        let vm = WorkoutViewModel(skillId: "handstand", repo: repo)
        vm.testForceState(.idle)
        vm.manualStart()
        vm.testSetElapsed(30)
        await vm.stopSession()
        #expect(vm.state == .complete(totalSeconds: 30))
        #expect(repo.loggedSessions.count == 1)
        #expect(repo.loggedSessions[0].skillId == "handstand")
        #expect(repo.loggedSessions[0].durationMinutes == 1) // max(1, 30/60) = 1
    }

    @Test("stopSession with zero elapsed does not save session")
    func stopWithZeroElapsed() async throws {
        let repo = MockPracticeSessionRepository()
        let vm = WorkoutViewModel(skillId: "handstand", repo: repo)
        vm.testForceState(.idle)
        await vm.stopSession()
        #expect(repo.loggedSessions.isEmpty)
    }

    @Test("manualStart is idempotent when already active")
    func manualStartIdempotent() {
        let repo = MockPracticeSessionRepository()
        let vm = WorkoutViewModel(skillId: "handstand", repo: repo)
        vm.testForceState(.active(elapsedSeconds: 10))
        vm.manualStart()
        #expect(vm.state == .active(elapsedSeconds: 10))
    }
}
