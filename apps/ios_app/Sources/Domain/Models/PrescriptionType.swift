import Foundation

enum PrescriptionType: String, Codable, Sendable {
    case duration  // hold-based skills (handstand, L-sit)
    case reps      // rep-based skills (pull-ups, dips)
}
