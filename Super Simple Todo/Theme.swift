import AppKit
import SwiftUI

/// The app's soft, warm surface colors, each with its own light and dark shade.
enum Theme {
    /// Window background: a faint warm off-white, or a warm near-black.
    static let background = Color.dynamic(light: 0xFAF7F2, dark: 0x1E1C1A)
    /// Task cards and the input field.
    static let card = Color.dynamic(light: 0xFFFFFF, dark: 0x2A2826)
    /// Hairline around cards.
    static let cardStroke = Color.dynamic(light: 0xECE6DC, dark: 0x3A3734)
    static let cardRadius: CGFloat = 10
}

extension Color {
    /// A color that switches between two sRGB hex values with the system appearance.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
                           green: CGFloat((hex >> 8) & 0xff) / 255,
                           blue: CGFloat(hex & 0xff) / 255, alpha: 1)
        })
    }
}
