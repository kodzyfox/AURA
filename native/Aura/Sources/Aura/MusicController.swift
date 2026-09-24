import AppKit
import AVFoundation
import Combine
import SwiftUI

/// Main SwiftUI facade coordinating playback, artwork, scrobbling, wallpaper, presets, and widget state.
@MainActor final class MusicController: ObservableObject {
    // MARK: - Dedicated Coordinators & Services
    private let playbackCoordinator = PlaybackCoordinator()
    private let localPlaybackService = LocalPlaybackService.shared
    private let externalPlayerService = ExternalPlayerService.shared
    private let artworkService = ArtworkService.shared
    private let scrobblingCoordinator = ScrobblingCoordinator.shared
    private let wallpaperCoordinator = WallpaperCoordinator.shared
    private let widgetStateExporter = WidgetStateExporter.shared
    private let presetStore = PresetStore.shared
    private let browserPlayerService = BrowserPlayerService.shared
    private let mediaRemoteService = MediaRemoteService.shared

    // MARK: - State Properties for SwiftUI
    @Published var source: Source = {
        if let raw = UserDefaults.standard.string(forKey: "aura.selectedSource"),
           let s = Source(rawValue: raw) {
            return s
        }
        return .auto
    }() {
        didSet {
            UserDefaults.standard.set(source.rawValue, forKey: "aura.selectedSource")
        }
    }

    @Published var activePlayerName: String? {
        didSet {
            if activePlayerName != oldValue {
                handlePlaybackChange()
                DesktopOverlayManager.shared.updateOverlayState()
            NotchOverlayManager.shared.updateOverlayState()
            }
        }
    }
    @Published var title = "Weightless"
    @Published var artist = "Marconi Union"
    @Published var playing = false {
        didSet {
            if playing != oldValue {
                if playing {
                    lastPositionDate = Date()
                }
                handlePlaybackChange()
                DesktopOverlayManager.shared.updateOverlayState()
            NotchOverlayManager.shared.updateOverlayState()
                exportWidgetState()
            }
        }
    }
    @Published var position: Double = 154 {
        didSet {
            lastPositionDate = Date()
        }
    }
    @Published var duration: Double = 489

    // Точная субсекундная отметка для плавной 60 FPS интерполяции позиции трека
    private(set) var lastPositionDate = Date()

    /// Текущая расчетная позиция трека с субсекундной точностью
    func currentPlaybackPosition(at date: Date = Date()) -> Double {
        if source == .local {
            return localPlaybackService.currentTime
        }
        guard playing else { return position }
        let elapsed = max(0, date.timeIntervalSince(lastPositionDate))
        return min(duration, position + elapsed)
    }

    @Published var artwork: NSImage? {
        didSet {
            updateArtworkColor()
            exportWidgetState()
        }
    }
    @Published var artworkColor: Color?
    /// Массив из 3 доминантных цветов обложки (для многоцветного свечения)
    @Published var artworkPalette: [Color] = []
    @Published var isLiked: Bool = false

    func toggleLike() {
        isLiked.toggle()
        let t = title
        let a = artist
        let liked = isLiked
        exportWidgetState()
        Task {
            await LastFMService.shared.toggleLove(title: t, artist: a, isLoved: liked)
        }
    }

    @Published var message: String?
    @Published var isCoverMode: Bool = false
    @Published var isMiniPlayer: Bool = false
    @Published var isScreenLocked: Bool = false

    @Published var wallpaperStyle: WallpaperStyle = {
        if let raw = UserDefaults.standard.string(forKey: "aura.wallpaperStyle"),
           let style = WallpaperStyle(rawValue: raw) {
            return style
        }
        return .poster
    }() {
        didSet {
            UserDefaults.standard.set(wallpaperStyle.rawValue, forKey: "aura.wallpaperStyle")
            scheduleWallpaperUpdate(delay: 0)
        }
    }

    @Published var dynamicWallpaperEnabled: Bool = UserDefaults.standard.bool(forKey: "aura.dynamicWallpaper") {
        didSet {
            UserDefaults.standard.set(dynamicWallpaperEnabled, forKey: "aura.dynamicWallpaper")
            if dynamicWallpaperEnabled {
                scheduleWallpaperUpdate(delay: 0)
            } else {
                wallpaperCoordinator.restore()
            }
        }
    }

    @Published var settings = Atmosphere() {
        didSet {
            saveSettings()
            scheduleWallpaperUpdate(delay: 0.15)
            DesktopOverlayManager.shared.updateOverlayState()
            NotchOverlayManager.shared.updateOverlayState()
        }
    }

    @Published var presets: [SavedPreset] = [] {
        didSet {
            presetStore.save(presets)
        }
    }

    // MARK: - Громкость и Mute
    @Published var volume: Double = 0.65 {
        didSet {
            localPlaybackService.setVolume(volume)
            if volume > 0 && isMuted {
                isMuted = false
            }
        }
    }
    @Published var isMuted: Bool = false
    private var unmutedVolume: Double = 0.65

    func toggleMute() {
        if isMuted {
            isMuted = false
            volume = unmutedVolume > 0 ? unmutedVolume : 0.65
        } else {
            unmutedVolume = volume > 0 ? volume : 0.65
            isMuted = true
            volume = 0
        }
    }

    // MARK: - Локальная медиатека и Очередь треков
    @Published var localQueue: [LocalTrackItem] = []
    @Published var localFileIndex: Int = 0

    var hasLocalFiles: Bool { !localQueue.isEmpty }

    // MARK: - Internal State
    private var demoIndex = 0
    private var blocked = false
    private var lastArtworkKey = ""
    private var artworkTask: Task<Void, Never>?
    private var restoreWallpaperTask: Task<Void, Never>?
    private var isPollingInFlight = false
    private var pollTask: Task<Void, Never>?
    private var lastPollStartTime: Date = .distantPast
    private var pollCount = 0
    private var activityAssertion: NSObjectProtocol?
    private var backgroundTimer: Timer?

    private let demos: [(String, String, Double)] = [
        ("Weightless", "Marconi Union", 489),
        ("A Walk", "Tycho", 316),
        ("An Ending (Ascent)", "Brian Eno", 266)
    ]

    var fallback: NSImage? {
        Bundle.main.url(forResource: "aura_cover", withExtension: "jpg").flatMap { NSImage(contentsOf: $0) }
            ?? Bundle.main.url(forResource: "desert", withExtension: "jpg").flatMap { NSImage(contentsOf: $0) }
            ?? Bundle.main.url(forResource: "AppIcon", withExtension: "png").flatMap { NSImage(contentsOf: $0) }
    }

    var currentTrackKey: String {
        "\(activePlayerName ?? source.rawValue):\(title):\(artist)"
    }

    // MARK: - Initialization & Lifecycle
    init() {
        if let data = UserDefaults.standard.data(forKey: "aura.settings"),
           let value = try? JSONDecoder().decode(Atmosphere.self, from: data) {
            settings = value
        }
        presets = presetStore.load()

        // Предотвращаем замедление и усыпление таймера при выключенном дисплее (App Nap)
        activityAssertion = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical],
            reason: "Aura continuous music monitoring and Last.fm scrobbler"
        )

        // Подписка на системные оповещения плееров Spotify и Apple Music
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            DispatchQueue.main.async { self?.handlePlaybackNotification(notification, appName: "Spotify") }
        }

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            DispatchQueue.main.async { self?.handlePlaybackNotification(notification, appName: "Apple Music") }
        }

        // Подписка на системные оповещения MediaRemote (системные медиаклавиши, браузеры, Now Playing)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationPlaybackStateDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.poll() }
        }
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.poll() }
        }

        // Блокировка/разблокировка экрана Mac
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isScreenLocked = true
                self?.scheduleWallpaperUpdate(delay: 0)
            }
        }

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isScreenLocked = false
                self?.scheduleWallpaperUpdate(delay: 0)
            }
        }

        // Реакция на выход из сна Mac
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isPollingInFlight = false
                self?.poll()
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await self?.scrobblingCoordinator.flushPendingScrobbles()
                }
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isPollingInFlight = false
                self?.poll()
            }
        }

        // Автопереход к следующему локальному треку при завершении
        LocalAudioService.shared.onTrackDidFinish = { [weak self] in
            Task { @MainActor in
                guard let self = self, self.source == .local else { return }
                self.scrobblingCoordinator.handleTrackProgress(
                    title: self.title,
                    artist: self.artist,
                    duration: self.duration,
                    position: self.position,
                    isPlaying: true
                )
                if self.localFileIndex + 1 < self.localQueue.count {
                    self.localFileIndex += 1
                    self.loadLocal()
                } else {
                    self.playing = false
                }
            }
        }

        updateArtworkColor()
        poll()

        // Фоновый опрос плееров и обновление статуса
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        backgroundTimer = timer
    }

    deinit {
        backgroundTimer?.invalidate()
        if let token = activityAssertion {
            ProcessInfo.processInfo.endActivity(token)
        }
    }

    // MARK: - Playback Control (Coordinated)
    func toggle() {
        if source == .demo {
            playing.toggle()
            return
        }
        if source == .youtubeMusic || source == .yandexMusic || source == .nowPlaying {
            mediaRemoteService.togglePlayPause()
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                poll()
            }
            return
        }
        playbackCoordinator.toggle(
            source: source,
            activePlayerName: activePlayerName,
            hasLocalFiles: hasLocalFiles,
            onOpenLocalFiles: openFiles
        )
        if source == .local {
            playing = localPlaybackService.isPlaying
        } else {
            poll()
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 180_000_000)
                self?.poll()
            }
        }
    }

    func seek(_ value: Double) {
        let target = max(0, min(value, duration))
        position = target
        if source == .youtubeMusic || source == .yandexMusic || source == .nowPlaying {
            mediaRemoteService.seek(to: target)
            return
        }
        playbackCoordinator.seek(source: source, activePlayerName: activePlayerName, position: target) { [weak self] pos in
            self?.position = pos
        }
    }

    func skip(_ direction: Int) {
        if source == .demo {
            demoIndex = (demoIndex + direction + demos.count) % demos.count
            loadDemo()
            return
        }
        if source == .local {
            guard !localQueue.isEmpty else { openFiles(); return }
            localFileIndex = (localFileIndex + direction + localQueue.count) % localQueue.count
            loadLocal()
            return
        }
        if source == .youtubeMusic || source == .yandexMusic || source == .nowPlaying {
            if direction > 0 {
                mediaRemoteService.nextTrack()
            } else {
                mediaRemoteService.prevTrack()
            }
            Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                poll()
            }
            return
        }

        playbackCoordinator.skip(
            source: source,
            activePlayerName: activePlayerName,
            direction: direction,
            hasLocalFiles: hasLocalFiles,
            onOpenLocalFiles: openFiles,
            onLocalSkip: { [weak self] value in
                guard let self = self, !self.localQueue.isEmpty else { return }
                self.localFileIndex = (self.localFileIndex + value + self.localQueue.count) % self.localQueue.count
                self.loadLocal()
            }
        )
        if source != .local { poll() }
    }

    func select(_ value: Source) {
        if value != .local {
            localPlaybackService.pause()
            if AudioAnalysisService.shared.analysisMode == .localFFT {
                AudioAnalysisService.shared.setMode(.beatGrid)
            }
        }
        artworkTask?.cancel()
        source = value
        artwork = nil
        lastArtworkKey = ""
        blocked = false
        message = nil

        if value == .demo {
            AudioAnalysisService.shared.setMode(.beatGrid)
            loadDemo()
            playing = true
        } else if value == .local {
            AudioAnalysisService.shared.setMode(.localFFT)
            title = L10n.current == .ru ? "Ваша музыка" : "Your Music"
            artist = L10n.current == .ru ? "Откройте аудиофайл" : "Open an Audio File"
            if localQueue.isEmpty { openFiles() } else { loadLocal() }
        } else if value == .youtubeMusic || value == .yandexMusic || value == .nowPlaying {
            AudioAnalysisService.shared.setMode(.beatGrid)
            title = value.localizedName
            artist = L10n.current == .ru ? "Ожидание воспроизведения" : "Waiting for playback"
            poll()
        } else {
            poll()
        }
    }

    // MARK: - Local & Demo Playback
    func openFiles() {
        if let selected = localPlaybackService.chooseAudioFiles() {
            addLocalFiles(selected)
        }
    }

    func addLocalFiles(_ urls: [URL]) {
        let audioURLs = localPlaybackService.collectAudioFiles(from: urls)
        guard !audioURLs.isEmpty else {
            AppNotificationManager.shared.show(
                type: .warning,
                title: L10n.current == .ru ? "Файлы не найдены" : "No Audio Files",
                message: L10n.current == .ru ? "Поддерживаются форматы MP3, M4A, WAV, FLAC, AIFF" : "Supported formats: MP3, M4A, WAV, FLAC, AIFF"
            )
            return
        }

        let newItems = audioURLs.map { localPlaybackService.makeQueueItem(from: $0) }
        let wasEmpty = localQueue.isEmpty
        localQueue.append(contentsOf: newItems)

        if wasEmpty || source != .local {
            select(.local)
            localFileIndex = wasEmpty ? 0 : (localQueue.count - newItems.count)
            loadLocal()
        }

        AppNotificationManager.shared.show(
            type: .success,
            title: L10n.current == .ru ? "Очередь пополнена" : "Queue Updated",
            message: L10n.current == .ru ? "Добавлено треков: \(newItems.count)" : "Added \(newItems.count) tracks"
        )
    }

    func playQueueTrack(at index: Int) {
        guard localQueue.indices.contains(index) else { return }
        localFileIndex = index
        if source != .local {
            select(.local)
        } else {
            loadLocal()
        }
    }

    func removeFromQueue(at index: Int) {
        guard localQueue.indices.contains(index) else { return }
        let isCurrent = (index == localFileIndex)
        localQueue.remove(at: index)

        if localQueue.isEmpty {
            localPlaybackService.stop()
            playing = false
            activePlayerName = nil
            title = L10n.current == .ru ? "Ваша музыка" : "Your Music"
            artist = L10n.current == .ru ? "Очередь пуста" : "Queue is Empty"
            artwork = nil
            localFileIndex = 0
            handlePlaybackChange()
            return
        }

        if isCurrent {
            localFileIndex = min(localFileIndex, localQueue.count - 1)
            loadLocal()
        } else if index < localFileIndex {
            localFileIndex -= 1
        }
    }

    func clearQueue() {
        localPlaybackService.stop()
        localQueue.removeAll()
        localFileIndex = 0
        playing = false
        activePlayerName = nil
        title = L10n.current == .ru ? "Ваша музыка" : "Your Music"
        artist = L10n.current == .ru ? "Очередь пуста" : "Queue is Empty"
        artwork = nil
        handlePlaybackChange()
    }

    private func loadLocal() {
        guard localQueue.indices.contains(localFileIndex) else { return }
        localPlaybackService.stop()
        artwork = nil
        message = nil
        let item = localQueue[localFileIndex]

        do {
            try localPlaybackService.load(item.url)
            localPlaybackService.setVolume(volume)
            duration = localPlaybackService.duration
            position = 0
            playing = localPlaybackService.play()
            AudioAnalysisService.shared.setMode(.localFFT)

            title = item.title
            artist = item.artist

            Task { [weak self, url = item.url, currentIndex = self.localFileIndex] in
                guard let self = self else { return }
                let meta = await self.localPlaybackService.extractMetadata(
                    from: url,
                    fallbackTitle: self.title,
                    fallbackArtist: self.artist
                )
                if !Task.isCancelled && self.localFileIndex == currentIndex {
                    self.title = meta.title
                    self.artist = meta.artist
                    self.artwork = meta.artwork
                    if meta.duration > 0 {
                        self.duration = meta.duration
                    }
                    if self.localQueue.indices.contains(currentIndex) {
                        self.localQueue[currentIndex].title = meta.title
                        self.localQueue[currentIndex].artist = meta.artist
                        self.localQueue[currentIndex].duration = self.duration
                    }
                    self.updateArtworkColor()
                    self.onNewTrackStarted(title: self.title, artist: self.artist, duration: self.duration)
                }
            }
        } catch {
            playing = false
            message = L10n.current == .ru ? "Не удалось открыть \(item.url.lastPathComponent). \(error.localizedDescription)" : "Failed to open \(item.url.lastPathComponent). \(error.localizedDescription)"
            AppNotificationManager.shared.show(
                type: .error,
                title: L10n.current == .ru ? "Ошибка воспроизведения" : "Playback Error",
                message: message ?? ""
            )
        }
    }

    private func loadDemo() {
        let t = demos[demoIndex]
        title = t.0
        artist = t.1
        duration = t.2
        position = 0
        artwork = nil
        updateArtworkColor()
        onNewTrackStarted(title: title, artist: artist, duration: duration)
    }

    // MARK: - Presets
    func savePreset(_ name: String) {
        presetStore.addPreset(name: name, settings: settings, to: &presets)
    }

    func exportPresets() {
        if presetStore.exportPresetsToFile(presets: presets) {
            AppNotificationManager.shared.show(
                type: .success,
                title: L10n.current == .ru ? "Экспорт выполнен" : "Export Complete",
                message: L10n.current == .ru ? "Файл пресетов успешно сохранен" : "Presets file saved successfully"
            )
        }
    }

    func importPresets() {
        let count = presetStore.importPresetsFromFile(into: &presets)
        if count > 0 {
            AppNotificationManager.shared.show(
                type: .success,
                title: L10n.current == .ru ? "Импорт завершен" : "Import Complete",
                message: L10n.current == .ru ? "Добавлено пресетов: \(count)" : "Imported \(count) presets"
            )
        } else if count == 0 {
            AppNotificationManager.shared.show(
                type: .info,
                title: L10n.current == .ru ? "Нет новых пресетов" : "No New Presets",
                message: L10n.current == .ru ? "Все пресеты из файла уже добавлены" : "All presets are already present"
            )
        } else {
            AppNotificationManager.shared.show(
                type: .error,
                title: L10n.current == .ru ? "Ошибка импорта" : "Import Failed",
                message: L10n.current == .ru ? "Неверный формат файла пресетов" : "Invalid presets file format"
            )
        }
    }

    // MARK: - Wallpaper & Overlay Coordination
    func scheduleWallpaperUpdate(delay: Double = 0.15) {
        guard dynamicWallpaperEnabled, playing, activePlayerName != nil else {
            wallpaperCoordinator.restore()
            DesktopOverlayManager.shared.updateOverlayState()
            NotchOverlayManager.shared.updateOverlayState()
            return
        }
        let info = WallpaperTrackInfo(
            title: title,
            artist: artist,
            progress: position / max(1, duration),
            position: position,
            duration: duration,
            isPlaying: playing
        )
        wallpaperCoordinator.scheduleUpdate(
            delay: delay,
            enabled: dynamicWallpaperEnabled,
            playing: playing,
            playerName: activePlayerName,
            image: artwork ?? fallback,
            tint: artworkColor,
            style: wallpaperStyle,
            settings: settings,
            trackInfo: info,
            isScreenLocked: isScreenLocked
        )
    }

    private func handlePlaybackChange() {
        restoreWallpaperTask?.cancel()
        if playing && activePlayerName != nil {
            scheduleWallpaperUpdate(delay: 0.15)
        } else {
            // Обои восстанавливаем мгновенно
            wallpaperCoordinator.restore()
            // Оверлей убираем через updateOverlayState чтобы сработала плавная анимация fadeOut (380мс)
            DesktopOverlayManager.shared.updateOverlayState()
            NotchOverlayManager.shared.updateOverlayState()
        }
    }

    private func updateArtworkColor() {
        if let image = artwork ?? fallback {
            artworkColor = ColorExtractor.extractDominantColor(from: image)
            // Извлекаем палитру из нескольких доминантных цветов (async, чтобы не блокировать UI)
            let img = image
            Task { @MainActor [weak self] in
                let palette = await Task.detached(priority: .utility) {
                    ColorExtractor.extractPalette(from: img, count: 3)
                }.value
                self?.artworkPalette = palette
            }
            if playing && activePlayerName != nil {
                scheduleWallpaperUpdate(delay: 0.15)
            }
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "aura.settings")
        }
    }

    // MARK: - Polling & Synchronization
    func poll() {
        pollCount += 1
        if pollCount % 30 == 0 {
            Task { await scrobblingCoordinator.flushPendingScrobbles() }
        }

        if source == .demo {
            if playing {
                position = min(position + 1, duration)
                if position >= duration { skip(1) }
            }
            activePlayerName = L10n.current == .ru ? "Деморежим" : "Demo Mode"
            return
        }

        if source == .local {
            activePlayerName = L10n.current == .ru ? "Локальный файл" : "Local File"
            position = localPlaybackService.currentTime
            if playing && !localPlaybackService.isPlaying {
                playing = false
            }
            scrobblingCoordinator.handleTrackProgress(
                title: title,
                artist: artist,
                duration: duration,
                position: position,
                isPlaying: playing
            )
            return
        }

        guard !blocked else { return }

        // Watchdog: сброс зависшего опроса > 3.5 сек
        if isPollingInFlight && Date().timeIntervalSince(lastPollStartTime) > 3.5 {
            isPollingInFlight = false
            pollTask?.cancel()
        }

        guard !isPollingInFlight else { return }
        isPollingInFlight = true
        lastPollStartTime = Date()

        pollTask?.cancel()
        pollTask = Task { @MainActor [weak self] in
            defer { self?.isPollingInFlight = false }
            guard let self = self, !Task.isCancelled else { return }

            if self.source == .auto {
                await self.pollAutoDetect()
            } else if self.source == .spotify {
                await self.pollPlayer(bundleID: "com.spotify.client", appName: "Spotify", isSpotify: true)
            } else if self.source == .music {
                await self.pollPlayer(bundleID: "com.apple.Music", appName: "Music", isSpotify: false)
            } else if self.source == .youtubeMusic || self.source == .yandexMusic || self.source == .nowPlaying {
                await self.pollMediaRemote(source: self.source)
            }
        }
    }

    private func pollAutoDetect() async {
        let spotifyRunning = externalPlayerService.isAppRunning(bundleID: "com.spotify.client")
        let musicRunning = externalPlayerService.isAppRunning(bundleID: "com.apple.Music")

        if spotifyRunning {
            if let state = await externalPlayerService.fetchPlayerState(appName: "Spotify"), state == "playing" {
                await pollPlayer(bundleID: "com.spotify.client", appName: "Spotify", isSpotify: true)
                return
            }
        }

        if musicRunning {
            if let state = await externalPlayerService.fetchPlayerState(appName: "Music"), state == "playing" {
                await pollPlayer(bundleID: "com.apple.Music", appName: "Music", isSpotify: false)
                return
            }
        }

        // Проверяем системный Now Playing (MediaRemote) — если сейчас активно играет трек
        if let mrSnapshot = await mediaRemoteService.fetchSnapshot(), mrSnapshot.isPlaying {
            applySnapshot(mrSnapshot, isSpotify: false)
            return
        }

        if spotifyRunning {
            await pollPlayer(bundleID: "com.spotify.client", appName: "Spotify", isSpotify: true)
            return
        }

        if musicRunning {
            await pollPlayer(bundleID: "com.apple.Music", appName: "Music", isSpotify: false)
            return
        }

        if let mrSnapshot = await mediaRemoteService.fetchSnapshot() {
            if mrSnapshot.isPlaying {
                applySnapshot(mrSnapshot, isSpotify: false)
                return
            } else if activePlayerName != nil {
                applySnapshot(mrSnapshot, isSpotify: false)
                return
            }
        }

        if !hasLocalFiles {
            activePlayerName = nil
            playing = false
            message = L10n.current == .ru
                ? "Включите музыку в Spotify, Apple Music, YouTube Music или Яндекс Музыке"
                : "Start playback in Spotify, Apple Music, YouTube Music, or Yandex Music"
        }
    }

    private func pollPlayer(bundleID: String, appName: String, isSpotify: Bool) async {
        let result = await externalPlayerService.fetchSnapshot(bundleID: bundleID, appName: appName, isSpotify: isSpotify)
        switch result {
        case .success(let snapshot):
            if let snapshot = snapshot {
                applySnapshot(snapshot, isSpotify: isSpotify)
            } else {
                if activePlayerName == appName {
                    playing = false
                    activePlayerName = nil
                }
            }
        case .failure(let error):
            if case .permissionDenied = error {
                blocked = true
                message = L10n.current == .ru ? "Разрешите Aura управлять плеерами: Системные настройки → Конфиденциальность и безопасность → Автоматизация." : "Allow Aura to control players: System Settings → Privacy & Security → Automation."
                AppNotificationManager.shared.show(
                    type: .warning,
                    title: L10n.current == .ru ? "Доступ заблокирован" : "Access Denied",
                    message: L10n.current == .ru ? "Разрешите управление в Системных настройках macOS" : "Grant automation permission in macOS System Settings",
                    actionTitle: L10n.current == .ru ? "Настройки" : "Settings",
                    autoDismissSeconds: 8.0
                ) {
                    AutomationPermissionManager.shared.openPrivacySettings()
                }
            } else if case .notRunning = error {
                if activePlayerName == appName {
                    playing = false
                    activePlayerName = nil
                }
            }
        }
    }

    /// Опрашивает нативный системный фреймворк MediaRemote для YouTube Music / Яндекс Музыки / Системного плеера
    private func pollMediaRemote(source: Source) async {
        if let snapshot = await mediaRemoteService.fetchSnapshot(for: source) {
            applySnapshot(snapshot, isSpotify: false)
            return
        }

        // Резервный опрос вкладок браузера (если трек ещё не запустился в системной аудио-сессии)
        if source == .youtubeMusic || source == .yandexMusic {
            if let browserSnapshot = await browserPlayerService.fetchSnapshot(source: source) {
                let state = await mediaRemoteService.fetchPlaybackState()
                let isPlaying = (state == 1)
                let adjustedSnapshot = PlayerSnapshot(
                    title: browserSnapshot.title,
                    artist: browserSnapshot.artist,
                    duration: browserSnapshot.duration,
                    position: browserSnapshot.position,
                    isPlaying: isPlaying,
                    artworkURL: browserSnapshot.artworkURL,
                    trackId: browserSnapshot.trackId,
                    appName: browserSnapshot.appName,
                    artworkData: browserSnapshot.artworkData
                )
                applySnapshot(adjustedSnapshot, isSpotify: false)
                return
            }
        }

        if playing || activePlayerName != nil {
            playing = false
            activePlayerName = nil
            let name = source.localizedName
            message = L10n.current == .ru
                ? "Включите воспроизведение в \(name)"
                : "Start playback in \(name)"
        }
    }

    private func applySnapshot(_ snapshot: PlayerSnapshot, isSpotify: Bool) {

        message = nil
        let newKey = snapshot.appName + snapshot.title + snapshot.artist

        if newKey != lastArtworkKey {
            // Если предыдущий трек доиграл до порога, но не был отправлен — фиксируем
            scrobblingCoordinator.handleTrackProgress(
                title: self.title,
                artist: self.artist,
                duration: self.duration,
                position: self.position,
                isPlaying: true
            )

            lastArtworkKey = newKey
            artworkTask?.cancel()

            title = snapshot.title
            artist = snapshot.artist
            duration = snapshot.duration
            position = snapshot.position
            lastPositionDate = Date()
            playing = snapshot.isPlaying
            activePlayerName = snapshot.appName

            onNewTrackStarted(title: title, artist: artist, duration: duration, spotifyTrackId: snapshot.trackId)

            // Загрузка обложки: если есть нативные байты обложки из MediaRemote, применяем их мгновенно
            if let artData = snapshot.artworkData, let img = NSImage(data: artData) {
                artworkService.store(img, for: newKey)
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.artwork = img
                }
            } else {
                loadArtwork(key: newKey, directUrl: snapshot.artworkURL, isSpotify: isSpotify)
            }
            scrobblingCoordinator.handleTrackProgress(
                title: title,
                artist: artist,
                duration: duration,
                position: position,
                isPlaying: playing,
                trackId: snapshot.trackId
            )
            return
        }

        // Тот же трек: проверка на повтор (rewind)
        if snapshot.isPlaying && self.position > 10.0 && snapshot.position < (self.position - 5.0) {
            scrobblingCoordinator.handleTrackProgress(
                title: self.title,
                artist: self.artist,
                duration: self.duration,
                position: self.position,
                isPlaying: true
            )
            onNewTrackStarted(title: snapshot.title, artist: snapshot.artist, duration: snapshot.duration, spotifyTrackId: snapshot.trackId)
        }

        title = snapshot.title
        artist = snapshot.artist
        duration = snapshot.duration
        position = snapshot.position
        lastPositionDate = Date()
        playing = snapshot.isPlaying
        activePlayerName = snapshot.appName

        if self.artwork == nil, let artData = snapshot.artworkData, let img = NSImage(data: artData) {
            artworkService.store(img, for: newKey)
            withAnimation(.easeInOut(duration: 0.35)) {
                self.artwork = img
            }
        }

        scrobblingCoordinator.handleTrackProgress(
            title: title,
            artist: artist,
            duration: duration,
            position: position,
            isPlaying: playing,
            trackId: snapshot.trackId
        )
    }

    private func loadArtwork(key: String, directUrl: String?, isSpotify: Bool) {
        if let cached = artworkService.cached(for: key) {
            self.artwork = cached
            return
        }

        artworkTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            let image: NSImage?
            if isSpotify {
                image = await self.artworkService.fetchSpotifyArtwork(
                    key: key,
                    title: self.title,
                    artist: self.artist,
                    directUrl: directUrl
                )
            } else {
                image = await self.artworkService.fetchAppleMusicArtwork(
                    key: key,
                    title: self.title,
                    artist: self.artist
                )
            }

            guard !Task.isCancelled, self.lastArtworkKey == key else { return }
            if let img = image {
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.artwork = img
                }
            }
        }
    }

    private func onNewTrackStarted(title: String, artist: String, duration: Double, spotifyTrackId: String? = nil) {
        isLiked = false
        if source != .local && AudioAnalysisService.shared.analysisMode == .localFFT {
            AudioAnalysisService.shared.setMode(.beatGrid)
        }

        AudioAnalysisService.shared.loadTrack(
            spotifyTrackId: spotifyTrackId,
            title: title,
            artist: artist,
            duration: duration,
            startOffset: position  // передаём текущую позицию для выравнивания ритма
        )

        scrobblingCoordinator.onNewTrackStarted(title: title, artist: artist, duration: duration, trackId: spotifyTrackId)
        exportWidgetState()

        guard !title.isEmpty && !artist.isEmpty else { return }
        Task {
            let isLoved = await LastFMService.shared.checkTrackIsLoved(title: title, artist: artist)
            if self.title == title && self.artist == artist {
                self.isLiked = isLoved
                self.exportWidgetState()
            }
        }
    }

    private func handlePlaybackNotification(_ notification: Notification, appName: String) {
        if let state = notification.userInfo?["Player State"] as? String {
            let isNowPlaying = (state.lowercased() == "playing")
            if self.playing != isNowPlaying && (self.activePlayerName == appName || self.source == .auto) {
                self.playing = isNowPlaying
            }
        }
        poll()
    }

    // MARK: - Window Modes
    func toggleCoverMode() {
        isCoverMode.toggle()
        if isCoverMode { isMiniPlayer = false }

        DispatchQueue.main.async {
            if let window = NSApp.keyWindow {
                if self.isCoverMode && !window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                } else if !self.isCoverMode && window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
        }
    }

    func toggleMiniPlayer() {
        isMiniPlayer.toggle()
        if isMiniPlayer { isCoverMode = false }

        if let window = NSApp.keyWindow {
            window.level = isMiniPlayer ? .floating : .normal
        }
    }

    func fullScreen() {
        NSApp.keyWindow?.toggleFullScreen(nil)
    }

    // MARK: - Widget Export & Deep Linking
    func exportWidgetState() {
        widgetStateExporter.export(
            title: title,
            artist: artist,
            isPlaying: playing,
            isLiked: isLiked,
            source: source,
            position: position,
            duration: duration,
            bpm: AudioAnalysisService.shared.currentBPM,
            artwork: artwork
        )
    }

    func handleURL(_ url: URL) {
        guard url.scheme == "aura" else { return }
        let command = url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch command {
        case "playpause", "toggle":
            toggle()
        case "next":
            skip(1)
        case "prev", "previous":
            skip(-1)
        case "toggle-love", "like":
            toggleLike()
        case "show", "open":
            WindowCloseHandler.shared.showMainWindow()
        default:
            break
        }
    }
}
