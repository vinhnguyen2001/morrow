import SwiftUI

extension Color {
    /// sRGB colour from a 0xRRGGBB value.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// "Chronicle" v2 colour tokens.
enum MorrowColor {
    static let ground = Color(hex: 0xF4F4F1)
    static let action = Color(hex: 0x1E3B2F)
    static let groundDot = action.opacity(0.13)
    static let ink = Color(hex: 0x121212)
    static let textBody = Color(hex: 0x2B2B2B)
    /// Darkened for 4.5:1 contrast on ground and white.
    static let textSecondary = Color(hex: 0x5C5C5C)
    static let card = Color.white
    /// Error text, about 6:1 on ground and white.
    static let error = Color(hex: 0xB00020)
}
