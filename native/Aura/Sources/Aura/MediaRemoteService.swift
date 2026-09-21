import Foundation
import AppKit

/// Нативный сервис для взаимодействия с системным фреймворком MediaRemote.framework macOS.
/// Позволяет читать метаданные (название, артист, обложка, длительность, прогресс)
/// и управлять воспроизведением (Play, Pause, Next, Prev, Seek) любого медиаплеера macOS,
/// включая YouTube Music и Яндекс Музыку в любых браузерах (Brave, Chrome, Safari) и нативных приложениях.
final class MediaRemoteService: @unchecked Sendable {
    static let shared = MediaRemoteService()

    // MARK: - C API Type Aliases
    private typealias MRGetInfoFunc = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRGetClientFunc = @convention(c) (DispatchQueue, @escaping (OpaquePointer?) -> Void) -> Void
    private typealias MRClientGetStringFunc = @convention(c) (OpaquePointer) -> Unmanaged<CFString>?
    private typealias MRClientGetPIDFunc = @convention(c) (OpaquePointer) -> pid_t
    private typealias MRSendCommandFunc = @convention(c) (Int32, CFDictionary?) -> Bool
    private typealias MRSetElapsedTimeFunc = @convention(c) (Double) -> Void
    private typealias MRRegisterFunc = @convention(c) (DispatchQueue) -> Void
    private typealias MRGetPlaybackStateFunc = @convention(c) (DispatchQueue, @escaping (UInt32) -> Void) -> Void

    // MARK: - Loaded Function Pointers
    private var getInfo: MRGetInfoFunc?
    private var getClient: MRGetClientFunc?
    private var getBundleId: MRClientGetStringFunc?
    private var getDisplayName: MRClientGetStringFunc?
    private var getPID: MRClientGetPIDFunc?
    private var sendCommand: MRSendCommandFunc?
    private var setElapsedTime: MRSetElapsedTimeFunc?
    private var registerForNotifications: MRRegisterFunc?
    private var getPlaybackState: MRGetPlaybackStateFunc?

    private(set) var isAvailable: Bool = false

    struct ClientInfo: Sendable {
        let bundleId: String?
        let displayName: String?
        let pid: pid_t?
    }

    private init() {
        loadFramework()
    }

    private func loadFramework() {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else {
            return
        }

        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) {
            getInfo = unsafeBitCast(ptr, to: MRGetInfoFunc.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingClient" as CFString) {
            getClient = unsafeBitCast(ptr, to: MRGetClientFunc.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetBundleIdentifier" as CFString) {
            getBundleId = unsafeBitCast(ptr, to: MRClientGetStringFunc.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetDisplayName" as CFString) {
            getDisplayName = unsafeBitCast(ptr, to: MRClientGetStringFunc.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetProcessIdentifier" as CFString) {
            getPID = unsafeBitCast(ptr, to: MRClientGetPIDFunc.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) {
            sendCommand = unsafeBitCast(ptr, to: MRSendCommandFunc.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetElapsedTime" as CFString) {
            setElapsedTime = unsafeBitCast(ptr, to: MRSetElapsedTimeFunc.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationPlaybackState" as CFString) {
            getPlaybackState = unsafeBitCast(ptr, to: MRGetPlaybackStateFunc.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) {
            registerForNotifications = unsafeBitCast(ptr, to: MRRegisterFunc.self)
            registerForNotifications?(DispatchQueue.main)
        }

        isAvailable = (getInfo != nil && sendCommand != nil)
    }

    // MARK: - Client & Snapshot Query

    /// Получить системный статус воспроизведения (1 = Playing, 2 = Paused, 3 = Stopped, 4 = Interrupted)
    func fetchPlaybackState() async -> UInt32 {
        guard let getPlaybackState = getPlaybackState else { return 0 }
        return await withCheckedContinuation { continuation in
            getPlaybackState(DispatchQueue.global(qos: .userInitiated)) { state in
                continuation.resume(returning: state)
            }
        }
    }

    /// Получить данные о текущем активном приложении в MediaRemote
    func fetchClient() async -> ClientInfo? {
        guard let getClient = getClient else { return nil }
        return await withCheckedContinuation { continuation in
            getClient(DispatchQueue.global(qos: .userInitiated)) { [weak self] opaqueClient in
                guard let self = self, let client = opaqueClient else {
                    continuation.resume(returning: nil)
                    return
                }
                let bundleId = self.getBundleId?(client)?.takeUnretainedValue() as String?
                let displayName = self.getDisplayName?(client)?.takeUnretainedValue() as String?
                let pid = self.getPID?(client)
                continuation.resume(returning: ClientInfo(bundleId: bundleId, displayName: displayName, pid: pid))
            }
        }
    }

    /// Получить снимок текущего трека из системного Now Playing
    func fetchSnapshot() async -> PlayerSnapshot? {
        guard isAvailable, let getInfo = getInfo else { return nil }
        let client = await fetchClient()

        // Если процесс плеера уже завершён, не используем устаревший кэш
        if let pid = client?.pid, pid > 0 {
            if kill(pid, 0) != 0 && errno == ESRCH {
                return nil
            }
        }

        let playbackState = await fetchPlaybackState()
        let isPlaying = (playbackState == 1) // 1 = Playing

        return await withCheckedContinuation { continuation in
            getInfo(DispatchQueue.global(qos: .userInitiated)) { info in
                let title = (info["kMRMediaRemoteNowPlayingInfoTitle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let artist = (info["kMRMediaRemoteNowPlayingInfoArtist"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0.0
                let position = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0.0
                let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data

                guard !title.isEmpty || !artist.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let appName = client?.displayName ?? client?.bundleId ?? "Media"
                let identifier = info["kMRMediaRemoteNowPlayingInfoContentItemIdentifier"] as? String
                    ?? "\(appName)_\(title)_\(artist)"

                let snapshot = PlayerSnapshot(
                    title: title.isEmpty ? "Неизвестный трек" : title,
                    artist: artist.isEmpty ? appName : artist,
                    duration: duration,
                    position: position,
                    isPlaying: isPlaying,
                    artworkURL: nil,
                    trackId: identifier,
                    appName: appName,
                    artworkData: artworkData
                )
                continuation.resume(returning: snapshot)
            }
        }
    }

    /// Получить снимок для конкретного источника Aura
    func fetchSnapshot(for source: Source) async -> PlayerSnapshot? {
        guard let snapshot = await fetchSnapshot() else { return nil }

        let client = await fetchClient()
        let bundleId = client?.bundleId?.lowercased() ?? ""
        let appName = (client?.displayName ?? snapshot.appName).lowercased()

        let isBrowser = bundleId.contains("brave")
            || bundleId.contains("chrome")
            || bundleId.contains("safari")
            || bundleId.contains("arc")
            || bundleId.contains("firefox")
            || bundleId.contains("edge")
            || bundleId.contains("opera")
            || appName.contains("browser")
            || appName.contains("chrome")
            || appName.contains("safari")

        switch source {
        case .youtubeMusic:
            // YouTube Music: проверяем PWA, десктопное приложение или любой браузер
            let isYT = bundleId.contains("youtube")
                || appName.contains("youtube")
                || snapshot.title.lowercased().contains("youtube")
                || isBrowser
            return isYT ? snapshot : nil

        case .yandexMusic:
            // Яндекс Музыка: официальное приложение ru.yandex.music или воспроизведение в браузере
            let isYandex = bundleId.contains("yandex")
                || appName.contains("яндекс")
                || appName.contains("yandex")
                || snapshot.title.lowercased().contains("яндекс")
                || isBrowser
            return isYandex ? snapshot : nil

        case .nowPlaying, .auto:
            return snapshot

        default:
            return snapshot
        }
    }

    // MARK: - Playback Controls

    /// Play / Pause toggle
    func togglePlayPause() {
        guard isAvailable else { return }
        _ = sendCommand?(2, nil) // 2 = kMRTogglePlayPause
    }

    func play() {
        guard isAvailable else { return }
        _ = sendCommand?(0, nil) // 0 = kMRPlay
    }

    func pause() {
        guard isAvailable else { return }
        _ = sendCommand?(1, nil) // 1 = kMRPause
    }

    func nextTrack() {
        guard isAvailable else { return }
        _ = sendCommand?(4, nil) // 4 = kMRNextTrack
    }

    func prevTrack() {
        guard isAvailable else { return }
        _ = sendCommand?(5, nil) // 5 = kMRPreviousTrack
    }

    func seek(to seconds: Double) {
        guard isAvailable else { return }
        setElapsedTime?(seconds)
    }
}
