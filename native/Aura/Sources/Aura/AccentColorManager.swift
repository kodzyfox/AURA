import SwiftUI
import AppKit

/// Manages a user-selectable accent color for the Aura UI.
/// - `select(_:)` writes the chosen colour both to `Theme.accent` (nonisolated
///   stored var) and to UserDefaults so the choice persists across launches.
/// - `loadColorSync()` is a static, nonisolated function used at app startup
///   to seed `Theme.accent` before any actor runs.
@MainActor final class AccentColorManager: ObservableObject {
    static let shared = AccentColorManager()

    private nonisolated static let key = "aura.accentColorRGBA"

    // MARK: - Default palette

    static let palette: [(name: String, color: Color)] = [
        ("Cyan",    Color(red: 0.00, green: 0.95, blue: 1.00)),
        ("Magenta", Color(red: 0.85, green: 0.27, blue: 0.94)),
        ("Mint",    Color(red: 0.12, green: 0.84, blue: 0.53)),
        ("Blue",    Color(red: 0.23, green: 0.51, blue: 0.96)),
        ("Orange",  Color(red: 1.00, green: 0.55, blue: 0.15)),
        ("Gold",    Color(red: 0.98, green: 0.73, blue: 0.01)),
        ("Rose",    Color(red: 1.00, green: 0.30, blue: 0.45)),
        ("Indigo",  Color(red: 0.45, green: 0.35, blue: 0.95)),
        ("Teal",    Color(red: 0.10, green: 0.78, blue: 0.75)),
        ("Lime",    Color(red: 0.60, green: 0.92, blue: 0.10)),
    ]

    /// ObservableObject-published colour — triggers SwiftUI view updates.
    @Published private(set) var accent: Color

    private init() {
        accent = AccentColorManager.loadColorSync()
    }

    // MARK: - Public API

    /// Apply a palette or arbitrary colour; propagates to Theme and UserDefaults.
    func select(_ color: Color) {
        withAnimation(.easeInOut(duration: 0.25)) {
            accent = color
        }
        // Update the global Theme property so non-SwiftUI code picks it up instantly
        Theme.accent = color
        saveColor(color)
    }

    func selectCustom(_ color: Color) { select(color) }

    func resetToDefault() { select(AccentColorManager.palette[0].color) }

    // MARK: - Persistence helpers

    /// Nonisolated static function — called from Theme.accent's initializer
    /// before the MainActor is available. Safe because UserDefaults is thread-safe.
    nonisolated static func loadColorSync() -> Color {
        guard let data = UserDefaults.standard.data(forKey: key),
              let rgba = try? JSONDecoder().decode([Double].self, from: data),
              rgba.count == 4 else {
            return Color(red: 0.00, green: 0.95, blue: 1.00) // electric cyan default
        }
        return Color(red: rgba[0], green: rgba[1], blue: rgba[2], opacity: rgba[3])
    }

    private func saveColor(_ color: Color) {
        let ns = NSColor(color).usingColorSpace(.deviceRGB)
            ?? NSColor(red: 0, green: 0.95, blue: 1, alpha: 1)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgba: [Double] = [Double(r), Double(g), Double(b), Double(a)]
        if let data = try? JSONEncoder().encode(rgba) {
            UserDefaults.standard.set(data, forKey: AccentColorManager.key)
        }
    }
}
