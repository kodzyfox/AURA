import Foundation

/// Facade for AppleScript-backed external players (Spotify and Apple Music).
@MainActor final class ExternalPlayerService {
    static let shared = ExternalPlayerService()
    private init() {}

    func isAppRunning(bundleID: String) -> Bool {
        PlayerAutomationService.shared.isAppRunning(bundleID: bundleID)
    }

    func fetchPlayerState(appName: String) async -> String? {
        await PlayerAutomationService.shared.fetchPlayerStateString(appName: appName)
    }

    func fetchSnapshot(bundleID: String, appName: String, isSpotify: Bool) async -> Result<PlayerSnapshot?, PlayerAutomationError> {
        await PlayerAutomationService.shared.fetchPlayerState(bundleID: bundleID, appName: appName, isSpotify: isSpotify)
    }

    func toggle(appName: String) {
        Task { await PlayerAutomationService.shared.playPause(appName: appName) }
    }

    func skip(appName: String, forward: Bool) {
        Task { await PlayerAutomationService.shared.skip(appName: appName, forward: forward) }
    }

    func seek(appName: String, position: Double) {
        Task { await PlayerAutomationService.shared.seek(appName: appName, position: position) }
    }
}
