import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case ru = "ru"
    case en = "en"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        }
    }
    
    public var shortTitle: String {
        switch self {
        case .ru: return "RU"
        case .en: return "EN"
        }
    }
}

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    private static let storageKey = "aura.language"
    
    @Published public var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.storageKey),
           let lang = AppLanguage(rawValue: saved) {
            self.language = lang
        } else {
            // Определение языка системы по умолчанию
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            if preferred.hasPrefix("ru") || preferred.hasPrefix("be") || preferred.hasPrefix("uk") || preferred.hasPrefix("kk") {
                self.language = .ru
            } else {
                self.language = .en
            }
        }
    }
    
    public func setLanguage(_ lang: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.language = lang
        }
    }
}

public struct L10n {
    public static var current: AppLanguage {
        LocalizationManager.shared.language
    }
    
    // MARK: - Sidebar & Navigation
    public static var yourSpace: String {
        current == .ru ? "ВАШЕ ПРОСТРАНСТВО" : "YOUR SPACE"
    }
    public static var overview: String {
        current == .ru ? "Обзор" : "Overview"
    }
    public static var effects: String {
        current == .ru ? "Эффекты" : "Effects"
    }
    public static var musicSources: String {
        current == .ru ? "Источники музыки" : "Music Sources"
    }
    public static var myPresets: String {
        current == .ru ? "Мои пресеты" : "My Presets"
    }
    public static var appearance: String {
        current == .ru ? "ОФОРМЛЕНИЕ" : "APPEARANCE"
    }
    public static var language: String {
        current == .ru ? "ЯЗЫК" : "LANGUAGE"
    }
    public static var nowInAura: String {
        current == .ru ? "СЕЙЧАС В AURA" : "NOW IN AURA"
    }
    public static var playback: String {
        current == .ru ? "Воспроизведение" : "Playback"
    }
    public static var paused: String {
        current == .ru ? "Пауза" : "Paused"
    }
    public static var wallpaperFromMusic: String {
        current == .ru ? "Обои из музыки" : "Music Wallpaper"
    }
    public static var wallpaperSub: String {
        current == .ru ? "Рабочий стол и экран блокировки" : "Desktop & Lock Screen"
    }
    public static var wallpaperStyle: String {
        current == .ru ? "Стиль обоев" : "Wallpaper Style"
    }
    public static var backgroundModeSection: String {
        current == .ru ? "ФОНОВЫЙ РЕЖИМ" : "BACKGROUND MODE"
    }
    public static var runInBackground: String {
        current == .ru ? "Работа в фоне" : "Run in Background"
    }
    public static var whenWindowClosed: String {
        current == .ru ? "При закрытии окна" : "When window is closed"
    }
    public static var hideFromDock: String {
        current == .ru ? "Скрывать из Dock" : "Hide from Dock"
    }
    public static var menuBarOnly: String {
        current == .ru ? "Только строка меню" : "Menu bar only"
    }
    public static var launchAtLogin: String {
        current == .ru ? "Автозапуск при входе" : "Launch at Login"
    }
    public static var launchAtLoginSub: String {
        current == .ru ? "Запускать Aura автоматически при старте macOS" : "Start Aura automatically when you log in"
    }
    public static var screensaverMode: String {
        current == .ru ? "Режим заставки" : "Screensaver Mode"
    }
    public static var miniPlayer: String {
        current == .ru ? "Мини-плеер" : "Mini-Player"
    }
    public static var resetSettings: String {
        current == .ru ? "Сбросить настройки" : "Reset Settings"
    }
    
    // MARK: - Topbar & Headings
    public static var companionBadge: String {
        "MACOS COMPANION"
    }
    public static var headingKicker: String {
        current == .ru ? "ЗВУК ОБРЕТАЕТ ФОРМУ" : "SOUND TAKES SHAPE"
    }
    public static var headingTitleOverview: String {
        current == .ru ? "Музыка, которую видно." : "Music you can see."
    }
    public static var headingTitleSources: String {
        current == .ru ? "Вся ваша музыка. Вместе." : "All your music. Together."
    }
    public static var headingTitlePresets: String {
        current == .ru ? "Ваши любимые моменты." : "Your favorite moments."
    }
    public static var headingTitleEffects: String {
        current == .ru ? "Выберите своё настроение." : "Choose your mood."
    }
    public static var headingTitleLastFM: String {
        current == .ru ? "Ваша музыкальная история." : "Your music history."
    }
    public static var headingTitleSettings: String {
        current == .ru ? "Настройки Aura." : "Aura settings."
    }
    public static var headingSubtitle: String {
        current == .ru ? "Превратите любимую музыку в атмосферу вашего пространства." : "Transform your favorite music into the atmosphere of your space."
    }
    
    // MARK: - Overview & Preview
    public static var preview: String {
        current == .ru ? "Предпросмотр" : "Live Preview"
    }
    public static var playingNow: String {
        current == .ru ? "Играет" : "Playing"
    }
    public static var waitingForMusic: String {
        current == .ru ? "Ожидание музыки на Mac" : "Waiting for music on Mac"
    }
    public static var previousTrackHint: String {
        current == .ru ? "Предыдущий трек (Cmd+Left)" : "Previous track (Cmd+Left)"
    }
    public static var playPauseHint: String {
        current == .ru ? "Воспроизведение / пауза (Space)" : "Play / Pause (Space)"
    }
    public static var nextTrackHint: String {
        current == .ru ? "Следующий трек (Cmd+Right)" : "Next track (Cmd+Right)"
    }
    public static var inFavorites: String {
        current == .ru ? "В любимых треках (Last.fm / Aura)" : "In Loved Tracks (Last.fm / Aura)"
    }
    public static var addToFavorites: String {
        current == .ru ? "Добавить в любимые (Last.fm)" : "Add to Loved Tracks (Last.fm)"
    }
    
    // MARK: - Effects
    public static var chooseMood: String {
        current == .ru ? "Выберите настроение" : "Choose Mood"
    }
    public static var countEffects: String {
        current == .ru ? "9 эффектов" : "9 effects"
    }
    public static var nineMoodsTitle: String {
        current == .ru ? "Девять настроений для вашей музыки" : "Nine moods for your music"
    }
    public static var nineMoodsSubtitle: String {
        current == .ru ? "Каждый эффект по-своему интерпретирует ритм, палитру и энергию текущего трека." : "Each effect uniquely interprets the rhythm, palette, and energy of the current track."
    }
    
    // MARK: - Wallpaper & Atmosphere Settings (Правая колонка)
    public static var wallpaperSettings: String {
        current == .ru ? "Настройки обоев" : "Wallpaper Settings"
    }
    public static var glowMode: String {
        current == .ru ? "РЕЖИМ СВЕЧЕНИЯ" : "GLOW EFFECT"
    }
    public static var trackInfo: String {
        current == .ru ? "Информация о треке" : "Track Information"
    }
    public static var showClock: String {
        current == .ru ? "Показывать часы" : "Show Clock"
    }
    public static var atmosphereAndWallpapers: String {
        current == .ru ? "АТМОСФЕРА И ОБОИ" : "ATMOSPHERE & WALLPAPER"
    }
    public static var playerOnLockscreen: String {
        current == .ru ? "Плеер на экране блокировки" : "Lock Screen Player"
    }
    public static var playerOnDesktop: String {
        current == .ru ? "Плеер на рабочем столе" : "Desktop Floating Player"
    }
    public static var ambilightEdgeGlow: String {
        current == .ru ? "Свечение по бокам (Ambilight)" : "Edge Glow (Ambilight)"
    }
    public static var animatedDesktopCover: String {
        current == .ru ? "Анимированная обложка на рабочем столе" : "Animated Desktop Cover"
    }
    public static var coverAnimationTitle: String {
        current == .ru ? "Анимация пульсации обложки" : "Cover Pulse Animation"
    }
    public static var glowBrightness: String {
        current == .ru ? "Яркость свечения" : "Glow Brightness"
    }
    public static var glowSize: String {
        current == .ru ? "Размер свечения" : "Glow Spread"
    }
    public static var glowShiftSpeed: String {
        current == .ru ? "Скорость перелива" : "Color Shift Speed"
    }
    public static var glowColor: String {
        current == .ru ? "Цвет свечения" : "Glow Color"
    }
    public static var saveAsPreset: String {
        current == .ru ? "Сохранить как пресет" : "Save as Preset"
    }
    public static var quoteText: String {
        current == .ru ? "✦  Ваша музыка задаёт настроение.\n     Aura делает его видимым." : "✦  Your music sets the mood.\n     Aura makes it visible."
    }
    public static var bannerTitle: String {
        current == .ru ? "Ваша музыка. Без границ." : "Your music. Without borders."
    }
    public static var bannerSub: String {
        current == .ru ? "Spotify, Apple Music и локальные файлы — в одном пространстве." : "Spotify, Apple Music and local files — all in one space."
    }
    
    // MARK: - Presets
    public static var presetsTitle: String {
        current == .ru ? "Мои пресеты" : "My Presets"
    }
    public static var presetsSubtitle: String {
        current == .ru ? "Сохраненные конфигурации визуальных эффектов и настроек обоев." : "Saved visual effect presets and wallpaper atmospheres."
    }
    public static var noPresets: String {
        current == .ru ? "У вас пока нет сохраненных пресетов." : "You don't have any saved presets yet."
    }
    public static var createFirstPreset: String {
        current == .ru ? "Настройте атмосферу в Обзоре и нажмите «Сохранить как пресет»." : "Tune the atmosphere in Overview and tap 'Save as Preset'."
    }
    public static var applyPreset: String {
        current == .ru ? "Применить" : "Apply"
    }
    public static var deletePreset: String {
        current == .ru ? "Удалить" : "Delete"
    }
    public static var savePresetTitle: String {
        current == .ru ? "Сохранить атмосферу" : "Save Atmosphere"
    }
    public static var presetNamePlaceholder: String {
        current == .ru ? "Название пресета" : "Preset Name"
    }
    public static var defaultPresetName: String {
        current == .ru ? "Тёплый вечер" : "Warm Evening"
    }
    public static var cancel: String {
        current == .ru ? "Отмена" : "Cancel"
    }
    public static var save: String {
        current == .ru ? "Сохранить" : "Save"
    }
    
    // MARK: - Sources
    public static var sourcesTitle: String {
        current == .ru ? "Источники музыки" : "Music Sources"
    }
    public static var sourcesSubtitle: String {
        current == .ru ? "Aura автоматически подключается к активному плееру на вашем Mac." : "Aura automatically connects to the active player on your Mac."
    }
    public static var activeSource: String {
        current == .ru ? "АКТИВНЫЙ ИСТОЧНИК" : "ACTIVE SOURCE"
    }
    public static var autoDetectDesc: String {
        current == .ru ? "Умное переключение на плеер, который играет прямо сейчас" : "Smart auto-detection of the currently playing audio player"
    }
    public static var spotifyDesc: String {
        current == .ru ? "Полнофункциональная интеграция, обложки в высоком разрешении и анализ битов" : "Full integration, high-resolution artwork and live beat analysis"
    }
    public static var appleMusicDesc: String {
        current == .ru ? "Нативное управление и трансляция медиатеки Apple Music" : "Native macOS Apple Music library playback and metadata"
    }
    public static var localFilesDesc: String {
        current == .ru ? "Воспроизведение любых треков MP3, FLAC, AAC, WAV с вашего диска" : "Play any MP3, FLAC, AAC, WAV audio files directly from disk"
    }
    public static var demoDesc: String {
        current == .ru ? "Интерактивная демонстрация эффектов и анимаций Aura без запущенного плеера" : "Interactive demo mode showing visual effects without any player"
    }
    public static var openAudioFiles: String {
        current == .ru ? "Выбрать аудиофайлы…" : "Select Audio Files…"
    }
    
    // MARK: - Menu Bar Popover
    public static var menuBarSources: String {
        current == .ru ? "ИСТОЧНИКИ" : "SOURCES"
    }
    public static var openWindow: String {
        current == .ru ? "Открыть окно" : "Open Window"
    }
    public static var hideWindow: String {
        current == .ru ? "Скрыть окно" : "Hide Window"
    }
    public static var quitAura: String {
        current == .ru ? "Завершить Aura" : "Quit Aura"
    }
    
    // MARK: - Application Menu Commands
    public static var menuPlayback: String {
        current == .ru ? "Воспроизведение" : "Playback"
    }
    public static var menuPlay: String {
        current == .ru ? "Воспроизвести" : "Play"
    }
    public static var menuPause: String {
        current == .ru ? "Пауза" : "Pause"
    }
    public static var menuNext: String {
        current == .ru ? "Следующий трек" : "Next Track"
    }
    public static var menuPrevious: String {
        current == .ru ? "Предыдущий трек" : "Previous Track"
    }
    public static var menuView: String {
        current == .ru ? "Вид" : "View"
    }
    public static var menuNormalMode: String {
        current == .ru ? "Обычный режим" : "Standard Window"
    }
    public static var menuMiniPlayerAlwaysOnTop: String {
        current == .ru ? "Мини-плеер (Поверх окон)" : "Mini-Player (Always on Top)"
    }
    public static var menuFullscreenCover: String {
        current == .ru ? "Режим обложки на весь экран" : "Fullscreen Cover Mode"
    }
    public static var menuTheme: String {
        current == .ru ? "Тема оформления" : "Appearance Theme"
    }
    public static var menuLanguage: String {
        current == .ru ? "Язык" : "Language"
    }
    public static var aboutAura: String {
        current == .ru ? "О программе Aura" : "About Aura"
    }
    public static var footerNote: String {
        current == .ru ? "●  Всё в своём ритме." : "●  Everything in its rhythm."
    }
    public static var footerCopyright: String {
        current == .ru ? "Aura для macOS · Нативно. Локально. by Kodzy." : "Aura for macOS · Native. Local. by Kodzy."
    }
    
    // MARK: - Glow Swatches & Palette Names
    public static func swatchName(_ index: Int) -> String {
        switch (index, current) {
        case (1, .ru): return "Радужный спектр"
        case (1, .en): return "Rainbow Spectrum"
        case (2, .ru): return "Северное сияние"
        case (2, .en): return "Northern Lights (Aurora)"
        case (3, .ru): return "Неоновый закат"
        case (3, .en): return "Neon Sunset"
        case (4, .ru): return "Янтарный"
        case (4, .en): return "Amber"
        case (5, .ru): return "Неоновый циан"
        case (5, .en): return "Neon Cyan"
        case (6, .ru): return "Пурпур"
        case (6, .en): return "Purple"
        case (7, .ru): return "Изумруд"
        case (7, .en): return "Emerald"
        case (8, .ru): return "Лунный белый"
        case (8, .en): return "Moon White"
        default:
            return current == .ru ? "Цвет обложки" : "Artwork Color"
        }
    }
    
    public static func swatchShortName(_ index: Int) -> String {
        switch (index, current) {
        case (1, .ru): return "Радуга"
        case (1, .en): return "Rainbow"
        case (2, .ru): return "Сияние"
        case (2, .en): return "Aurora"
        case (3, .ru): return "Закат"
        case (3, .en): return "Sunset"
        case (4, .ru): return "Янтарь"
        case (4, .en): return "Amber"
        case (5, .ru): return "Циан"
        case (5, .en): return "Cyan"
        case (6, .ru): return "Пурпур"
        case (6, .en): return "Purple"
        case (7, .ru): return "Изумруд"
        case (7, .en): return "Emerald"
        case (8, .ru): return "Белый"
        case (8, .en): return "White"
        default:
            return current == .ru ? "Обложка" : "Artwork"
        }
    }
    
    // MARK: - Last.fm Screen
    public static var lastfmConnected: String {
        current == .ru ? "Подключено" : "Connected"
    }
    public static var lastfmHeaderDesc: String {
        current == .ru ? "Автоматический скробблинг, синхронизация Now Playing и любимых треков со всеми плеерами." : "Automatic scrobbling, Now Playing sync, and Loved Tracks integration with all players."
    }
    public static var lastfmProfile: String {
        current == .ru ? "Профиль Last.fm" : "Last.fm Profile"
    }
    public static var lastfmTotalScrobbles: String {
        current == .ru ? "всего скробблов" : "total scrobbles"
    }
    public static var lastfmOpenProfile: String {
        current == .ru ? "Открыть профиль" : "Open Profile"
    }
    public static var lastfmSyncParams: String {
        current == .ru ? "ПАРАМЕТРЫ СИНХРОНИЗАЦИИ" : "SYNC SETTINGS"
    }
    public static var lastfmAutoScrobble: String {
        current == .ru ? "Автоматический скробблинг" : "Automatic Scrobbling"
    }
    public static var lastfmAutoScrobbleDesc: String {
        current == .ru ? "Засчитывать трек в статистику Last.fm после 50% прослушивания (или 4 минут)" : "Scrobble track to Last.fm after 50% playback (or 4 minutes)"
    }
    public static var lastfmNowPlaying: String {
        current == .ru ? "Статус «Сейчас играет» (Now Playing)" : "Now Playing Status"
    }
    public static var lastfmNowPlayingDesc: String {
        current == .ru ? "Мгновенно обновлять текущий трек в профиле Last.fm при старте песни" : "Instantly update current track on Last.fm upon track start"
    }
    public static var lastfmScrobblerStatus: String {
        current == .ru ? "ТЕКУЩИЙ СТАТУС СКРОББЛЕРА" : "SCROBBLER STATUS"
    }
    public static var lastfmNowBroadcasting: String {
        current == .ru ? "Сейчас транслируется в Last.fm:" : "Now broadcasting to Last.fm:"
    }
    public static var lastfmPlaybackPaused: String {
        current == .ru ? "Воспроизведение приостановлено" : "Playback is paused"
    }
    public static var lastfmLastScrobble: String {
        current == .ru ? "Последний скроббл:" : "Last scrobble:"
    }
    public static var lastfmPendingQueue: String {
        current == .ru ? "В очереди на отправку:" : "Pending in offline queue:"
    }
    public static var lastfmSendQueueNow: String {
        current == .ru ? "Отправить сейчас" : "Send Now"
    }
    public static var lastfmRefreshStats: String {
        current == .ru ? "Обновить статистику" : "Refresh Statistics"
    }
    public static var lastfmDisconnect: String {
        current == .ru ? "Отключить аккаунт Last.fm" : "Disconnect Last.fm Account"
    }
    public static var lastfmAnalyticsTitle: String {
        current == .ru ? "МУЗЫКАЛЬНАЯ АНАЛИТИКА ВКУСОВ" : "LISTENING ANALYTICS"
    }
    public static var lastfmAnalyticsSub: String {
        current == .ru ? "Ваши самые прослушиваемые исполнители и жанры по данным Last.fm" : "Your most listened artists and genres according to Last.fm"
    }
    public static var lastfm7Days: String {
        current == .ru ? "7 дней" : "7 days"
    }
    public static var lastfm1Month: String {
        current == .ru ? "1 месяц" : "1 month"
    }
    public static var lastfmOverall: String {
        current == .ru ? "За всё время" : "All time"
    }
    public static var lastfmTopArtists: String {
        current == .ru ? "ТОП-7 ИСПОЛНИТЕЛЕЙ" : "TOP 7 ARTISTS"
    }
    public static var lastfmTopTags: String {
        current == .ru ? "ЛЮБИМЫЕ ЖАНРЫ И ТЕГИ" : "FAVORITE GENRES & TAGS"
    }
    public static var lastfmScrobbles: String {
        current == .ru ? "Скробблы" : "Scrobbles"
    }
    public static var lastfmLoadingAnalytics: String {
        current == .ru ? "Загрузка аналитики из Last.fm..." : "Loading analytics from Last.fm..."
    }
    public static var lastfmLoadAnalytics: String {
        current == .ru ? "Загрузить аналитику вкусов" : "Load Listening Analytics"
    }
    public static var lastfmConnectTitle: String {
        current == .ru ? "ПОДКЛЮЧЕНИЕ AURA К LAST.FM" : "CONNECT AURA TO LAST.FM"
    }
    public static var lastfmFeaturesTitle: String {
        current == .ru ? "ВОЗМОЖНОСТИ ИНТЕГРАЦИИ" : "INTEGRATION FEATURES"
    }
    public static var lastfmKeysReady: String {
        current == .ru ? "Ключи приложения готовы" : "API keys are ready"
    }
    
    // MARK: - Settings Page
    public static var settingsNavTitle: String {
        current == .ru ? "Настройки" : "Settings"
    }
    public static var settingsSubtitle: String {
        current == .ru ? "Персонализация внешнего вида, языка и поведения Aura в macOS." : "Personalize Aura's appearance, language, and behavior on macOS."
    }
    public static var appearanceSubtitle: String {
        current == .ru ? "Выберите цветовую схему оформления интерфейса приложения" : "Choose the color scheme for the application interface"
    }
    public static var languageSubtitle: String {
        current == .ru ? "Мгновенное переключение языка всех элементов без перезапуска" : "Instant live language switching for all elements without restart"
    }
    public static var backgroundSectionSubtitle: String {
        current == .ru ? "Поведение Aura при закрытии главного окна и работа в строке меню" : "Aura's behavior when the main window is closed and menu bar presence"
    }
    public static var resetSettingsTitle: String {
        current == .ru ? "Сброс настроек" : "Reset Settings"
    }
    public static var resetSettingsSubtitle: String {
        current == .ru ? "Вернуть параметры атмосферы, эффектов и чувствительности к заводским" : "Reset atmosphere, effect, and sensitivity parameters to factory defaults"
    }
    public static var resetToDefaults: String {
        current == .ru ? "Сбросить к стандартным" : "Reset to Defaults"
    }
    public static var resetSuccess: String {
        current == .ru ? "Настройки сброшены" : "Settings reset"
    }
    public static var aboutAuraSection: String {
        current == .ru ? "О ПРОГРАММЕ AURA" : "ABOUT AURA"
    }
    public static var nativeMacApp: String {
        current == .ru ? "Нативное приложение для macOS" : "Native application for macOS"
    }
    public static var openAboutDialog: String {
        current == .ru ? "Открыть окно «О программе»" : "Open About Panel"
    }
    
    // MARK: - Performance & Energy
    public static var performanceSectionTitle: String {
        current == .ru ? "ПРОИЗВОДИТЕЛЬНОСТЬ И ЭНЕРГОСБЕРЕЖЕНИЕ" : "PERFORMANCE & ENERGY"
    }
    public static var performanceSubtitle: String {
        current == .ru ? "Оптимизация нагрузки на процессор, видеокарту и батарею при работе визуализации" : "Optimize CPU, GPU, and battery footprint during visualization"
    }
    public static var visualQualityTitle: String {
        current == .ru ? "Визуальное качество и частота кадров" : "Visual Quality & Frame Rate"
    }
    public static var disableOnBatteryTitle: String {
        current == .ru ? "Энергосбережение при питании от батареи" : "Energy Saving on Battery Power"
    }
    public static var disableOnBatterySubtitle: String {
        current == .ru ? "Автоматически ограничивать FPS и отключать сложные многослойные шейдеры" : "Automatically cap FPS and disable expensive multi-layer shaders on battery"
    }
    public static var diagnosticsTitle: String {
        current == .ru ? "Диагностика нагрузки в реальном времени" : "Real-Time System Diagnostics"
    }
    public static var powerSourceTitle: String {
        current == .ru ? "Источник питания" : "Power Source"
    }
    public static var currentFPSTitle: String {
        current == .ru ? "Ограничение FPS" : "FPS Target"
    }
    public static var thermalsTitle: String {
        current == .ru ? "Нагрев системы" : "Thermal State"
    }
    public static var monitorsTitle: String {
        current == .ru ? "Дисплеи" : "Displays"
    }
    public static var wallpaperScaleTitle: String {
        current == .ru ? "Масштаб рендера обоев" : "Wallpaper Render Scale"
    }
    
    // MARK: - UX Priority 7
    public static var testConnectionTitle: String {
        current == .ru ? "Проверить подключение" : "Check Connection"
    }
    public static var checkConnectionSubtitle: String {
        current == .ru ? "Проверка состояния процесса и прав Apple Events" : "Verify process status and Apple Events permissions"
    }
    public static var exportPresets: String {
        current == .ru ? "Экспорт пресетов" : "Export Presets"
    }
    public static var importPresets: String {
        current == .ru ? "Импорт пресетов" : "Import Presets"
    }
    public static var windowCloseBehaviorTitle: String {
        current == .ru ? "Действие при закрытии окна" : "When Window is Closed"
    }
    public static var windowCloseBehaviorSubtitle: String {
        current == .ru ? "Выберите, что происходит при нажатии красной кнопки закрытия" : "Choose what happens when the red close button is clicked"
    }
    public static var queueTitle: String {
        current == .ru ? "Очередь треков" : "Track Queue"
    }
    public static var dragDropHint: String {
        current == .ru ? "Перетащите аудиофайлы или папки сюда" : "Drag audio files or folders here"
    }
    public static var audioAnalysisTitle: String {
        current == .ru ? "Режим анализа аудио" : "Audio Analysis Mode"
    }
    public static var audioAnalysisPopoverDesc: String {
        current == .ru ? "Аппаратный спектральный анализ частот vDSP FFT и синхронизация темпа" : "Hardware vDSP FFT frequency analysis and tempo synchronization"
    }
    public static var onboardingButton: String {
        current == .ru ? "Инструкция и возможности" : "Feature Tour & Setup"
    }
    public static var dropFilesHere: String {
        current == .ru ? "Перетащите файлы сюда" : "Drop files here"
    }
    public static var dropFilesSub: String {
        current == .ru ? "Поддерживаются MP3, M4A, WAV, FLAC, AIFF или целые папки" : "Supports MP3, M4A, WAV, FLAC, AIFF or full folders"
    }
    public static var checkConnection: String {
        current == .ru ? "Проверить подключение" : "Check Connection"
    }
    public static var connectionSuccess: String {
        current == .ru ? "Подключение успешно" : "Connection Successful"
    }
    public static var connectionFailed: String {
        current == .ru ? "Сбой подключения" : "Connection Failed"
    }
    public static var openSettingsAction: String {
        current == .ru ? "Настройки macOS" : "macOS Settings"
    }
    public static var localQueueTitle: String {
        current == .ru ? "Очередь воспроизведения" : "Playback Queue"
    }
    public static var addFiles: String {
        current == .ru ? "Добавить файлы" : "Add Files"
    }
    public static var dragDropFilesHint: String {
        current == .ru ? "Или перетащите файлы в окно Aura" : "Or drag & drop files into Aura"
    }
    public static var onWindowClose: String {
        current == .ru ? "Действие при закрытии окна" : "When Window is Closed"
    }
    public static var onWindowCloseSub: String {
        current == .ru ? "Поведение приложения при нажатии красной кнопки окна" : "App behavior when clicking the red window close button"
    }
    public static var onboardingWelcome: String {
        current == .ru ? "Знакомство с возможностями" : "Feature Introduction"
    }
    public static var onboardingSubtitle: String {
        current == .ru ? "Повторно пройти начальную настройку и проверку прав" : "Rerun initial setup walkthrough and permissions check"
    }
    public static var openOnboarding: String {
        current == .ru ? "Открыть тур" : "Open Tour"
    }
    
    // MARK: - Onboarding Screen Localization
    public static var onboardingWelcomeTitle: String {
        current == .ru ? "Aura для macOS" : "Aura for macOS"
    }
    public static var onboardingWelcomeDesc: String {
        current == .ru
            ? "Атмосферный музыкальный компаньон с парящими живыми обоями, Ambilight-свечением и аудиореактивной визуализацией."
            : "Ambient macOS music companion with dynamic live wallpapers, edge Ambilight glow, and real-time audio visualization."
    }
    public static var onboardingBadgeLiveWallpapers: String {
        current == .ru ? "Живые обои" : "Dynamic Wallpapers"
    }
    public static var onboardingBadgeAmbilight: String {
        current == .ru ? "Ambilight-свечение" : "Ambilight Glow"
    }
    public static var onboardingBadgeAudioSpectrum: String {
        current == .ru ? "Аудиоспектр" : "Audio Spectrum"
    }
    public static var onboardingIntegrationsTitle: String {
        current == .ru ? "Интеграция с плеерами" : "Player Integration"
    }
    public static var onboardingIntegrationsDesc: String {
        current == .ru
            ? "Aura автоматически синхронизирует треки и обложки из Spotify и Apple Music через нативные события Apple Events. Для управления требуется разрешение автоматизации."
            : "Aura synchronizes tracks and artwork from Spotify and Apple Music via native Apple Events. Automation permission is required."
    }
    public static var onboardingAllowPermission: String {
        current == .ru ? "Разрешить" : "Allow"
    }
    public static var onboardingAudioTitle: String {
        current == .ru ? "Студийный звук и FFT-анализ" : "Studio Audio & FFT Analysis"
    }
    public static var onboardingAudioDesc: String {
        current == .ru
            ? "Воспроизводите файлы MP3, M4A, WAV, AIFF и FLAC без потерь. Аппаратный DSP vDSP FFT анализирует спектр в 60 FPS для точной пульсации эффектов."
            : "Play MP3, M4A, WAV, AIFF, and lossless FLAC. Hardware vDSP FFT engine analyzes audio frequencies at 60 FPS for instant reactive visuals."
    }
    public static var onboardingBadgeDSP: String {
        current == .ru ? "vDSP FFT процессор" : "vDSP FFT DSP"
    }
    public static var onboardingBadgeDragDrop: String {
        "Drag & Drop"
    }
    public static var onboardingBadgeQueue: String {
        current == .ru ? "Очередь треков" : "Track Queue"
    }
    public static var onboardingReadyTitle: String {
        current == .ru ? "Всё готово к работе" : "You're All Set"
    }
    public static var onboardingReadyDesc: String {
        current == .ru
            ? "Управляйте воспроизведением из строки меню, используйте компактный мини-плеер (Cmd+Shift+M), виджет Центра уведомлений и скробблинг Last.fm."
            : "Control playback from Menu Bar, use sleek Mini-Player (Cmd+Shift+M), Notification Center widget, and Last.fm scrobbling."
    }
    public static var onboardingBadgeMenuBar: String {
        current == .ru ? "Строка меню" : "Menu Bar"
    }
    public static var onboardingBadgeMiniPlayer: String {
        current == .ru ? "Мини-плеер" : "Mini-Player"
    }
    public static var onboardingBadgeLastFM: String {
        current == .ru ? "Скробблинг Last.fm" : "Last.fm Scrobbling"
    }
    public static var onboardingBack: String {
        current == .ru ? "Назад" : "Back"
    }
    public static var onboardingNext: String {
        current == .ru ? "Далее" : "Next"
    }
    public static var onboardingFinish: String {
        current == .ru ? "Начать погружение" : "Get Started"
    }
    public static var onboardingSkip: String {
        current == .ru ? "Пропустить" : "Skip"
    }
    
    // MARK: - Software Updates (Обновление ПО)
    public static var updatesSectionTitle: String {
        current == .ru ? "Обновление ПО" : "Software Update"
    }
    public static var updatesSectionSubtitle: String {
        current == .ru ? "Проверка наличия и установка свежих версий Aura" : "Check for and install new Aura releases"
    }
    public static var checkUpdatesButton: String {
        current == .ru ? "Проверить обновления" : "Check for Updates"
    }
    public static var checkingUpdates: String {
        current == .ru ? "Проверка наличия обновлений..." : "Checking for updates..."
    }
    public static var upToDate: String {
        current == .ru ? "У вас установлена последняя версия" : "Aura is up to date"
    }
    public static var newVersionAvailable: String {
        current == .ru ? "Доступна новая версия" : "New Version Available"
    }
    public static var currentVersionLabel: String {
        current == .ru ? "Текущая версия" : "Current Version"
    }
    public static var latestVersionLabel: String {
        current == .ru ? "Свежая версия" : "Latest Version"
    }
    public static var downloadAndInstall: String {
        current == .ru ? "Скачать и обновить" : "Download & Update"
    }
    public static var downloading: String {
        current == .ru ? "Загрузка обновления..." : "Downloading update..."
    }
    public static var installAndRelaunch: String {
        current == .ru ? "Перезапустить и обновить" : "Relaunch & Install"
    }
    public static var openDMG: String {
        current == .ru ? "Открыть образ диска (DMG)" : "Open Disk Image (DMG)"
    }
    public static var viewOnGitHub: String {
        current == .ru ? "Смотреть на GitHub" : "View on GitHub"
    }
    public static var autoCheckOnLaunch: String {
        current == .ru ? "Проверять обновления автоматически" : "Automatically check for updates"
    }
    public static var autoCheckOnLaunchSub: String {
        current == .ru ? "Проверять наличие новых версий при запуске Aura" : "Check for new versions on Aura startup"
    }
    public static var releaseNotesTitle: String {
        current == .ru ? "Что нового в этом обновлении" : "What's New in this Release"
    }
    public static var lastChecked: String {
        current == .ru ? "Последняя проверка" : "Last checked"
    }
    public static var cancelDownload: String {
        current == .ru ? "Отмена" : "Cancel"
    }
    public static var checkUpdatesMenu: String {
        current == .ru ? "Проверить обновления..." : "Check for Updates..."
    }
    public static var readyToInstallDesc: String {
        current == .ru ? "Обновление успешно загружено и готово к установке." : "Update successfully downloaded and ready to install."
    }
}

