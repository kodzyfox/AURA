import WidgetKit
import SwiftUI
import AppKit

// MARK: - Модель состояния виджета
struct AuraWidgetData: Codable {
    var title: String = "Нет воспроизведения"
    var artist: String = "Включите трек в Spotify или Music"
    var isPlaying: Bool = false
    var isLiked: Bool = false
    var source: String = "Spotify"
    var bpm: Double = 120.0
    var updatedAt: Double = 0
}

struct AuraWidgetEntry: TimelineEntry {
    let date: Date
    let data: AuraWidgetData
    let artwork: NSImage?
}

// MARK: - Провайдер таймлайна виджета
struct AuraTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AuraWidgetEntry {
        AuraWidgetEntry(
            date: Date(),
            data: AuraWidgetData(
                title: "Starboy",
                artist: "The Weeknd, Daft Punk",
                isPlaying: true,
                isLiked: true,
                source: "Spotify",
                bpm: 186.0
            ),
            artwork: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AuraWidgetEntry) -> Void) {
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AuraWidgetEntry>) -> Void) {
        let entry = loadCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 5, to: Date()) ?? Date().addingTimeInterval(5)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadCurrentEntry() -> AuraWidgetEntry {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Aura", isDirectory: true)
        
        var data = AuraWidgetData()
        let jsonURL = appSupport.appendingPathComponent("widget_state.json")
        if let jsonData = try? Data(contentsOf: jsonURL),
           let saved = try? JSONDecoder().decode(AuraWidgetData.self, from: jsonData) {
            data = saved
        }
        
        var artwork: NSImage? = nil
        let artURL = appSupport.appendingPathComponent("current_artwork.png")
        if let artData = try? Data(contentsOf: artURL) {
            artwork = NSImage(data: artData)
        }
        
        return AuraWidgetEntry(date: Date(), data: data, artwork: artwork)
    }
}

// MARK: - Цвета темы для виджета
private struct WidgetTheme {
    static let cyan = Color(red: 0.0, green: 0.95, blue: 1.0)
    static let magenta = Color(red: 0.85, green: 0.27, blue: 0.94)
    static let green = Color(red: 0.12, green: 0.84, blue: 0.53)
    static let darkBg = Color(red: 0.07, green: 0.07, blue: 0.11)
    static let cardBg = Color(red: 0.11, green: 0.11, blue: 0.16)
}

// MARK: - Представление виджета
struct AuraWidgetEntryView: View {
    var entry: AuraTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            WidgetTheme.darkBg
            
            // Фоновое размытое свечение обложки
            if let art = entry.artwork {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 24)
                    .opacity(0.35)
                    .overlay(Color.black.opacity(0.4))
            }
            
            switch family {
            case .systemSmall:
                smallWidgetView
            default:
                mediumWidgetView
            }
        }
    }
    
    // MARK: - Компактный виджет (Small)
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetTheme.cyan)
                    Text("Λ U R Λ")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [WidgetTheme.cyan, WidgetTheme.magenta],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Spacer()
                
                Circle()
                    .fill(entry.data.isPlaying ? WidgetTheme.green : Color.gray)
                    .frame(width: 6, height: 6)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                if let art = entry.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                        .shadow(color: .black.opacity(0.4), radius: 6)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 58, height: 58)
                        .overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.3)))
                }
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.data.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(entry.data.artist)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .widgetURL(URL(string: "aura://show"))
    }
    
    // MARK: - Расширенный интерактивный виджет (Medium)
    private var mediumWidgetView: some View {
        HStack(spacing: 14) {
            // Обложка трека
            if let art = entry.artwork {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 82, height: 82)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 3)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 82, height: 82)
                    .overlay(Image(systemName: "music.note").font(.title2).foregroundStyle(.white.opacity(0.3)))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Верхний статус
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundStyle(WidgetTheme.cyan)
                        Text("Λ U R Λ")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [WidgetTheme.cyan, WidgetTheme.magenta],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Text(entry.data.source)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Spacer()
                    
                    if entry.data.isPlaying && entry.data.bpm > 0 {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(WidgetTheme.green)
                                .frame(width: 4, height: 4)
                            Text("\(Int(entry.data.bpm)) BPM")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(WidgetTheme.green)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(WidgetTheme.green.opacity(0.14), in: Capsule())
                    }
                }
                
                // Название трека и артист
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.data.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(entry.data.artist)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Интерактивные кнопки управления
                HStack(spacing: 12) {
                    // Предыдущий трек
                    Link(destination: URL(string: "aura://prev")!) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                    
                    // Плей / Пауза
                    Link(destination: URL(string: "aura://playpause")!) {
                        Image(systemName: entry.data.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(WidgetTheme.green, in: Circle())
                    }
                    
                    // Следующий трек
                    Link(destination: URL(string: "aura://next")!) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                    
                    Spacer()
                    
                    // Любимый трек (Last.fm Loved Track)
                    Link(destination: URL(string: "aura://toggle-love")!) {
                        HStack(spacing: 4) {
                            Image(systemName: entry.data.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(entry.data.isLiked ? WidgetTheme.magenta : .white.opacity(0.7))
                            if entry.data.isLiked {
                                Text("Loved")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(WidgetTheme.magenta)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            entry.data.isLiked ? WidgetTheme.magenta.opacity(0.18) : Color.white.opacity(0.08),
                            in: Capsule()
                        )
                    }
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Главная точка входа виджета
@main
struct AuraWidget: Widget {
    let kind: String = "studio.aura.mac.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuraTimelineProvider()) { entry in
            AuraWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Aura Плеер")
        .description("Интерактивный плеер Aura с управлением музыкой и статусом Last.fm.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
