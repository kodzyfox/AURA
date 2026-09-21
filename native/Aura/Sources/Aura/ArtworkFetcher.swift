import AppKit
import Foundation

// MARK: - Загрузчик обложек ультравысокого разрешения (Apple iTunes & Deezer API)
@MainActor final class ArtworkFetcher {
    static let shared = ArtworkFetcher()
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 8
        cache.totalCostLimit = 32 * 1024 * 1024 // 32 МБ максимум
    }
    
    func fetchHighResArtwork(title: String, artist: String) async -> NSImage? {
        let key = "\(artist.lowercased())_\(title.lowercased())" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        // 1. Попытка через Apple iTunes Search API (1500×1500 / 3000×3000px оригинальный студийный мастер)
        if let itunesImage = await fetchFromITunes(title: title, artist: artist) {
            cache.setObject(itunesImage, forKey: key)
            return itunesImage
        }
        
        // 2. Попытка через Deezer API (1000×1000px мастер высокого разрешения)
        if let deezerImage = await fetchFromDeezer(title: title, artist: artist) {
            cache.setObject(deezerImage, forKey: key)
            return deezerImage
        }
        
        return nil
    }
    
    // MARK: - Apple iTunes API
    private func fetchFromITunes(title: String, artist: String) async -> NSImage? {
        let cleanTitle = sanitize(title)
        let cleanArtist = sanitize(artist)
        let query = "\(cleanArtist) \(cleanTitle)"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=song&limit=1") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let first = results.first,
              let artworkUrl100 = first["artworkUrl100"] as? String else {
            return nil
        }
        
        // Заменяем 100x100bb на 1500x1500bb (максимальное качество Apple Music CDN)
        let highResUrlString = artworkUrl100
            .replacingOccurrences(of: "100x100bb.jpg", with: "1500x1500bb.jpg")
            .replacingOccurrences(of: "100x100bb.png", with: "1500x1500bb.png")
            .replacingOccurrences(of: "60x60bb.jpg", with: "1500x1500bb.jpg")
        
        guard let highResUrl = URL(string: highResUrlString),
              let (imgData, _) = try? await URLSession.shared.data(from: highResUrl),
              let image = NSImage(data: imgData) else {
            return nil
        }
        
        return image
    }
    
    // MARK: - Deezer API
    private func fetchFromDeezer(title: String, artist: String) async -> NSImage? {
        let cleanTitle = sanitize(title)
        let cleanArtist = sanitize(artist)
        let query = "\(cleanArtist) \(cleanTitle)"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.deezer.com/search?q=\(encoded)&limit=1") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let first = dataArray.first,
              let album = first["album"] as? [String: Any],
              let coverXl = (album["cover_xl"] as? String) ?? (album["cover_big"] as? String),
              let imgUrl = URL(string: coverXl),
              let (imgData, _) = try? await URLSession.shared.data(from: imgUrl),
              let image = NSImage(data: imgData) else {
            return nil
        }
        
        return image
    }
    
    private func sanitize(_ text: String) -> String {
        // Убираем служебные пометки вида (feat. ...), [Remix], - Radio Edit для точного поиска
        var s = text
        if let range = s.range(of: " (feat.") { s = String(s[..<range.lowerBound]) }
        if let range = s.range(of: " feat.") { s = String(s[..<range.lowerBound]) }
        if let range = s.range(of: " (with") { s = String(s[..<range.lowerBound]) }
        if let range = s.range(of: " [") { s = String(s[..<range.lowerBound]) }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
