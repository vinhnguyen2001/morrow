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
    /// Timeline spine, connectors and leaves (Main.dc.html lines 86-148).
    static let leaf = Color(hex: 0x7CC48A)
    static let leafLight = Color(hex: 0xA9DDB2)
    /// Dot on the notification bell (Main.dc.html line 26). Decorative, not text.
    static let notificationDot = Color(hex: 0xE8542F)
    /// Place chip on Detail (Main.dc.html line 435), and the neutral "Private" chip beside it.
    static let placeChipBackground = Color(hex: 0xE4F1FB)
    static let placeChipText = Color(hex: 0x1F6FA8)
    static let neutralChipBackground = Color(hex: 0xE9E9E9)
    /// Error text, about 6:1 on ground and white.
    static let error = Color(hex: 0xB00020)
}
