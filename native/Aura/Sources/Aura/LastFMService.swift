import Foundation
import AppKit
import CryptoKit

// MARK: - Модель данных профиля Last.fm
struct LastFMUser: Codable {
    let name: String
    let playcount: String?
    let realname: String?
    let url: String?
}

// MARK: - Модель отложенного оффлайн-скроббла
struct PendingScrobble: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let title: String
    let artist: String
    let album: String?
    let timestamp: Int
    var attempts: Int = 0
}

// MARK: - Официальный сервис интеграции с Last.fm API 2.0
@MainActor final class LastFMService: ObservableObject {
    static let shared = LastFMService()
    
    // MARK: - Миграция и безопасное хранение ключей в Keychain
    private static func migrateFromUserDefaultsIfNeeded() {
        if let oldKey = UserDefaults.standard.string(forKey: "aura.lastfm.apiKey") {
            UserDefaults.standard.removeObject(forKey: "aura.lastfm.apiKey")
            if !oldKey.isEmpty && oldKey != "b25b959554ed76058ac220b7b2e0a026" {
                KeychainHelper.set(oldKey, forKey: "lastfm.apiKey")
            }
        }
        if let oldSecret = UserDefaults.standard.string(forKey: "aura.lastfm.apiSecret") {
            UserDefaults.standard.removeObject(forKey: "aura.lastfm.apiSecret")
            if !oldSecret.isEmpty && oldSecret != "425b550c18408f6d6b1d1d81b4fc6c8e" {
                KeychainHelper.set(oldSecret, forKey: "lastfm.apiSecret")
            }
        }
        if let oldSession = UserDefaults.standard.string(forKey: "aura.lastfm.sessionKey") {
            UserDefaults.standard.removeObject(forKey: "aura.lastfm.sessionKey")
            if !oldSession.isEmpty {
                KeychainHelper.set(oldSession, forKey: "lastfm.sessionKey")
            }
        }
    }
    
    // API ключи приложения (хранятся в системном Keychain)
    @Published var apiKey: String = {
        migrateFromUserDefaultsIfNeeded()
        return KeychainHelper.get(forKey: "lastfm.apiKey") ?? ""
    }() {
        didSet {
            let clean = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty {
                KeychainHelper.delete(forKey: "lastfm.apiKey")
            } else {
                KeychainHelper.set(clean, forKey: "lastfm.apiKey")
            }
        }
    }
    
    @Published var apiSecret: String = {
        migrateFromUserDefaultsIfNeeded()
        return KeychainHelper.get(forKey: "lastfm.apiSecret") ?? ""
    }() {
        didSet {
            let clean = apiSecret.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty {
                KeychainHelper.delete(forKey: "lastfm.apiSecret")
            } else {
                KeychainHelper.set(clean, forKey: "lastfm.apiSecret")
            }
        }
    }
    
    var hasValidCredentials: Bool {
        let k = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = apiSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        return !k.isEmpty && !s.isEmpty
    }
    
    // Состояние сессии (сессионный токен хранится в Keychain)
    @Published var sessionKey: String? = {
        migrateFromUserDefaultsIfNeeded()
        return KeychainHelper.get(forKey: "lastfm.sessionKey")
    }() {
        didSet {
            if let key = sessionKey, !key.isEmpty {
                KeychainHelper.set(key, forKey: "lastfm.sessionKey")
            } else {
                KeychainHelper.delete(forKey: "lastfm.sessionKey")
            }
            isConnected = sessionKey != nil && !(sessionKey?.isEmpty ?? true)
        }
    }
    @Published var username: String = UserDefaults.standard.string(forKey: "aura.lastfm.username") ?? "" {
        didSet { UserDefaults.standard.set(username, forKey: "aura.lastfm.username") }
    }
    @Published var isConnected: Bool = {
        let sk = KeychainHelper.get(forKey: "lastfm.sessionKey")
        return sk != nil && !(sk?.isEmpty ?? true)
    }()
    @Published var isAuthenticating: Bool = false
    @Published var authError: String? = nil
    
    // Настройки
    @Published var scrobblingEnabled: Bool = UserDefaults.standard.object(forKey: "aura.lastfm.scrobbling") == nil ? true : UserDefaults.standard.bool(forKey: "aura.lastfm.scrobbling") {
        didSet { UserDefaults.standard.set(scrobblingEnabled, forKey: "aura.lastfm.scrobbling") }
    }
    @Published var nowPlayingEnabled: Bool = UserDefaults.standard.object(forKey: "aura.lastfm.nowPlaying") == nil ? true : UserDefaults.standard.bool(forKey: "aura.lastfm.nowPlaying") {
        didSet { UserDefaults.standard.set(nowPlayingEnabled, forKey: "aura.lastfm.nowPlaying") }
    }
    
    // Статистика
    @Published var totalScrobbles: Int = UserDefaults.standard.integer(forKey: "aura.lastfm.totalScrobbles") {
        didSet { UserDefaults.standard.set(totalScrobbles, forKey: "aura.lastfm.totalScrobbles") }
    }
    @Published var lastScrobbledTrack: String? = UserDefaults.standard.string(forKey: "aura.lastfm.lastScrobbledTrack") {
        didSet { UserDefaults.standard.set(lastScrobbledTrack, forKey: "aura.lastfm.lastScrobbledTrack") }
    }
    /// URL аватарки Last.fm пользователя (размер extralarge)
    @Published var avatarURL: String? = UserDefaults.standard.string(forKey: "aura.lastfm.avatarURL") {
        didSet { UserDefaults.standard.set(avatarURL, forKey: "aura.lastfm.avatarURL") }
    }
    /// Локально кэшированная аватарка Last.fm пользователя
    @Published var avatarImage: NSImage? = nil

    private var avatarCacheURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Aura", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("lastfm_avatar.png")
    }
    @Published var lastScrobbledTime: Date? = {
        if let time = UserDefaults.standard.object(forKey: "aura.lastfm.lastScrobbledTime") as? Date {
            return time
        }
        return nil
    }() {
        didSet { UserDefaults.standard.set(lastScrobbledTime, forKey: "aura.lastfm.lastScrobbledTime") }
    }
    
    @Published var topArtists: [LastFMTopArtist] = []
    @Published var topTags: [LastFMTopTag] = []
    @Published var isLoadingAnalytics: Bool = false
    @Published var analyticsPeriod: String = "overall" // "7day", "1month", "overall"
    
    // Очередь оффлайн-скробблов для надежной отправки после простоя и потери сети
    @Published var pendingScrobbles: [PendingScrobble] = {
        if let data = UserDefaults.standard.data(forKey: "aura.lastfm.pendingScrobbles"),
           let list = try? JSONDecoder().decode([PendingScrobble].self, from: data) {
            return list
        }
        return []
    }() {
        didSet {
            if let data = try? JSONEncoder().encode(pendingScrobbles) {
                UserDefaults.standard.set(data, forKey: "aura.lastfm.pendingScrobbles")
            }
        }
    }
    
    private var pendingToken: String?
    private let baseURL = URL(string: "https://ws.audioscrobbler.com/2.0/")!
    
    private init() {
        if let data = try? Data(contentsOf: avatarCacheURL), let img = NSImage(data: data) {
            self.avatarImage = img
        }
        isConnected = sessionKey != nil && !(sessionKey?.isEmpty ?? true)
        if isConnected && !username.isEmpty {
            Task {
                await fetchUserInfo()
                await loadAnalytics()
                await flushPendingScrobbles()
            }
        }
        
        // Автоматический сброс очереди при пробуждении Mac из сна или блокировки
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await self?.flushPendingScrobbles()
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await self?.flushPendingScrobbles()
            }
        }
    }
    
    // MARK: - Авторизация через браузер (Last.fm Desktop Web Auth)
    
    func startAuthorization() async {
        guard hasValidCredentials else {
            authError = "Сначала укажите API Key и Shared Secret (Шаг 1 и 2)"
            return
        }
        
        isAuthenticating = true
        authError = nil
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "method", value: "auth.gettoken"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components.url else {
            authError = "Некорректный URL"
            isAuthenticating = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["token"] as? String {
                self.pendingToken = token
                
                // Открываем браузер на странице авторизации Last.fm
                let authWebURL = URL(string: "https://www.last.fm/api/auth/?api_key=\(apiKey)&token=\(token)")!
                NSWorkspace.shared.open(authWebURL)
            } else {
                authError = "Не удалось получить токен авторизации от Last.fm"
                isAuthenticating = false
            }
        } catch {
            authError = "Ошибка подключения: \(error.localizedDescription)"
            isAuthenticating = false
        }
    }
    
    func completeAuthorization() async {
        guard let token = pendingToken else {
            authError = "Сначала нажмите «Войти через Last.fm»"
            return
        }
        
        isAuthenticating = true
        authError = nil
        
        let params: [String: String] = [
            "method": "auth.getSession",
            "api_key": apiKey,
            "token": token
        ]
        
        let sig = createSignature(params: params)
        var postParams = params
        postParams["api_sig"] = sig
        postParams["format"] = "json"
        
        guard let body = urlEncode(postParams) else {
            authError = "Ошибка подготовки параметров"
            isAuthenticating = false
            return
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let session = json["session"] as? [String: Any],
                   let key = session["key"] as? String,
                   let name = session["name"] as? String {
                    self.sessionKey = key
                    self.username = name
                    self.pendingToken = nil
                    self.isAuthenticating = false
                    await fetchUserInfo()
                } else if let errorMsg = json["message"] as? String {
                    self.authError = errorMsg
                    self.isAuthenticating = false
                } else {
                    self.authError = "Авторизация не подтверждена на сайте Last.fm"
                    self.isAuthenticating = false
                }
            }
        } catch {
            self.authError = error.localizedDescription
            self.isAuthenticating = false
        }
    }
    
    func disconnect() {
        sessionKey = nil
        username = ""
        pendingToken = nil
        totalScrobbles = 0
        lastScrobbledTrack = nil
        lastScrobbledTime = nil
        avatarURL = nil
        avatarImage = nil
        try? FileManager.default.removeItem(at: avatarCacheURL)
        pendingScrobbles = []
        topArtists = []
        topTags = []
        isConnected = false
    }
    
    // MARK: - Статус «Сейчас играет» (track.updateNowPlaying)
    
    func updateNowPlaying(title: String, artist: String, album: String? = nil, duration: Double? = nil) async {
        guard isConnected, nowPlayingEnabled, let sk = sessionKey, !apiKey.isEmpty else { return }
        guard !title.isEmpty && !artist.isEmpty else { return }
        
        var params: [String: String] = [
            "method": "track.updateNowPlaying",
            "artist": artist,
            "track": title,
            "api_key": apiKey,
            "sk": sk
        ]
        if let album = album, !album.isEmpty {
            params["album"] = album
        }
        if let duration = duration, duration > 0 {
            params["duration"] = "\(Int(duration))"
        }
        
        let sig = createSignature(params: params)
        var postParams = params
        postParams["api_sig"] = sig
        postParams["format"] = "json"
        
        guard let body = urlEncode(postParams) else { return }
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        request.timeoutInterval = 8.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if statusCode == 200 {
                print("[LastFM] Now Playing updated: \(artist) — \(title)")
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let error = json["error"] as? Int {
                print("[LastFM] Now Playing error \(error): \(json["message"] as? String ?? "")")
                if error == 9 {
                    self.authError = "Сессия Last.fm устарела. Авторизуйтесь снова."
                    self.sessionKey = nil
                    self.isConnected = false
                }
            }
        } catch {
            print("[LastFM] Now Playing network error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Скробблинг трека с поддержкой оффлайн-очереди (track.scrobble)
    
    func scrobble(title: String, artist: String, album: String? = nil, timestamp: Date) async {
        guard isConnected, scrobblingEnabled, let _ = sessionKey, !apiKey.isEmpty else {
            print("[LastFM] Scrobble skipped: isConnected=\(isConnected), scrobblingEnabled=\(scrobblingEnabled), hasSession=\(sessionKey != nil), hasApiKey=\(!apiKey.isEmpty)")
            return
        }
        guard !title.isEmpty && !artist.isEmpty else { return }
        
        let timeInt = Int(timestamp.timeIntervalSince1970)
        
        // Дедупликация: не добавляем, если такой же трек уже в очереди с таймстемпом ±60 сек
        let isDuplicate = pendingScrobbles.contains { pending in
            pending.title.caseInsensitiveCompare(title) == .orderedSame &&
            pending.artist.caseInsensitiveCompare(artist) == .orderedSame &&
            abs(pending.timestamp - timeInt) < 60
        }
        
        if !isDuplicate {
            let item = PendingScrobble(
                title: title,
                artist: artist,
                album: album,
                timestamp: timeInt
            )
            pendingScrobbles.append(item)
            print("[LastFM] Added to queue: \"\(artist) — \(title)\" (queue count: \(pendingScrobbles.count))")
        }
        
        await flushPendingScrobbles()
    }
    
    private var isFlushingQueue = false
    
    func flushPendingScrobbles() async {
        guard isConnected, scrobblingEnabled, let sk = sessionKey, !apiKey.isEmpty else { return }
        guard !pendingScrobbles.isEmpty, !isFlushingQueue else { return }
        
        isFlushingQueue = true
        defer { isFlushingQueue = false }
        
        var successfullyScrobbled = 0
        var lastSuccessName: String? = nil
        var itemsToRemove = Set<UUID>()
        var attemptsUpdate: [UUID: Int] = [:]
        
        // Снимок очереди для безопасного перебора
        let queueSnapshot = pendingScrobbles
        
        for item in queueSnapshot {
            if item.attempts >= 10 {
                itemsToRemove.insert(item.id)
                print("[LastFM] Dropping item after 10 failed attempts: \(item.artist) — \(item.title)")
                continue
            }
            
            var params: [String: String] = [
                "method": "track.scrobble",
                "artist": item.artist,
                "track": item.title,
                "timestamp": "\(item.timestamp)",
                "api_key": apiKey,
                "sk": sk
            ]
            if let album = item.album, !album.isEmpty {
                params["album"] = album
            }
            
            let sig = createSignature(params: params)
            var postParams = params
            postParams["api_sig"] = sig
            postParams["format"] = "json"
            
            guard let body = urlEncode(postParams) else {
                itemsToRemove.insert(item.id)
                continue
            }
            
            var request = URLRequest(url: baseURL)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = body.data(using: .utf8)
            request.timeoutInterval = 12.0
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let scrobbles = json["scrobbles"] as? [String: Any],
                       let attr = scrobbles["@attr"] as? [String: Any] {
                        let accepted: Int = {
                            if let num = attr["accepted"] as? Int { return num }
                            if let str = attr["accepted"] as? String, let num = Int(str) { return num }
                            return 0
                        }()
                        
                        if accepted > 0 {
                            itemsToRemove.insert(item.id)
                            successfullyScrobbled += 1
                            lastSuccessName = "\(item.artist) — \(item.title)"
                            print("[LastFM] Successfully scrobbled: \(item.artist) — \(item.title)")
                        } else {
                            // Трек проигнорирован сервером (например, дата старше 14 дней или пустой тег)
                            itemsToRemove.insert(item.id)
                            print("[LastFM] Scrobble ignored by Last.fm: \(item.artist) — \(item.title)")
                        }
                    } else if let error = json["error"] as? Int {
                        let errorMsg = json["message"] as? String ?? "Error \(error)"
                        print("[LastFM] API Error \(error): \(errorMsg)")
                        
                        if error == 9 {
                            self.authError = "Сессия Last.fm устарела. Авторизуйтесь снова."
                            self.sessionKey = nil
                            self.isConnected = false
                            break
                        } else if error == 11 || error == 16 || error == 29 {
                            attemptsUpdate[item.id] = item.attempts + 1
                            break
                        } else {
                            itemsToRemove.insert(item.id)
                        }
                    } else if statusCode == 200 {
                        itemsToRemove.insert(item.id)
                    }
                } else if statusCode >= 500 {
                    attemptsUpdate[item.id] = item.attempts + 1
                    break
                }
            } catch {
                print("[LastFM] Network error sending scrobble: \(error.localizedDescription)")
                attemptsUpdate[item.id] = item.attempts + 1
                break
            }
        }
        
        // Безопасное обновление: удаляем только подтвержденные ID, не затирая добавленные во время запроса треки
        if !itemsToRemove.isEmpty || !attemptsUpdate.isEmpty {
            self.pendingScrobbles = self.pendingScrobbles.compactMap { current in
                if itemsToRemove.contains(current.id) {
                    return nil
                }
                if let updatedAttempts = attemptsUpdate[current.id] {
                    var modified = current
                    modified.attempts = updatedAttempts
                    return modified
                }
                return current
            }
        }
        
        if successfullyScrobbled > 0 {
            self.totalScrobbles += successfullyScrobbled
            if let last = lastSuccessName {
                self.lastScrobbledTrack = last
                self.lastScrobbledTime = Date()
            }
        }
    }
    
    // MARK: - Отметка Любимый трек (track.love / track.unlove)
    
    func toggleLove(title: String, artist: String, isLoved: Bool) async {
        guard isConnected, let sk = sessionKey else { return }
        guard !title.isEmpty && !artist.isEmpty else { return }
        
        let method = isLoved ? "track.love" : "track.unlove"
        let params: [String: String] = [
            "method": method,
            "artist": artist,
            "track": title,
            "api_key": apiKey,
            "sk": sk
        ]
        
        let sig = createSignature(params: params)
        var postParams = params
        postParams["api_sig"] = sig
        postParams["format"] = "json"
        
        guard let body = urlEncode(postParams) else { return }
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        
        _ = try? await URLSession.shared.data(for: request)
    }
    
    // MARK: - Проверка статуса «Любимый трек» (track.getInfo)
    
    func checkTrackIsLoved(title: String, artist: String) async -> Bool {
        guard isConnected, !username.isEmpty, !title.isEmpty, !artist.isEmpty, !apiKey.isEmpty else { return false }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "method", value: "track.getInfo"),
            URLQueryItem(name: "artist", value: artist),
            URLQueryItem(name: "track", value: title),
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components.url else { return false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let trackObj = json["track"] as? [String: Any] {
                if let userloved = trackObj["userloved"] as? String {
                    return userloved == "1"
                } else if let userlovedNum = trackObj["userloved"] as? Int {
                    return userlovedNum == 1
                }
            }
        } catch {
            return false
        }
        return false
    }
    
    // MARK: - Аналитика вкусов: Топ артистов и Топ жанров
    
    func loadAnalytics(period: String? = nil) async {
        guard isConnected, !username.isEmpty else { return }
        let selectedPeriod = period ?? analyticsPeriod
        self.analyticsPeriod = selectedPeriod
        self.isLoadingAnalytics = true
        
        async let artistsTask = fetchTopArtists(period: selectedPeriod, limit: 10)
        async let tagsTask = fetchTopTags(limit: 12)
        
        let (artists, tags) = await (artistsTask, tagsTask)
        self.topArtists = artists
        self.topTags = tags
        self.isLoadingAnalytics = false
    }
    
    private func fetchTopArtists(period: String, limit: Int) async -> [LastFMTopArtist] {
        guard !username.isEmpty, !apiKey.isEmpty else { return [] }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "method", value: "user.gettopartists"),
            URLQueryItem(name: "user", value: username),
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components.url else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let topartists = json["topartists"] as? [String: Any],
                  let artistList = topartists["artist"] as? [[String: Any]] else {
                return []
            }
            
            return artistList.enumerated().compactMap { index, item in
                guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                let playcountStr = item["playcount"] as? String ?? "0"
                let playcount = Int(playcountStr) ?? 0
                let urlStr = item["url"] as? String
                return LastFMTopArtist(name: name, playcount: playcount, rank: index + 1, url: urlStr)
            }
        } catch {
            return []
        }
    }
    
    private func fetchTopTags(limit: Int) async -> [LastFMTopTag] {
        guard !username.isEmpty, !apiKey.isEmpty else { return [] }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "method", value: "user.gettoptags"),
            URLQueryItem(name: "user", value: username),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components.url else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let toptags = json["toptags"] as? [String: Any],
                  let tagList = toptags["tag"] as? [[String: Any]] else {
                return []
            }
            
            return tagList.compactMap { item in
                guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                let countStr = item["count"] as? String ?? "0"
                let count = Int(countStr) ?? 0
                let urlStr = item["url"] as? String
                return LastFMTopTag(name: name, count: count, url: urlStr)
            }
        } catch {
            return []
        }
    }
    
    // MARK: - Загрузка профиля пользователя (user.getInfo)
    
    func fetchUserInfo() async {
        guard !username.isEmpty, !apiKey.isEmpty else { return }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "method", value: "user.getinfo"),
            URLQueryItem(name: "user", value: username),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components.url else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userObj = json["user"] as? [String: Any] {
                if let playcountStr = userObj["playcount"] as? String,
                   let count = Int(playcountStr) {
                    self.totalScrobbles = count
                }
                // Парсинг аватарки: Last.fm возвращает массив image[] по размерам
                if let images = userObj["image"] as? [[String: Any]] {
                    // Порядок размеров: small, medium, large, extralarge
                    // Берём extralarge (индекс 3), если есть, иначе последний непустой
                    let sorted = images.sorted { a, b in
                        let sizeOrder = ["small": 0, "medium": 1, "large": 2, "extralarge": 3, "mega": 4]
                        let sA = sizeOrder[(a["size"] as? String) ?? ""] ?? -1
                        let sB = sizeOrder[(b["size"] as? String) ?? ""] ?? -1
                        return sA < sB
                    }
                    if let best = sorted.last(where: { ($0["#text"] as? String)?.isEmpty == false }),
                       let urlStr = best["#text"] as? String, !urlStr.isEmpty {
                        self.avatarURL = urlStr
                        
                        // Загружаем и кэшируем изображение аватарки
                        if let imgURL = URL(string: urlStr),
                           let (imgData, _) = try? await URLSession.shared.data(from: imgURL),
                           let nsImg = NSImage(data: imgData) {
                            self.avatarImage = nsImg
                            try? imgData.write(to: self.avatarCacheURL, options: .atomic)
                        }
                    }
                }
            }
        } catch {
            print("Failed to fetch Last.fm user info:", error)
        }
    }
    
    // MARK: - Вспомогательные методы подписи API
    
    func createSignature(params: [String: String]) -> String {
        let sortedKeys = params.keys.filter { $0 != "format" && $0 != "callback" }.sorted()
        var signatureBase = ""
        for key in sortedKeys {
            if let val = params[key] {
                signatureBase += key + val
            }
        }
        signatureBase += apiSecret
        let digest = Insecure.MD5.hash(data: Data(signatureBase.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func urlEncode(_ params: [String: String]) -> String? {
        var components = URLComponents()
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.percentEncodedQuery
    }
}
