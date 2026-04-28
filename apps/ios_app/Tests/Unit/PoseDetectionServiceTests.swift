import CoreGraphics
import Testing
@testable import FMF

@Suite("PoseDetectionService")
struct PoseDetectionServiceTests {
    @Test("upright standing posture is not detected as handstand")
    func uprightPostureReturnsFalse() {
        let result = PoseDetectionService.isHandstandHold(
            leftShoulder: joint(x: 0.4, y: 0.8),
            rightShoulder: joint(x: 0.6, y: 0.8),
            leftHip: joint(x: 0.45, y: 0.55),
            rightHip: joint(x: 0.55, y: 0.55),
            leftAnkle: joint(x: 0.45, y: 0.12),
            rightAnkle: joint(x: 0.55, y: 0.12)
        )

        #expect(result == false)
    }

    @Test("inverted posture is detected as handstand")
    func invertedPostureReturnsTrue() {
        let result = PoseDetectionService.isHandstandHold(
            leftShoulder: joint(x: 0.4, y: 0.18),
            rightShoulder: joint(x: 0.6, y: 0.18),
            leftHip: joint(x: 0.45, y: 0.46),
            rightHip: joint(x: 0.55, y: 0.46),
            leftAnkle: joint(x: 0.45, y: 0.84),
            rightAnkle: joint(x: 0.55, y: 0.84)
        )

        #expect(result == true)
    }

    @Test("missing low-confidence joints do not infer handstand")
    func lowConfidenceReturnsFalse() {
        let result = PoseDetectionService.isHandstandHold(
            leftShoulder: joint(x: 0.4, y: 0.18),
            rightShoulder: joint(x: 0.6, y: 0.18),
            leftHip: joint(x: 0.45, y: 0.46),
            rightHip: joint(x: 0.55, y: 0.46),
            leftAnkle: joint(x: 0.45, y: 0.84, confidence: 0.1),
            rightAnkle: joint(x: 0.55, y: 0.84)
        )

        #expect(result == false)
    }

    @Test("handstand pushup inverted helper stays true for valid upside-down posture")
    func invertedHelperReturnsTrue() {
        let result = PoseDetectionService.isInverted(
            leftShoulder: joint(x: 0.4, y: 0.18),
            rightShoulder: joint(x: 0.6, y: 0.18),
            leftHip: joint(x: 0.45, y: 0.46),
            rightHip: joint(x: 0.55, y: 0.46),
            leftAnkle: joint(x: 0.45, y: 0.84),
            rightAnkle: joint(x: 0.55, y: 0.84)
        )

        #expect(result == true)
    }

    private func joint(x: CGFloat, y: CGFloat, confidence: Float = 1.0) -> PoseJoint {
        PoseJoint(location: CGPoint(x: x, y: y), confidence: confidence)
    }
}
