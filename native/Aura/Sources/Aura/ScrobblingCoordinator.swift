import Foundation

/// Coordinates Last.fm now-playing notifications, scrobble threshold evaluation, and queue flushing.
@MainActor final class ScrobblingCoordinator {
    static let shared = ScrobblingCoordinator()

    private var hasScrobbledCurrentTrack: Bool = false
    private var nowPlayingUpdatedForTrackId: String = ""
    private var lastScrobbledTrackId: String = ""

    private init() {}

    /// Стандартное правило Last.fm: 50% длины трека или 4 минуты (240 сек), но не менее 30 секунд.
    func threshold(for duration: Double) -> Double {
        guard duration > 0 else { return 30.0 }
        return max(30.0, min(duration * 0.5, 240.0))
    }

    /// Вызывается при начале воспроизведения нового трека
    func onNewTrackStarted(title: String, artist: String, duration: Double, trackId: String? = nil) {
        guard !title.isEmpty && !artist.isEmpty else { return }
        let currentId = trackId ?? "\(title)-\(artist)"
        
        hasScrobbledCurrentTrack = (currentId == lastScrobbledTrackId)
        
        if nowPlayingUpdatedForTrackId != currentId {
            nowPlayingUpdatedForTrackId = currentId
            Task {
                await LastFMService.shared.updateNowPlaying(title: title, artist: artist, duration: duration)
            }
        }
    }

    /// Проверка прогресса воспроизведения и отправка скроббла при достижении порога
    func handleTrackProgress(title: String, artist: String, duration: Double, position: Double, isPlaying: Bool, trackId: String? = nil) {
        guard isPlaying, !hasScrobbledCurrentTrack, !title.isEmpty, !artist.isEmpty, duration >= 30.0 else { return }

        let scrobbleThreshold = threshold(for: duration)
        if position >= scrobbleThreshold {
            hasScrobbledCurrentTrack = true
            let currentId = trackId ?? "\(title)-\(artist)"
            lastScrobbledTrackId = currentId

            let timestamp = Date().addingTimeInterval(-position)
            Task {
                await LastFMService.shared.scrobble(title: title, artist: artist, timestamp: timestamp)
            }
        }
    }

    /// Сброс накопленной офлайн-очереди
    func flushPendingScrobbles() async {
        guard !LastFMService.shared.pendingScrobbles.isEmpty else { return }
        await LastFMService.shared.flushPendingScrobbles()
    }
}
