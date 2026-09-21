import AppKit
import CoreServices
import Foundation

public enum AutomationPermissionStatus: Sendable {
    case authorized
    case notDetermined
    case denied
    case notInstalled

    public var localizedDescription: String {
        switch (self, L10n.current) {
        case (.authorized, .ru): return "Разрешено"
        case (.authorized, .en): return "Authorized"
        case (.notDetermined, .ru): return "Не настроено"
        case (.notDetermined, .en): return "Not Determined"
        case (.denied, .ru): return "Заблокировано"
        case (.denied, .en): return "Denied"
        case (.notInstalled, .ru): return "Не установлено"
        case (.notInstalled, .en): return "Not Installed"
        }
    }
}

public struct ConnectionTestResult: Sendable {
    public let appName: String
    public let isRunning: Bool
    public let permissionStatus: AutomationPermissionStatus
    public let currentTrack: String?
    public let isPlaying: Bool
    public let message: String

    public var isSuccess: Bool {
        permissionStatus == .authorized && isRunning
    }
}

@MainActor public final class AutomationPermissionManager: ObservableObject {
    public static let shared = AutomationPermissionManager()

    private init() {}

    /// Проверка прав автоматизации для приложения по bundleID
    public func checkPermission(bundleID: String, promptIfNeeded: Bool = false) -> AutomationPermissionStatus {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil else {
            return .notInstalled
        }

        let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
        let status = AEDeterminePermissionToAutomateTarget(
            target.aeDesc,
            typeWildCard,
            typeWildCard,
            promptIfNeeded
        )

        switch status {
        case noErr:
            return .authorized
        case -1743: // errAEEventNotPermitted
            return .denied
        case -1744: // errAEEventWouldRequireUserConsent
            return .notDetermined
        default:
            return .denied
        }
    }

    /// Запрос прав через нативное диалоговое окно macOS
    public func requestPermission(bundleID: String) {
        _ = checkPermission(bundleID: bundleID, promptIfNeeded: true)
    }

    /// Открыть Системные настройки в разделе Конфиденциальность -> Автоматизация
    public func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openAutomationSettings() {
        openPrivacySettings()
    }

    public func testConnection(bundleID: String) async -> ConnectionTestResult {
        let appName = bundleID == "com.spotify.client" ? "Spotify" : "Apple Music"
        return await testConnection(bundleID: bundleID, appName: appName)
    }

    /// Комплексный тест подключения к плееру
    public func testConnection(bundleID: String, appName: String) async -> ConnectionTestResult {
        let isInstalled = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
        guard isInstalled else {
            return ConnectionTestResult(
                appName: appName,
                isRunning: false,
                permissionStatus: .notInstalled,
                currentTrack: nil,
                isPlaying: false,
                message: L10n.current == .ru ? "\(appName) не установлен на этом Mac" : "\(appName) is not installed on this Mac"
            )
        }

        let isRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
        let permission = checkPermission(bundleID: bundleID, promptIfNeeded: false)

        if permission == .denied {
            return ConnectionTestResult(
                appName: appName,
                isRunning: isRunning,
                permissionStatus: .denied,
                currentTrack: nil,
                isPlaying: false,
                message: L10n.current == .ru ? "Доступ к \(appName) заблокирован в Системных настройках" : "Access to \(appName) is denied in System Settings"
            )
        }

        if !isRunning {
            return ConnectionTestResult(
                appName: appName,
                isRunning: false,
                permissionStatus: permission,
                currentTrack: nil,
                isPlaying: false,
                message: L10n.current == .ru ? "\(appName) установлен, но сейчас закрыт" : "\(appName) is installed but not running"
            )
        }

        // Пробуем считать состояние трека через PlayerAutomationService
        let isSpotify = (bundleID == "com.spotify.client")
        let snapshotResult = await PlayerAutomationService.shared.fetchPlayerState(
            bundleID: bundleID,
            appName: appName,
            isSpotify: isSpotify
        )

        switch snapshotResult {
        case .success(let snapshot):
            if let snapshot = snapshot {
                let trackInfo = "\(snapshot.title) — \(snapshot.artist)"
                let statusText = snapshot.isPlaying ? (L10n.current == .ru ? "Играет: " : "Playing: ") : (L10n.current == .ru ? "Пауза: " : "Paused: ")
                return ConnectionTestResult(
                    appName: appName,
                    isRunning: true,
                    permissionStatus: .authorized,
                    currentTrack: trackInfo,
                    isPlaying: snapshot.isPlaying,
                    message: "\(statusText)\(trackInfo)"
                )
            } else {
                return ConnectionTestResult(
                    appName: appName,
                    isRunning: true,
                    permissionStatus: .authorized,
                    currentTrack: nil,
                    isPlaying: false,
                    message: L10n.current == .ru ? "Подключено. Нет активного трека" : "Connected. No active track"
                )
            }
        case .failure(let error):
            if case .permissionDenied = error {
                return ConnectionTestResult(
                    appName: appName,
                    isRunning: true,
                    permissionStatus: .denied,
                    currentTrack: nil,
                    isPlaying: false,
                    message: L10n.current == .ru ? "Требуется разрешение в Системных настройках" : "Permission required in System Settings"
                )
            }
            return ConnectionTestResult(
                appName: appName,
                isRunning: true,
                permissionStatus: permission,
                currentTrack: nil,
                isPlaying: false,
                message: L10n.current == .ru ? "Ошибка связи: \(error)" : "Connection error: \(error)"
            )
        }
    }
}
