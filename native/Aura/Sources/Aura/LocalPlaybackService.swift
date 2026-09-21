import AppKit
import AVFoundation
import Foundation
import UniformTypeIdentifiers

public struct LocalTrackItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public var title: String
    public var artist: String
    public var duration: Double

    public init(id: UUID = UUID(), url: URL, title: String, artist: String, duration: Double = 0) {
        self.id = id
        self.url = url
        self.title = title
        self.artist = artist
        self.duration = duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    public static func == (lhs: LocalTrackItem, rhs: LocalTrackItem) -> Bool {
        lhs.url == rhs.url
    }
}

public struct LocalTrackMetadata {
    public let title: String
    public let artist: String
    public let artwork: NSImage?
    public let duration: Double
}

/// Native playback boundary. The audio engine remains isolated in LocalAudioService.
@MainActor final class LocalPlaybackService {
    static let shared = LocalPlaybackService()
    private init() {}

    var isPlaying: Bool { LocalAudioService.shared.isPlaying }
    var currentTime: Double { LocalAudioService.shared.currentTime }
    var duration: Double { LocalAudioService.shared.duration }

    func toggle() {
        if isPlaying {
            LocalAudioService.shared.pause()
        } else {
            _ = LocalAudioService.shared.play()
        }
    }

    func load(_ url: URL) throws {
        try LocalAudioService.shared.load(url: url)
    }

    func play() -> Bool {
        LocalAudioService.shared.play()
    }

    func pause() {
        LocalAudioService.shared.pause()
    }

    func stop() {
        LocalAudioService.shared.stop()
    }

    func seek(to seconds: Double) {
        LocalAudioService.shared.seek(to: seconds)
    }

    func setVolume(_ value: Double) {
        LocalAudioService.shared.setVolume(value)
    }

    /// Открытие диалога выбора аудиофайлов
    func chooseAudioFiles() -> [URL]? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowedContentTypes = [
            .audio,
            .mp3,
            UTType(filenameExtension: "m4a") ?? .audio,
            UTType(filenameExtension: "wav") ?? .audio,
            UTType(filenameExtension: "aiff") ?? .audio,
            UTType(filenameExtension: "flac") ?? .audio,
            UTType(filenameExtension: "aac") ?? .audio
        ]
        if panel.runModal() == .OK {
            return collectAudioFiles(from: panel.urls)
        }
        return nil
    }

    /// Рекурсивный сбор аудиофайлов из переданных URL (включая директории)
    func collectAudioFiles(from urls: [URL]) -> [URL] {
        var result: [URL] = []
        let audioExtensions: Set<String> = ["mp3", "m4a", "wav", "flac", "aiff", "aif", "aac", "alac", "ogg"]
        let fileManager = FileManager.default

        for url in urls {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    if let enumerator = fileManager.enumerator(
                        at: url,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsHiddenFiles, .skipsPackageDescendants]
                    ) {
                        for case let fileURL as URL in enumerator {
                            if audioExtensions.contains(fileURL.pathExtension.lowercased()) {
                                result.append(fileURL)
                            }
                        }
                    }
                } else if audioExtensions.contains(url.pathExtension.lowercased()) {
                    result.append(url)
                }
            }
        }
        return result
    }

    /// Создание базового элемента очереди
    func makeQueueItem(from url: URL) -> LocalTrackItem {
        let title = url.deletingPathExtension().lastPathComponent
        let artist = L10n.current == .ru ? "Локальный файл" : "Local File"
        return LocalTrackItem(url: url, title: title, artist: artist)
    }

    /// Извлечение полных метаданных (ID3/MP4 теги, длительность, обложка)
    func extractMetadata(from url: URL, fallbackTitle: String, fallbackArtist: String) async -> LocalTrackMetadata {
        let asset = AVAsset(url: url)
        var title = fallbackTitle
        var artist = fallbackArtist
        var artwork: NSImage? = nil
        var trackDuration: Double = 0

        if let d = try? await asset.load(.duration) {
            trackDuration = CMTimeGetSeconds(d)
        }

        if let metadata = try? await asset.load(.metadata) {
            // 1. Извлекаем обложку из метаданных аудиофайла
            for item in metadata {
                if item.commonKey == .commonKeyArtwork {
                    if let data = try? await item.load(.dataValue),
                       let image = NSImage(data: data) {
                        artwork = image
                        break
                    }
                }
            }

            // 2. Извлекаем название трека и артиста
            for item in metadata {
                if item.commonKey == .commonKeyTitle,
                   let val = try? await item.load(.stringValue),
                   !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    title = val
                }
                if item.commonKey == .commonKeyArtist,
                   let val = try? await item.load(.stringValue),
                   !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    artist = val
                }
            }
        }

        return LocalTrackMetadata(
            title: title,
            artist: artist,
            artwork: artwork,
            duration: trackDuration.isFinite ? trackDuration : 0
        )
    }
}
