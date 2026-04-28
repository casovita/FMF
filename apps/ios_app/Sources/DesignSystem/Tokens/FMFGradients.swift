import SwiftUI

enum FMFGradients {
    static let orange = Gradient(colors: [Color(hex: 0xFF8068), Color(hex: 0xD9512A)])
    static let purple = Gradient(colors: [Color(hex: 0xE168FF), Color(hex: 0x9D2FC4)])
    static let green  = Gradient(colors: [Color(hex: 0x52D652), Color(hex: 0x2A8A2A)])
    static let blue   = Gradient(colors: [Color(hex: 0x4D7CFF), Color(hex: 0x2A4FD9)])
    static let teal   = Gradient(colors: [Color(hex: 0x22D3EE), Color(hex: 0x0891B2)])
    static let cardSurface = Gradient(colors: [Color(hex: 0x1A1A1A), Color(hex: 0x2A2A2A)])
    static let appBase = Gradient(colors: [Color(hex: 0x0A0A0A), Color(hex: 0x111111), Color(hex: 0x0A0A0A)])

    static func forCategory(_ category: SkillCategory) -> Gradient {
        switch category {
        case .balance:    return blue
        case .strength:   return orange
        case .bodyweight: return green
        }
    }

    static func accentForCategory(_ category: SkillCategory) -> Color {
        switch category {
        case .balance:    return Color(hex: 0x4D7CFF)
        case .strength:   return Color(hex: 0xFF8068)
        case .bodyweight: return Color(hex: 0x52D652)
        }
    }
}
