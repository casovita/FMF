import SwiftUI

enum FMFColors {
    // Brand
    static let brandPrimary = Color(hex: 0x1A1A2E)
    static let brandAccent = Color(hex: 0x2563EB)
    static let accentBlueLight = Color(hex: 0x3B82F6)
    static let darkSurface = Color(hex: 0x1E2A3B)
    static let brandSurface = Color(hex: 0xF8F8FC)

    // Semantic
    static let success = Color(hex: 0x22C55E)
    static let warning = Color(hex: 0xF59E0B)
    static let error = Color(hex: 0xEF4444)

    // Neutral scale
    static let neutral900 = Color(hex: 0x111827)
    static let neutral700 = Color(hex: 0x374151)
    static let neutral500 = Color(hex: 0x6B7280)
    static let neutral300 = Color(hex: 0xD1D5DB)
    static let neutral100 = Color(hex: 0xF3F4F6)
    static let neutral50 = Color(hex: 0xFAFAFA)

    // Skill category tints
    static let skillBalance = Color(hex: 0x6366F1)
    static let skillStrength = Color(hex: 0xEF4444)
    static let skillBodyweight = Color(hex: 0x00D4AA)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, opacity: opacity)
    }
}
