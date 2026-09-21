import SwiftUI
import AppKit

// MARK: - Векторное отображение официального логотипа Spotify
private enum SpotifyBrandResource {
    // Официальный векторный логотип Spotify (круг с 3 звуковыми волнами)
    private static let svgString: String = """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="48" height="48">
    <path fill="black" fill-rule="evenodd" d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.48.66.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z"/>
    </svg>
    """
    
    static let templateImage: NSImage = {
        if let data = svgString.data(using: .utf8), let img = NSImage(data: data) {
            img.isTemplate = true
            return img
        }
        return NSImage()
    }()
}

// MARK: - Универсальный компонент иконок источников
struct SourceIconView: View {
    let source: Source
    var size: CGFloat = 16
    var color: Color? = nil
    
    var body: some View {
        Group {
            switch source {
            case .spotify:
                Image(nsImage: SpotifyBrandResource.templateImage)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: size, height: size)
                    
            case .music:
                // Официальный логотип Apple () в точности из гайдлайнов Apple Music
                Image(systemName: "apple.logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    
            case .auto:
                // Интуитивная и понятная волшебная палочка со звездами (авто-определение / смарт-выбор)
                Image(systemName: "wand.and.stars")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    
            case .local:
                Image(systemName: "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    
            case .demo:
                Image(systemName: "sparkles")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    
            case .youtubeMusic:
                Image(systemName: "play.rectangle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)

            case .yandexMusic:
                Image(systemName: "music.note.list")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)

            case .nowPlaying:
                Image(systemName: "macwindow.on.rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            }

        }
        .applyColor(color)
    }
}

private extension View {
    @ViewBuilder
    func applyColor(_ color: Color?) -> some View {
        if let color = color {
            self.foregroundStyle(color)
        } else {
            self
        }
    }
}
