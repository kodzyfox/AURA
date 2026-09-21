import Foundation
import AppKit
import os

// MARK: - Модели данных автоматизации плееров

public struct PlayerSnapshot: Sendable {
    public let title: String
    public let artist: String
    public let duration: Double
    public let position: Double
    public let isPlaying: Bool
    public let artworkURL: String?
    public let trackId: String?
    public let appName: String
    public let artworkData: Data?

    public init(
        title: String,
        artist: String,
        duration: Double,
        position: Double,
        isPlaying: Bool,
        artworkURL: String? = nil,
        trackId: String? = nil,
        appName: String,
        artworkData: Data? = nil
    ) {
        self.title = title
        self.artist = artist
        self.duration = duration
        self.position = position
        self.isPlaying = isPlaying
        self.artworkURL = artworkURL
        self.trackId = trackId
        self.appName = appName
        self.artworkData = artworkData
    }
}

public enum PlayerAutomationError: Error, Sendable {
    case notRunning
    case scriptFailed(code: Int, message: String)
    case timeout
    case permissionDenied
    case invalidResponse
}

// MARK: - Асинхронный сервис автоматизации (AppleScript в фоновом акторе с таймаутом)

public actor PlayerAutomationService {
    public static let shared = PlayerAutomationService()
    
    private init() {}
    
    /// Проверка, запущен ли процесс с заданным bundleID
    public nonisolated func isAppRunning(bundleID: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }
    
    /// Внутреннее синхронное выполнение скрипта в фоновом контексте
    private static func runScript(_ sourceText: String) throws -> NSAppleEventDescriptor {
        var error: NSDictionary?
        let script = NSAppleScript(source: sourceText)
        let result = script?.executeAndReturnError(&error)
        
        if let error {
            let number = error[NSAppleScript.errorNumber] as? Int ?? 0
            let msg = error[NSAppleScript.errorMessage] as? String ?? "AppleScript error"
            if number == -1743 {
                throw PlayerAutomationError.permissionDenied
            }
            throw PlayerAutomationError.scriptFailed(code: number, message: msg)
        }
        
        guard let res = result else {
            throw PlayerAutomationError.invalidResponse
        }
        return res
    }
    
    /// Обертка с контролем таймаута для Sendable-значений (не блокирует Swift-актор при зависаниях системного AppleScript)
    private func executeWithTimeout<T: Sendable>(
        timeoutSeconds: Double = 1.5,
        operation: @Sendable @escaping () throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let completed = OSAllocatedUnfairLock(initialState: false)
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try operation()
                    let shouldResume = completed.withLock { isDone -> Bool in
                        if !isDone {
                            isDone = true
                            return true
                        }
                        return false
                    }
                    if shouldResume {
                        continuation.resume(returning: result)
                    }
                } catch {
                    let shouldResume = completed.withLock { isDone -> Bool in
                        if !isDone {
                            isDone = true
                            return true
                        }
                        return false
                    }
                    if shouldResume {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + timeoutSeconds) {
                let shouldResume = completed.withLock { isDone -> Bool in
                    if !isDone {
                        isDone = true
                        return true
                    }
                    return false
                }
                if shouldResume {
                    continuation.resume(throwing: PlayerAutomationError.timeout)
                }
            }
        }
    }
    
    /// Получение текущего статуса плеера ("playing", "paused", etc.)
    public func fetchPlayerStateString(appName: String) async -> String? {
        let script = "tell application \"\(appName)\" to get player state as string"
        do {
            return try await executeWithTimeout(timeoutSeconds: 1.2) {
                let desc = try Self.runScript(script)
                return desc.stringValue
            }
        } catch {
            return nil
        }
    }
    
    /// Получение полного слепка состояния трека из Spotify или Apple Music
    public func fetchPlayerState(bundleID: String, appName: String, isSpotify: Bool) async -> Result<PlayerSnapshot?, PlayerAutomationError> {
        guard isAppRunning(bundleID: bundleID) else {
            return .success(nil)
        }
        
        let scriptQuery = isSpotify ? """
        tell application "\(appName)"
        return {name of current track, artist of current track, duration of current track, player position, player state as string, artwork url of current track, id of current track}
        end tell
        """ : """
        tell application "\(appName)"
        return {name of current track, artist of current track, duration of current track, player position, player state as string}
        end tell
        """
        
        do {
            let snapshot = try await executeWithTimeout(timeoutSeconds: 1.5) { () -> PlayerSnapshot in
                let result = try Self.runScript(scriptQuery)
                guard result.numberOfItems >= 5 else {
                    throw PlayerAutomationError.invalidResponse
                }
                
                let title = result.atIndex(1)?.stringValue ?? "Неизвестный трек"
                let artist = result.atIndex(2)?.stringValue ?? appName
                let rawDuration = result.atIndex(3)?.doubleValue ?? 0
                let duration = isSpotify ? (rawDuration / 1000.0) : rawDuration
                let position = result.atIndex(4)?.doubleValue ?? 0
                let isPlaying = result.atIndex(5)?.stringValue == "playing"
                let artworkURL = (isSpotify && result.numberOfItems >= 6) ? result.atIndex(6)?.stringValue : nil
                let trackId = (isSpotify && result.numberOfItems >= 7) ? result.atIndex(7)?.stringValue : nil
                
                return PlayerSnapshot(
                    title: title,
                    artist: artist,
                    duration: duration,
                    position: position,
                    isPlaying: isPlaying,
                    artworkURL: artworkURL,
                    trackId: trackId,
                    appName: appName
                )
            }
            return .success(snapshot)
        } catch let err as PlayerAutomationError {
            return .failure(err)
        } catch {
            return .failure(.scriptFailed(code: -1, message: error.localizedDescription))
        }
    }
    
    /// Переключение воспроизведения (Play/Pause)
    public func playPause(appName: String) async {
        let script = "tell application \"\(appName)\" to playpause"
        _ = try? await executeWithTimeout(timeoutSeconds: 1.0) {
            _ = try Self.runScript(script)
            return true
        }
    }
    
    /// Перемотка трека вперёд/назад
    public func skip(appName: String, forward: Bool) async {
        let cmd = forward ? "next track" : "previous track"
        let script = "tell application \"\(appName)\" to \(cmd)"
        _ = try? await executeWithTimeout(timeoutSeconds: 1.0) {
            _ = try Self.runScript(script)
            return true
        }
    }
    
    /// Установка позиции трека (Seek)
    public func seek(appName: String, position: Double) async {
        let script = "tell application \"\(appName)\" to set player position to \(position)"
        _ = try? await executeWithTimeout(timeoutSeconds: 1.0) {
            _ = try Self.runScript(script)
            return true
        }
    }
    
    /// Получение сырых данных обложки из Apple Music
    public func fetchMusicArtworkData() async -> Data? {
        let scriptText = """
        tell application "Music"
        try
        return raw data of artwork 1 of current track
        on error
        return ""
        end try
        end tell
        """
        do {
            return try await executeWithTimeout(timeoutSeconds: 2.0) {
                let descriptor = try Self.runScript(scriptText)
                let data = descriptor.data
                return data.isEmpty ? nil : data
            }
        } catch {
            return nil
        }
    }
}
