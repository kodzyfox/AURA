import AppKit
import SwiftUI

/// Coordinates wallpaper lifecycle, debounce scheduling, and screen layout changes.
@MainActor final class WallpaperCoordinator {
    static let shared = WallpaperCoordinator()

    private var debounceTask: Task<Void, Never>?
    private var lastUpdateParams: (enabled: Bool, playing: Bool, playerName: String?, image: NSImage?, tint: Color?, style: WallpaperStyle, settings: Atmosphere, trackInfo: WallpaperTrackInfo?, isScreenLocked: Bool)?

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenChange()
            }
        }
    }

    func scheduleUpdate(
        delay: Double = 0.15,
        enabled: Bool,
        playing: Bool,
        playerName: String?,
        image: NSImage?,
        tint: Color?,
        style: WallpaperStyle,
        settings: Atmosphere,
        trackInfo: WallpaperTrackInfo?,
        isScreenLocked: Bool
    ) {
        lastUpdateParams = (enabled, playing, playerName, image, tint, style, settings, trackInfo, isScreenLocked)

        guard enabled, playing, playerName != nil, image != nil else {
            debounceTask?.cancel()
            restore()
            return
        }

        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard !Task.isCancelled, let self = self else { return }
            self.update(
                enabled: enabled,
                playing: playing,
                playerName: playerName,
                image: image,
                tint: tint,
                style: style,
                settings: settings,
                trackInfo: trackInfo,
                isScreenLocked: isScreenLocked
            )
        }
    }

    func update(
        enabled: Bool,
        playing: Bool,
        playerName: String?,
        image: NSImage?,
        tint: Color?,
        style: WallpaperStyle,
        settings: Atmosphere,
        trackInfo: WallpaperTrackInfo?,
        isScreenLocked: Bool
    ) {
        guard enabled, playing, playerName != nil, let image else {
            WallpaperManager.shared.restoreOriginalWallpaper()
            return
        }
        WallpaperManager.shared.setDynamicWallpaper(
            from: image,
            tint: tint,
            style: style,
            settings: settings,
            trackInfo: trackInfo,
            isScreenLocked: isScreenLocked
        )
    }

    func restore() {
        debounceTask?.cancel()
        WallpaperManager.shared.restoreOriginalWallpaper()
    }

    private func handleScreenChange() {
        WallpaperManager.shared.handleScreenParametersChanged()
        if let p = lastUpdateParams, p.enabled && p.playing {
            scheduleUpdate(
                delay: 0.4,
                enabled: p.enabled,
                playing: p.playing,
                playerName: p.playerName,
                image: p.image,
                tint: p.tint,
                style: p.style,
                settings: p.settings,
                trackInfo: p.trackInfo,
                isScreenLocked: p.isScreenLocked
            )
        }
    }
}
