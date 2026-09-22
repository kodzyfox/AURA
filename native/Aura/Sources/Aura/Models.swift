import SwiftUI

enum Appearance: String, CaseIterable, Identifiable, Codable {
    case system = "Системная"
    case light = "Светлая"
    case dark = "Тёмная"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch (self, L10n.current) {
        case (.system, .ru): return "Системная"
        case (.system, .en): return "System"
        case (.light, .ru): return "Светлая"
        case (.light, .en): return "Light"
        case (.dark, .ru): return "Тёмная"
        case (.dark, .en): return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }
}

enum NavigationSection: String, CaseIterable, Identifiable, Codable {
    case overview = "overview"
    case effects = "effects"
    case sources = "sources"
    case presets = "presets"
    case lastfm = "lastfm"
    case settings = "settings"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .overview: return "macwindow"
        case .effects: return "sparkles"
        case .sources: return "waveform"
        case .presets: return "square.stack"
        case .lastfm: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        }
    }
    
    var localizedTitle: String {
        switch (self, L10n.current) {
        case (.overview, .ru): return "Обзор"
        case (.overview, .en): return "Overview"
        case (.effects, .ru): return "Эффекты"
        case (.effects, .en): return "Effects"
        case (.sources, .ru): return "Источники музыки"
        case (.sources, .en): return "Music Sources"
        case (.presets, .ru): return "Мои пресеты"
        case (.presets, .en): return "My Presets"
        case (.lastfm, _): return "Last.fm"
        case (.settings, .ru): return "Настройки"
        case (.settings, .en): return "Settings"
        }
    }
}

enum Source: String, CaseIterable, Identifiable, Codable {
    case auto = "Авто"
    case spotify = "Spotify"
    case music = "Apple Music"
    case youtubeMusic = "YouTube Music"
    case yandexMusic = "Яндекс Музыка"
    case nowPlaying = "Системный плеер"
    case local = "Локальные файлы"
    case demo = "Деморежим"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch (self, L10n.current) {
        case (.auto, .ru): return "Авто"
        case (.auto, .en): return "Auto"
        case (.spotify, _): return "Spotify"
        case (.music, _): return "Apple Music"
        case (.youtubeMusic, _): return "YouTube Music"
        case (.yandexMusic, .ru): return "Яндекс Музыка"
        case (.yandexMusic, .en): return "Yandex Music"
        case (.nowPlaying, .ru): return "Системный плеер"
        case (.nowPlaying, .en): return "System Player"
        case (.local, .ru): return "Локальные файлы"
        case (.local, .en): return "Local Files"
        case (.demo, .ru): return "Деморежим"
        case (.demo, .en): return "Demo Mode"
        }
    }
    
    var shortLocalizedName: String {
        switch (self, L10n.current) {
        case (.auto, .ru): return "Авто"
        case (.auto, .en): return "Auto"
        case (.spotify, _): return "Spotify"
        case (.music, _): return "Apple"
        case (.youtubeMusic, _): return "YT Music"
        case (.yandexMusic, _): return "Yandex"
        case (.nowPlaying, .ru): return "Система"
        case (.nowPlaying, .en): return "System"
        case (.local, .ru): return "Файлы"
        case (.local, .en): return "Files"
        case (.demo, .ru): return "Демо"
        case (.demo, .en): return "Demo"
        }
    }
    
    var bundleID: String? {
        switch self {
        case .spotify: return "com.spotify.client"
        case .music: return "com.apple.Music"
        case .yandexMusic: return "ru.yandex.music"
        default: return nil
        }
    }
    
    var appName: String {
        switch self {
        case .spotify: return "Spotify"
        case .music: return "Music"
        case .youtubeMusic: return "YouTube Music"
        case .yandexMusic: return L10n.current == .ru ? "Яндекс Музыка" : "Yandex Music"
        case .nowPlaying: return L10n.current == .ru ? "Системный плеер" : "System Player"
        default: return L10n.current == .ru ? "Музыка" : "Music"
        }
    }
    
    /// URL-фрагмент для поиска нужной вкладки в браузере (резервный)
    var browserTabDomain: String? {
        switch self {
        case .youtubeMusic: return "music.youtube.com"
        case .yandexMusic: return "music.yandex"
        default: return nil
        }
    }
    
    var symbol: String {
        switch self {
        case .auto: return "wand.and.stars"
        case .spotify: return "waveform.circle"
        case .music: return "apple.logo"
        case .youtubeMusic: return "play.rectangle.fill"
        case .yandexMusic: return "music.note.list"
        case .nowPlaying: return "macwindow.on.rectangle"
        case .local: return "folder"
        case .demo: return "sparkles"
        }
    }
}

enum Effect: String, CaseIterable, Identifiable, Codable {
    case aura = "Аура"
    case neonPulse = "Неоновый пульс"
    case prism = "Призма"
    case cosmicBreath = "Дыхание космоса"
    case waves = "Волны"
    case orbit = "Орбита"
    case aurora = "Северное сияние"
    case vinyl = "Винил"
    case minimal = "Минимализм"
    case nebula = "Туманность"
    case cyberGrid = "Кибер-сетка"
    case supernova = "Сверхновая"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch (self, L10n.current) {
        case (.aura, .ru): return "Аура"
        case (.aura, .en): return "Aura"
        case (.neonPulse, .ru): return "Неоновый пульс"
        case (.neonPulse, .en): return "Neon Pulse"
        case (.prism, .ru): return "Призма"
        case (.prism, .en): return "Prism"
        case (.cosmicBreath, .ru): return "Дыхание космоса"
        case (.cosmicBreath, .en): return "Cosmic Breath"
        case (.waves, .ru): return "Волны"
        case (.waves, .en): return "Waves"
        case (.orbit, .ru): return "Орбита"
        case (.orbit, .en): return "Orbit"
        case (.aurora, .ru): return "Северное сияние"
        case (.aurora, .en): return "Aurora"
        case (.vinyl, .ru): return "Винил"
        case (.vinyl, .en): return "Vinyl"
        case (.minimal, .ru): return "Минимализм"
        case (.minimal, .en): return "Minimal"
        case (.nebula, .ru): return "Жидкая туманность"
        case (.nebula, .en): return "Fluid Nebula"
        case (.cyberGrid, .ru): return "Кибер-сетка"
        case (.cyberGrid, .en): return "Cyber Grid"
        case (.supernova, .ru): return "Сверхновая"
        case (.supernova, .en): return "Supernova"
        }
    }
    var symbol: String {
        switch self {
        case .aura: return "sparkles"
        case .neonPulse: return "waveform.path.ecg"
        case .prism: return "triangle.fill"
        case .cosmicBreath: return "aqi.medium"
        case .waves: return "water.waves"
        case .orbit: return "circle.hexagongrid"
        case .minimal: return "square.stack"
        case .vinyl: return "opticaldisc"
        case .aurora: return "wind"
        case .nebula: return "smoke.fill"
        case .cyberGrid: return "grid"
        case .supernova: return "sparkle"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .aura:
            return [Theme.accent, Theme.accentSecondary]
        case .neonPulse:
            return [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.85, green: 0.27, blue: 0.94)]
        case .prism:
            return [Color(red: 0.0, green: 0.85, blue: 1.0), Color(red: 0.95, green: 0.25, blue: 0.75), Color(red: 1.0, green: 0.75, blue: 0.20)]
        case .cosmicBreath:
            return [Color(red: 0.08, green: 0.12, blue: 0.35), Color(red: 0.60, green: 0.20, blue: 0.90), Color(red: 0.0, green: 0.90, blue: 1.0)]
        case .waves:
            return [Color(red: 0.10, green: 0.80, blue: 0.90), Color(red: 0.15, green: 0.40, blue: 0.70)]
        case .orbit:
            return [Color.purple.opacity(0.85), Color.indigo, Color.cyan]
        case .aurora:
            return [Color.mint, Color.purple, Color.blue]
        case .vinyl:
            return [Color(white: 0.25), Color.black]
        case .minimal:
            return [Color.gray.opacity(0.6), Color.black.opacity(0.8)]
        case .nebula:
            return [Color(red: 0.10, green: 0.85, blue: 0.95), Color(red: 0.85, green: 0.20, blue: 0.90), Color(red: 0.20, green: 0.40, blue: 1.0)]
        case .cyberGrid:
            return [Color(red: 1.0, green: 0.20, blue: 0.65), Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.50, green: 0.10, blue: 0.90)]
        case .supernova:
            return [Color(red: 1.0, green: 0.75, blue: 0.20), Color(red: 1.0, green: 0.30, blue: 0.50), Color(red: 0.30, green: 0.85, blue: 1.0)]
        }
    }

    var localizedDescription: String {
        switch (self, L10n.current) {
        case (.aura, .ru): return "Мягкое сферическое сияние, плавно следующее за ритмом музыки."
        case (.aura, .en): return "Soft spherical bloom smoothly following the musical rhythm."
        case (.neonPulse, .ru): return "Ритмичные неоновые световые волны по периметру и контуру артворка."
        case (.neonPulse, .en): return "Rhythmic neon lightwaves along artwork borders and contour."
        case (.prism, .ru): return "Хроматическая дисперсия: переливающиеся спектральные призменные лучи."
        case (.prism, .en): return "Chromatic dispersion: shimmering spectral prismatic rays."
        case (.cosmicBreath, .ru): return "Глубокая пульсирующая туманность с мягким космическим дыханием."
        case (.cosmicBreath, .en): return "Deep pulsating nebula with gentle cosmic breathing."
        case (.waves, .ru): return "Динамические световые кольца и интерференционные волны света."
        case (.waves, .en): return "Dynamic light rings and optical interference waves."
        case (.orbit, .ru): return "Наклонные 3D-орбиты с парящими спутниками вокруг обложки."
        case (.orbit, .en): return "Tilted 3D orbits with floating satellites around artwork."
        case (.minimal, .ru): return "Фокус только на главном: чистый артворк и мягкий глубокий блюр."
        case (.minimal, .en): return "Focus on essentials: clean artwork and deep soft blur."
        case (.vinyl, .ru): return "Вращающаяся виниловая пластинка с круговыми канавками и отражениями."
        case (.vinyl, .en): return "Spinning vinyl record with micro-grooves and reflections."
        case (.aurora, .ru): return "Северное сияние: медленно колышущиеся неоновые ленты света."
        case (.aurora, .en): return "Northern Lights: gently swaying ribbons of polar light."
        case (.nebula, _): return L10n.effectNebulaDesc
        case (.cyberGrid, _): return L10n.effectCyberGridDesc
        case (.supernova, _): return L10n.effectSupernovaDesc
        }
    }
}

enum NotchGlowMode: String, CaseIterable, Identifiable, Codable {
    case ambientHalo = "ambientHalo"
    case audioWings = "audioWings"
    case dynamicIsland = "dynamicIsland"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch (self, L10n.current) {
        case (.ambientHalo, .ru): return "Неоновый ореол"
        case (.ambientHalo, .en): return "Ambient Halo"
        case (.audioWings, .ru): return "Эквалайзер-крылья"
        case (.audioWings, .en): return "Audio Wings"
        case (.dynamicIsland, .ru): return "Dynamic Island HUD"
        case (.dynamicIsland, .en): return "Dynamic Island HUD"
        }
    }
    
    var symbol: String {
        switch self {
        case .ambientHalo: return "sparkles"
        case .audioWings: return "waveform.path.ecg"
        case .dynamicIsland: return "capsule.portrait"
        }
    }
}

struct AuraPaletteItem: Identifiable, Hashable {
    let id: Int
    let name: String
    let previewColors: [Color]
    
    var localizedName: String {
        switch (id, L10n.current) {
        case (0, .ru): return "Обложка"
        case (0, .en): return "Artwork"
        case (1, .ru): return "Aura Неон"
        case (1, .en): return "Aura Neon"
        case (2, .ru): return "Киберпанк"
        case (2, .en): return "Cyberpunk"
        case (3, .ru): return "Северное сияние"
        case (3, .en): return "Northern Lights"
        case (4, .ru): return "Закат"
        case (4, .en): return "Sunset"
        case (5, .ru): return "Глубокий океан"
        case (5, .en): return "Deep Ocean"
        case (6, .ru): return "Лаванда"
        case (6, .en): return "Lavender"
        case (7, .ru): return "Ночной космос"
        case (7, .en): return "Night Cosmos"
        default: return name
        }
    }
}

struct AuraPalettes {
    static let all: [AuraPaletteItem] = [
        AuraPaletteItem(id: 0, name: "Обложка", previewColors: [Color.cyan, Color.purple]),
        AuraPaletteItem(id: 1, name: "Aura Неон", previewColors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.85, green: 0.27, blue: 0.94)]),
        AuraPaletteItem(id: 2, name: "Киберпанк", previewColors: [Color(red: 0.58, green: 0.20, blue: 1.0), Color(red: 1.0, green: 0.20, blue: 0.65)]),
        AuraPaletteItem(id: 3, name: "Северное сияние", previewColors: [Color(red: 0.10, green: 0.90, blue: 0.65), Color(red: 0.0, green: 0.85, blue: 1.0)]),
        AuraPaletteItem(id: 4, name: "Закат", previewColors: [Color(red: 1.0, green: 0.32, blue: 0.45), Color(red: 1.0, green: 0.68, blue: 0.22)]),
        AuraPaletteItem(id: 5, name: "Глубокий океан", previewColors: [Color(red: 0.15, green: 0.45, blue: 1.0), Color(red: 0.0, green: 0.88, blue: 0.96)]),
        AuraPaletteItem(id: 6, name: "Лаванда", previewColors: [Color(red: 0.72, green: 0.45, blue: 1.0), Color(red: 0.90, green: 0.65, blue: 0.98)]),
        AuraPaletteItem(id: 7, name: "Ночной космос", previewColors: [Color(red: 0.15, green: 0.22, blue: 0.40), Color(red: 0.55, green: 0.68, blue: 0.95)])
    ]
}

struct Atmosphere: Codable, Equatable {
    var effect: Effect = .aura
    var intensity: Double = 0.65
    var speed: Double = 0.35
    var blurRadius: Double = 18.0
    var glowScale: Double = 1.0
    var showClock: Bool = false
    var showInfo: Bool = true
    var palette: Int = 0 // 0..7
    
    // Атмосферные эффекты
    var showPlayerOnLockScreen: Bool = true // Виджет мини-плеера на экране блокировки
    var showPlayerOnDesktop: Bool = false   // Виджет мини-плеера на рабочем столе (по умолчанию выключен)
    var edgeGlow: Bool = true              // Пульсирующее свечение по краям экрана
    var animatedDesktopCover: Bool = true  // Анимированная парящая обложка по центру рабочего стола
    var edgeGlowOpacity: Double = 0.70     // Яркость свечения (10% - 100%)
    var edgeGlowThickness: Double = 140.0  // Размер / толщина свечения (40 - 240px)
    var edgeGlowSpeed: Double = 1.0        // Скорость пульсации и перелива
    var edgeGlowColorIndex: Int = 0        // 0: Обложка, 1..8: Пресеты
    var coverZoomLevel: Double = 0.80      // Масштаб обложки
    var filmGrain: Bool = false            // Текстура пленки

    // Свечение вокруг выреза экрана / Dynamic Island
    var notchGlow: Bool = true             // Свечение вокруг выреза экрана
    var notchGlowMode: NotchGlowMode = .dynamicIsland // Режим (.ambientHalo, .audioWings, .dynamicIsland)
    var notchGlowRadius: Double = 24.0      // Радиус свечения вокруг выреза (10 - 45px)
    var notchHUDOnTrackChange: Bool = true  // Автораскрытие мини-капсулы при смене трека

    // Performance controls
    var visualQuality: VisualQuality = .automatic
    var energySaving: Bool = true
    
    // Audio Reactive (пульсация в такт музыке)
    var audioReactive: Bool = true             // Пульсация в такт музыке
    var reactiveMode: ReactiveMode = .beatPulse // Режим реакции (.beatPulse, .spectrum, .ambientWave)
    var reactiveSensitivity: Double = 1.0       // Чувствительность пульсации (0.5 - 2.0)
    var coverAnimation: CoverAnimation = .beatPulse // Режим анимации (пульсации) обложки
    
    // Инициализатор по умолчанию
    init() {}
    
    // Безопасное декодирование со 100% обратной совместимостью старых пресетов
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        effect = try container.decodeIfPresent(Effect.self, forKey: .effect) ?? .aura
        intensity = try container.decodeIfPresent(Double.self, forKey: .intensity) ?? 0.65
        speed = try container.decodeIfPresent(Double.self, forKey: .speed) ?? 0.35
        blurRadius = try container.decodeIfPresent(Double.self, forKey: .blurRadius) ?? 18.0
        glowScale = try container.decodeIfPresent(Double.self, forKey: .glowScale) ?? 1.0
        showClock = try container.decodeIfPresent(Bool.self, forKey: .showClock) ?? false
        showInfo = try container.decodeIfPresent(Bool.self, forKey: .showInfo) ?? true
        palette = try container.decodeIfPresent(Int.self, forKey: .palette) ?? 0
        
        showPlayerOnLockScreen = try container.decodeIfPresent(Bool.self, forKey: .showPlayerOnLockScreen) ?? true
        showPlayerOnDesktop = try container.decodeIfPresent(Bool.self, forKey: .showPlayerOnDesktop) ?? false
        edgeGlow = try container.decodeIfPresent(Bool.self, forKey: .edgeGlow) ?? true
        animatedDesktopCover = try container.decodeIfPresent(Bool.self, forKey: .animatedDesktopCover) ?? true
        edgeGlowOpacity = try container.decodeIfPresent(Double.self, forKey: .edgeGlowOpacity) ?? 0.70
        edgeGlowThickness = try container.decodeIfPresent(Double.self, forKey: .edgeGlowThickness) ?? 140.0
        edgeGlowSpeed = try container.decodeIfPresent(Double.self, forKey: .edgeGlowSpeed) ?? 1.0
        edgeGlowColorIndex = try container.decodeIfPresent(Int.self, forKey: .edgeGlowColorIndex) ?? 0
        coverZoomLevel = try container.decodeIfPresent(Double.self, forKey: .coverZoomLevel) ?? 0.80
        filmGrain = try container.decodeIfPresent(Bool.self, forKey: .filmGrain) ?? false
        
        notchGlow = try container.decodeIfPresent(Bool.self, forKey: .notchGlow) ?? true
        notchGlowMode = try container.decodeIfPresent(NotchGlowMode.self, forKey: .notchGlowMode) ?? .dynamicIsland
        notchGlowRadius = try container.decodeIfPresent(Double.self, forKey: .notchGlowRadius) ?? 24.0
        notchHUDOnTrackChange = try container.decodeIfPresent(Bool.self, forKey: .notchHUDOnTrackChange) ?? true
        
        visualQuality = try container.decodeIfPresent(VisualQuality.self, forKey: .visualQuality) ?? .automatic
        energySaving = try container.decodeIfPresent(Bool.self, forKey: .energySaving) ?? true
        
        audioReactive = try container.decodeIfPresent(Bool.self, forKey: .audioReactive) ?? true
        reactiveMode = try container.decodeIfPresent(ReactiveMode.self, forKey: .reactiveMode) ?? .beatPulse
        reactiveSensitivity = try container.decodeIfPresent(Double.self, forKey: .reactiveSensitivity) ?? 1.0
        coverAnimation = try container.decodeIfPresent(CoverAnimation.self, forKey: .coverAnimation) ?? .beatPulse
    }
    
    // Обратная совместимость
    var showPlayerOnWallpaper: Bool {
        get { showPlayerOnLockScreen }
        set { showPlayerOnLockScreen = newValue }
    }
    
    func edgeGlowColor(artworkColor: Color?) -> Color {
        switch edgeGlowColorIndex {
        case 1: return Color(red: 0.95, green: 0.40, blue: 0.60) // Радужный спектр
        case 2: return Color(red: 0.0, green: 0.92, blue: 0.82)  // Северное сияние
        case 3: return Color(red: 1.0, green: 0.25, blue: 0.65)  // Неоновый закат
        case 4: return Color(red: 1.0, green: 0.65, blue: 0.20)  // Янтарь
        case 5: return Color(red: 0.0, green: 0.95, blue: 1.0)   // Фирменный Неон Циан
        case 6: return Color(red: 0.85, green: 0.27, blue: 0.94) // Фирменный Неон Маджента
        case 7: return Color(red: 0.12, green: 0.92, blue: 0.60) // Изумруд
        case 8: return Color.white                               // Белый
        default: return artworkColor ?? Color(red: 0.0, green: 0.95, blue: 1.0)
        }
    }
    
    func edgeGlowCGColor(artworkColor: CGColor? = nil) -> CGColor {
        switch edgeGlowColorIndex {
        case 1: return CGColor(red: 0.95, green: 0.40, blue: 0.60, alpha: 1.0)
        case 2: return CGColor(red: 0.0, green: 0.92, blue: 0.82, alpha: 1.0)
        case 3: return CGColor(red: 1.0, green: 0.25, blue: 0.65, alpha: 1.0)
        case 4: return CGColor(red: 1.0, green: 0.65, blue: 0.20, alpha: 1.0)
        case 5: return CGColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
        case 6: return CGColor(red: 0.85, green: 0.27, blue: 0.94, alpha: 1.0)
        case 7: return CGColor(red: 0.12, green: 0.92, blue: 0.60, alpha: 1.0)
        case 8: return CGColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0)
        default: return artworkColor ?? CGColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
        }
    }
    
    // Расчет исключительно масштаба (пульсации) обложки без смещения координат
    func computeCoverScale(
        t: Double,
        beatImpact: Double,
        beatPhase: Double = 0.0
    ) -> CGFloat {
        guard coverAnimation != .none else { return 1.0 }
        
        let sens = reactiveSensitivity
        
        // Определение активного импульса и фазы:
        // Если играет музыка с аудио-реактивностью — используем точный анализ битов
        // Если трек на паузе, в режиме предпросмотра или без выраженного бита — используем непрерывную плавную фазу от t
        let activeImpact: Double
        let activePhase: Double
        
        if audioReactive && beatImpact > 0.01 {
            activeImpact = min(1.0, max(0.0, beatImpact))
            activePhase = max(0.0, min(1.0, beatPhase))
        } else {
            let cycle = (t * (1.1 + speed * 0.9)).truncatingRemainder(dividingBy: 1.0)
            activePhase = max(0.0, min(1.0, cycle < 0 ? cycle + 1.0 : cycle))
            activeImpact = pow(max(0.0, 1.0 - activePhase * 2.2), 2.0)
        }
        
        switch coverAnimation {
        case .beatPulse:
            // Четкий акцентированный толчок в такт бочке/басу (до +12%)
            let boost = pow(activeImpact, 1.2) * 0.12 * sens
            return 1.0 + CGFloat(boost)
            
        case .breathe:
            // Плавное глубокое дыхание в темп трека (синусоида ±8%)
            let breatheCycle = sin(t * (2.2 * (0.6 + speed * 0.8)))
            let boost = (0.5 + 0.5 * breatheCycle) * 0.08 * sens
            return 1.0 + CGFloat(boost)
            
        case .heartbeat:
            // Двойной реалистичный толчок (тук-тук) на каждом такте (до +11%)
            let sub = (activePhase * 2.0).truncatingRemainder(dividingBy: 1.0)
            let subPhase = sub < 0 ? sub + 1.0 : sub
            var thump: Double = 0.0
            if subPhase < 0.30 {
                thump = sin(subPhase / 0.30 * .pi)
            } else if subPhase >= 0.38 && subPhase < 0.68 {
                thump = sin((subPhase - 0.38) / 0.30 * .pi) * 0.72
            }
            let boost = thump * 0.10 * sens * (0.35 + 0.65 * activeImpact)
            return 1.0 + CGFloat(boost)
            
        case .bounce:
            // Упругий эластичный отскок с приятным физическим эффектом
            let p = activePhase
            let bounceVal: Double
            if p < 0.25 {
                bounceVal = sin(p / 0.25 * (.pi * 0.5)) // Взлет до 1.0
            } else if p < 0.55 {
                bounceVal = 1.0 - sin((p - 0.25) / 0.30 * .pi) * 0.38 // Откат вниз
            } else if p < 0.80 {
                bounceVal = 0.62 + sin((p - 0.55) / 0.25 * .pi) * 0.22 // Малый отскок
            } else {
                bounceVal = 0.62 * (1.0 - (p - 0.80) / 0.20) // Плавное затухание
            }
            let boost = max(0.0, bounceVal) * 0.11 * sens * (0.35 + 0.65 * activeImpact)
            return 1.0 + CGFloat(boost)
            
        case .subtle:
            // Деликатная спокойная микро-пульсация (+5%)
            let boost = activeImpact * 0.048 * sens
            return 1.0 + CGFloat(boost)
            
        case .none:
            return 1.0
        }
    }
}

enum CoverAnimation: String, CaseIterable, Identifiable, Codable {
    case beatPulse = "beatPulse"
    case breathe = "breathe"
    case heartbeat = "heartbeat"
    case bounce = "bounce"
    case subtle = "subtle"
    case none = "none"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch (self, L10n.current) {
        case (.beatPulse, .ru): return "Бит-толчок"
        case (.beatPulse, .en): return "Beat Punch"
        case (.breathe, .ru): return "Плавное дыхание"
        case (.breathe, .en): return "Smooth Breathe"
        case (.heartbeat, .ru): return "Сердцебиение"
        case (.heartbeat, .en): return "Heartbeat"
        case (.bounce, .ru): return "Упругий отскок"
        case (.bounce, .en): return "Elastic Bounce"
        case (.subtle, .ru): return "Мягкий бит"
        case (.subtle, .en): return "Subtle Pulse"
        case (.none, .ru): return "Без пульсации"
        case (.none, .en): return "Static"
        }
    }
    
    var symbol: String {
        switch self {
        case .beatPulse: return "waveform.path.ecg"
        case .breathe: return "wind"
        case .heartbeat: return "heart.fill"
        case .bounce: return "arrow.up.and.down"
        case .subtle: return "circle.dotted"
        case .none: return "slash.circle"
        }
    }
}

enum ReactiveMode: String, CaseIterable, Identifiable, Codable {
    case beatPulse = "Бит-пульс"
    case spectrum = "Спектр волн"
    case ambientWave = "Дыхание"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch (self, L10n.current) {
        case (.beatPulse, .ru): return "Бит-пульс"
        case (.beatPulse, .en): return "Beat Pulse"
        case (.spectrum, .ru): return "Спектр волн"
        case (.spectrum, .en): return "Wave Spectrum"
        case (.ambientWave, .ru): return "Дыхание"
        case (.ambientWave, .en): return "Ambient Breathing"
        }
    }
    
    var symbol: String {
        switch self {
        case .beatPulse: return "waveform.path.ecg"
        case .spectrum: return "chart.bar.fill"
        case .ambientWave: return "water.waves"
        }
    }
}

// MARK: - Модели аналитики Last.fm
struct LastFMTopArtist: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let playcount: Int
    let rank: Int
    let url: String?
}

struct LastFMTopTag: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let count: Int
    let url: String?
}

struct SavedPreset: Identifiable, Codable {
    var id = UUID()
    var name: String
    var settings: Atmosphere
}

enum WallpaperStyle: String, CaseIterable, Identifiable, Codable {
    case poster = "Атмосферный постер"
    case fill = "На весь экран"
    case center = "Минимализм"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch (self, L10n.current) {
        case (.poster, .ru): return "Атмосферный постер"
        case (.poster, .en): return "Atmospheric Poster"
        case (.fill, .ru): return "На весь экран"
        case (.fill, .en): return "Fill Screen"
        case (.center, .ru): return "Минимализм"
        case (.center, .en): return "Minimalism"
        }
    }
    var symbol: String {
        switch self {
        case .poster: return "rectangle.inset.filled.and.person.filled"
        case .fill: return "arrow.up.left.and.arrow.down.right"
        case .center: return "square.inset.filled"
        }
    }
}
