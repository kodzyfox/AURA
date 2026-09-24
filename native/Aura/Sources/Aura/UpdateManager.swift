import SwiftUI
import AppKit
import Combine

// MARK: - Модели данных GitHub Releases API

public struct GitHubAsset: Codable {
    public let name: String
    public let browserDownloadUrl: String
    public let size: Int64
    public let contentType: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
        case contentType = "content_type"
    }
}

public struct GitHubRelease: Codable, Identifiable {
    public var id: String { tagName }
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let publishedAt: String?
    public let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }
    
    public var versionString: String {
        var v = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        if v.lowercased().hasPrefix("v") {
            v.removeFirst()
        }
        return v
    }
    
    public var dmgAsset: GitHubAsset? {
        assets.first { $0.name.lowercased().hasSuffix(".dmg") } ?? assets.first
    }
}

// MARK: - Состояния загрузки обновления

public enum UpdateDownloadState: Equatable {
    case idle
    case downloading(progress: Double, bytesRead: Int64, totalBytes: Int64)
    case readyToInstall(dmgURL: URL)
    case failed(message: String)
}

// MARK: - Сервис проверки и установки обновлений

@MainActor
public final class UpdateManager: NSObject, ObservableObject {
    public static let shared = UpdateManager()
    
    // GitHub репозиторий проекта
    private let repoOwner = "kodzyfox"
    private let repoName = "AURA"
    
    private let autoCheckKey = "aura.updater.autoCheck"
    private let lastCheckKey = "aura.updater.lastCheckDate"
    
    @Published public var isChecking: Bool = false
    @Published public var updateAvailable: Bool = false
    @Published public var isUpToDate: Bool = false
    @Published public var latestRelease: GitHubRelease?
    @Published public var downloadState: UpdateDownloadState = .idle
    @Published public var errorMessage: String?
    @Published public var lastCheckedDate: Date?
    
    @Published public var autoCheckOnLaunch: Bool {
        didSet {
            UserDefaults.standard.set(autoCheckOnLaunch, forKey: autoCheckKey)
        }
    }
    
    private var downloadTask: URLSessionDownloadTask?
    private var urlSession: URLSession?
    
    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.5"
    }
    
    override private init() {
        self.autoCheckOnLaunch = UserDefaults.standard.object(forKey: autoCheckKey) as? Bool ?? true
        if let savedDate = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
            self.lastCheckedDate = savedDate
        }
        super.init()
    }
    
    // MARK: - Проверка обновлений
    
    public func checkForUpdates(manual: Bool = false) {
        guard !isChecking else { return }
        
        isChecking = true
        errorMessage = nil
        if manual {
            isUpToDate = false
        }
        
        Task {
            defer {
                self.isChecking = false
                let now = Date()
                self.lastCheckedDate = now
                UserDefaults.standard.set(now, forKey: self.lastCheckKey)
            }
            
            do {
                guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
                    throw URLError(.badURL)
                }
                
                var request = URLRequest(url: url)
                request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
                request.setValue("Aura-macOS-Updater/\(currentVersion)", forHTTPHeaderField: "User-Agent")
                request.timeoutInterval = 12
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if httpResponse.statusCode == 404 {
                    // Релизов на GitHub пока нет — разработчик использует последнюю версию
                    self.updateAvailable = false
                    self.latestRelease = nil
                    if manual { self.isUpToDate = true }
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let remoteVersion = release.versionString
                
                if self.isRemoteVersionNewer(remote: remoteVersion, local: self.currentVersion) {
                    self.latestRelease = release
                    self.updateAvailable = true
                    self.isUpToDate = false
                } else {
                    self.latestRelease = release
                    self.updateAvailable = false
                    if manual { self.isUpToDate = true }
                }
            } catch {
                if manual {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Сравнение версий SemVer
    
    public func isRemoteVersionNewer(remote: String, local: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0.filter { $0.isNumber }) }
        let localParts = local.split(separator: ".").compactMap { Int($0.filter { $0.isNumber }) }
        
        let maxCount = max(remoteParts.count, localParts.count)
        for i in 0..<maxCount {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let l = i < localParts.count ? localParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }
    
    // MARK: - Загрузка обновления
    
    public func startDownload() {
        guard let release = latestRelease, let asset = release.dmgAsset,
              let downloadURL = URL(string: asset.browserDownloadUrl) else {
            downloadState = .failed(message: LocalizationManager.shared.language == .ru ? "Файл DMG не найден в релизе" : "DMG asset not found in release")
            return
        }
        
        cancelDownload()
        downloadState = .downloading(progress: 0.0, bytesRead: 0, totalBytes: asset.size)
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        self.urlSession = session
        
        var request = URLRequest(url: downloadURL)
        request.setValue("Aura-macOS-Updater/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        
        let task = session.downloadTask(with: request)
        self.downloadTask = task
        task.resume()
    }
    
    public func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        downloadState = .idle
    }
    
    // MARK: - Установка и перезапуск приложения
    
    public func installAndRelaunch() {
        guard case .readyToInstall(let dmgURL) = downloadState else { return }
        
        let currentAppPath = Bundle.main.bundleURL.path
        let targetAppPath = currentAppPath.hasPrefix("/Applications") ? currentAppPath : "/Applications/Aura.app"
        let currentPID = ProcessInfo.processInfo.processIdentifier
        
        let scriptPath = "/tmp/aura_installer.sh"
        let scriptContent = """
        #!/bin/bash
        PID=\(currentPID)
        DMG="\(dmgURL.path)"
        TARGET="\(targetAppPath)"
        
        # 1. Ждем закрытия текущего процесса Aura
        while kill -0 "$PID" 2>/dev/null; do
            sleep 0.2
        done
        
        # 2. Создаем временную точку монтирования и подключаем DMG
        MOUNT_DIR=$(mktemp -d /tmp/aura_mount_XXXXXX)
        if hdiutil attach "$DMG" -mountpoint "$MOUNT_DIR" -nobrowse -quiet; then
            # 3. Копируем новый Aura.app
            if [ -d "$MOUNT_DIR/Aura.app" ]; then
                rm -rf "$TARGET"
                cp -R "$MOUNT_DIR/Aura.app" "$TARGET"
            fi
            
            # 4. Размонтируем DMG
            hdiutil detach "$MOUNT_DIR" -force -quiet || true
            rm -rf "$MOUNT_DIR" "$DMG"
            
            # 5. Запускаем обновленное приложение
            open "$TARGET"
        else
            # Если автоматическое монтирование не сработало, открываем DMG пользователю
            open "$DMG"
        fi
        
        rm -f "\(scriptPath)"
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            let chmodProcess = Process()
            chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodProcess.arguments = ["+x", scriptPath]
            try chmodProcess.run()
            chmodProcess.waitUntilExit()
            
            let runProcess = Process()
            runProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
            runProcess.arguments = [scriptPath]
            try runProcess.run()
            
            // Завершаем текущее приложение
            NSApplication.shared.terminate(nil)
        } catch {
            // В случае системного запрета просто открываем DMG
            openDMGDirectly()
        }
    }
    
    public func openDMGDirectly() {
        if case .readyToInstall(let dmgURL) = downloadState {
            NSWorkspace.shared.open(dmgURL)
        } else if let release = latestRelease {
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate для отслеживания прогресса

extension UpdateManager: URLSessionDownloadDelegate {
    public nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0.0
        
        Task { @MainActor in
            self.downloadState = .downloading(
                progress: progress,
                bytesRead: totalBytesWritten,
                totalBytes: totalBytesExpectedToWrite
            )
        }
    }
    
    public nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let destinationURL = URL(fileURLWithPath: "/tmp/Aura-update.dmg")
        try? FileManager.default.removeItem(at: destinationURL)
        
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            Task { @MainActor in
                self.downloadState = .readyToInstall(dmgURL: destinationURL)
            }
        } catch {
            Task { @MainActor in
                self.downloadState = .failed(message: error.localizedDescription)
            }
        }
    }
    
    public nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error as? URLError, error.code == .cancelled {
            return
        }
        if let error = error {
            Task { @MainActor in
                self.downloadState = .failed(message: error.localizedDescription)
            }
        }
    }
}
