import SwiftUI
import AppKit

struct Theme {
    /// Dynamic accent colour — updated by AccentColorManager whenever the user
    /// picks a new colour. Stored as nonisolated(unsafe) so SwiftUI views,
    /// AppKit draw methods, and other nonisolated contexts can read it freely.
    nonisolated(unsafe) static var accent: Color = AccentColorManager.loadColorSync()

    static let accentSecondary = Color(red: 0.85, green: 0.27, blue: 0.94) // Neon Magenta (#D946EF)
    static let magenta = accentSecondary                                    // Neon Magenta alias
    static let accentBlue = Color(red: 0.23, green: 0.51, blue: 0.96)      // Deep Royal Blue (#3B82F6)
    static var accentHover: Color { accent.opacity(0.85) }
    static let green = Color(red: 0.12, green: 0.84, blue: 0.53)          // Neon Mint / Spotify
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.15)          // Warm Neon Orange
    static let yellow = Color(red: 0.98, green: 0.73, blue: 0.01)         // Amber Gold

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var auraGlowGradient: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.85), accentSecondary.opacity(0.85), accentBlue.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var background: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.045, green: 0.065, blue: 0.105, alpha: 1.0) // Space Navy (#0B101B)
                : NSColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
        }))
    }
    
    static var sidebarBackground: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.03, green: 0.045, blue: 0.075, alpha: 1.0) // Deep Space Dark (#070B13)
                : NSColor(red: 0.92, green: 0.94, blue: 0.97, alpha: 1.0)
        }))
    }
    
    static var cardBackground: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.08, green: 0.11, blue: 0.18, alpha: 0.72) // Glassmorphic dark navy
                : NSColor(white: 1.0, alpha: 0.85)
        }))
    }
    
    static var cardBorder: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.14) // Subtle cyan neon edge
                : NSColor(red: 0.10, green: 0.20, blue: 0.40, alpha: 0.10)
        }))
    }
    
    static var textPrimary: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 1.0)
                : NSColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1.0)
        }))
    }
    
    static var textSecondary: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.65, green: 0.72, blue: 0.82, alpha: 1.0) // Cool slate secondary
                : NSColor(red: 0.40, green: 0.45, blue: 0.55, alpha: 1.0)
        }))
    }
    
    static var textTertiary: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.42, green: 0.48, blue: 0.58, alpha: 1.0)
                : NSColor(red: 0.60, green: 0.64, blue: 0.72, alpha: 1.0)
        }))
    }
}
