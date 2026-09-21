import AppKit
import Foundation
import WidgetKit

/// Widget export boundary. The facade can call this without knowing file details.
@MainActor final class WidgetStateExporter {
    static let shared = WidgetStateExporter()
    private init() {}

    func export(title: String, artist: String, isPlaying: Bool, isLiked: Bool, source: Source, position: Double, duration: Double, bpm: Double, artwork: NSImage?) {
        WidgetStateExporter.write(title: title, artist: artist, isPlaying: isPlaying, isLiked: isLiked, source: source, position: position, duration: duration, bpm: bpm, artwork: artwork)
        WidgetCenter.shared.reloadTimelines(ofKind: "AuraWidget")
    }

    private static func write(title: String, artist: String, isPlaying: Bool, isLiked: Bool, source: Source, position: Double, duration: Double, bpm: Double, artwork: NSImage?) {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Aura", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let state: [String: Any] = ["title": title, "artist": artist, "isPlaying": isPlaying, "isLiked": isLiked, "source": source.rawValue, "position": position, "duration": duration, "bpm": bpm, "updatedAt": Date().timeIntervalSince1970]
        if let data = try? JSONSerialization.data(withJSONObject: state, options: [.prettyPrinted]) { try? data.write(to: directory.appendingPathComponent("widget_state.json"), options: .atomic) }
        if let artwork, let tiff = artwork.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) { try? png.write(to: directory.appendingPathComponent("current_artwork.png"), options: .atomic) }
    }
}
