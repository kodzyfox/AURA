import AppKit
import Foundation

/// Owns artwork caching, resolution fetching, and network image downloading.
@MainActor final class ArtworkService {
    static let shared = ArtworkService()
    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 24
        cache.totalCostLimit = 64 * 1024 * 1024 // 64 MB
    }

    func cached(for key: String) -> NSImage? {
        cache.object(forKey: key as NSString)
    }

    func store(_ image: NSImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func clearCache() {
        cache.removeAllObjects()
    }

    func fetchHighResolution(title: String, artist: String) async -> NSImage? {
        await ArtworkFetcher.shared.fetchHighResArtwork(title: title, artist: artist)
    }

    /// Загружает обложку с проверкой кэша, поддержкой прямых URL и fallback на iTunes/Last.fm
    func fetchArtwork(key: String, title: String, artist: String, directUrl: String?) async -> NSImage? {
        if let cached = cached(for: key) {
            return cached
        }

        var downloadedImage: NSImage? = nil

        // 1. Попытка скачать по прямому URL
        if let directUrl, let url = URL(string: directUrl) {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = NSImage(data: data) {
                downloadedImage = img
            }
        }

        // 2. Если прямого URL нет или загрузка не удалась, ищем HD обложку через ArtworkFetcher
        if downloadedImage == nil && !title.isEmpty && !artist.isEmpty {
            downloadedImage = await fetchHighResolution(title: title, artist: artist)
        }

        // 3. Сохраняем в кэш
        if let img = downloadedImage {
            store(img, for: key)
        }

        return downloadedImage
    }

    /// Специализированная загрузка обложки Spotify с подменой на максимальное разрешение CDN (640x640)
    func fetchSpotifyArtwork(key: String, title: String, artist: String, directUrl: String?) async -> NSImage? {
        if let cached = cached(for: key) {
            return cached
        }
        var urlString = directUrl
        if let str = urlString, str.contains("ab67616d00001e02") {
            urlString = str.replacingOccurrences(of: "ab67616d00001e02", with: "ab67616d0000b273")
        }
        return await fetchArtwork(key: key, title: title, artist: artist, directUrl: urlString)
    }

    /// Специализированная загрузка обложки Apple Music через скриптовые данные с fallback на iTunes
    func fetchAppleMusicArtwork(key: String, title: String, artist: String) async -> NSImage? {
        if let cached = cached(for: key) {
            return cached
        }
        if let data = await PlayerAutomationService.shared.fetchMusicArtworkData(),
           let img = NSImage(data: data) {
            store(img, for: key)
            return img
        }
        return await fetchArtwork(key: key, title: title, artist: artist, directUrl: nil)
    }
}
