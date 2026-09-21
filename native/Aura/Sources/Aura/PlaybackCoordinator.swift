import Foundation

/// Coordinates playback commands without exposing player-specific details to SwiftUI.
@MainActor final class PlaybackCoordinator {
    private let local: LocalPlaybackService
    private let external: ExternalPlayerService

    init(local: LocalPlaybackService? = nil, external: ExternalPlayerService? = nil) {
        self.local = local ?? .shared
        self.external = external ?? .shared
    }

    func toggle(source: Source, activePlayerName: String?, hasLocalFiles: Bool, onOpenLocalFiles: () -> Void) {
        if source == .local {
            guard hasLocalFiles else { onOpenLocalFiles(); return }
            local.toggle()
            return
        }
        let app = activePlayerName == "Spotify" || source == .spotify ? "Spotify" : "Music"
        external.toggle(appName: app)
    }

    func skip(source: Source, activePlayerName: String?, direction: Int, hasLocalFiles: Bool, onOpenLocalFiles: () -> Void, onLocalSkip: (Int) -> Void) {
        if source == .local {
            guard hasLocalFiles else { onOpenLocalFiles(); return }
            onLocalSkip(direction)
            return
        }
        let app = activePlayerName == "Spotify" || source == .spotify ? "Spotify" : "Music"
        external.skip(appName: app, forward: direction > 0)
    }

    func seek(source: Source, activePlayerName: String?, position: Double, onLocalSeek: (Double) -> Void) {
        if source == .local {
            local.seek(to: position)
            onLocalSeek(position)
            return
        }
        let app = activePlayerName == "Spotify" || source == .spotify ? "Spotify" : "Music"
        external.seek(appName: app, position: position)
    }
}
