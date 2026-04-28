import SwiftUI

enum FMFColors {
    // Backgrounds
    static let background     = Color(hex: 0x0A0A0A)
    static let surfaceLow     = Color(hex: 0x121212)
    static let surfaceMid     = Color(hex: 0x1A1A1A)
    static let surfaceHigh    = Color(hex: 0x2A2A2A)
    static let surfaceOverlay = Color(hex: 0x3F3F3F)

    // Brand
    static let brandPrimary      = Color(hex: 0xFF8068)
    static let brandPrimaryDark  = Color(hex: 0xD9512A)
    static let brandPrimaryLight = Color(hex: 0xFF9D8E)

    // Semantic
    static let success = Color(hex: 0x52D652)
    static let warning = Color(hex: 0xFFB800)
    static let error   = Color(hex: 0xFF6B6B)

    // Neutral scale
    static let neutral900 = Color(hex: 0x1A1A1A)
    static let neutral700 = Color(hex: 0x3F3F3F)
    static let neutral500 = Color(hex: 0x6B7280)
    static let neutral300 = Color(hex: 0xD1D5DB)
    static let neutral100 = Color(hex: 0xF3F4F6)
    static let neutral50  = Color(hex: 0xFAFAFA)

    // Skill category accents
    static let skillBalance    = Color(hex: 0x4D7CFF)
    static let skillStrength   = Color(hex: 0xFF8068)
    static let skillBodyweight = Color(hex: 0x52D652)

}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, opacity: opacity)
    }
}
