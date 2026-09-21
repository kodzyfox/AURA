import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @ObservedObject private var launchAtLogin = LaunchAtLoginManager.shared
    @ObservedObject private var performance = PerformanceManager.shared
    @ObservedObject private var accentManager = AccentColorManager.shared
    @EnvironmentObject var music: MusicController
    @AppStorage("aura.appearance") private var appearance: Appearance = .system
    @AppStorage("aura.backgroundMode") private var backgroundMode: Bool = true
    @AppStorage("aura.hideFromDock") private var hideFromDock: Bool = false
    @AppStorage("aura.windowCloseBehavior") private var windowCloseBehavior: WindowCloseBehavior = .hideToMenuBar
    @AppStorage("aura.hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @State private var section: NavigationSection = .overview
    @State private var saveSheet = false
    @State private var presetName = L10n.defaultPresetName
    @State private var showOnboarding = false
    @State private var showQueueSheet = false
    @State private var isDragTargeted = false
    @State private var showAnalysisDetails = false
    @State private var spotifyTestResult: ConnectionTestResult?
    @State private var musicTestResult: ConnectionTestResult?
    @State private var customAccentColor: Color = AccentColorManager.shared.accent
    @ObservedObject private var updater = UpdateManager.shared
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .top) {
            if music.isMiniPlayer {
                MiniPlayerView()
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else if music.isCoverMode {
                CoverView()
                    .transition(.opacity)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    sidebar
                    
                    VStack(spacing: 0) {
                        topbar
                        Divider().opacity(0.3)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 28) {
                                heading
                                
                                if let message = music.message {
                                    HStack(spacing: 12) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundStyle(Theme.accent)
                                        Text(message)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.textPrimary)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                }
                                
                                switch section {
                                case .sources:
                                    sources
                                case .presets:
                                    presetLibrary
                                case .effects:
                                    effectLibraryFull
                                case .lastfm:
                                    LastFMView()
                                case .settings:
                                    settingsView
                                default:
                                    overview
                                }
                                
                                footer
                            }
                            .padding(32)
                        }
                    }
                    .background(Theme.background)
                }
            }

            // Плавающий баннер уведомлений
            AppNotificationBannerView()
                .padding(.top, 10)
                .padding(.horizontal, 24)
                .zIndex(100)

            // Индикатор Drag & Drop локальных аудиофайлов
            if isDragTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
                    .background(Theme.accent.opacity(0.1))
                    .overlay(
                        VStack(spacing: 14) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.accent)
                            Text(L10n.dropFilesHere)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.dropFilesSub)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(28)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    )
                    .allowsHitTesting(false)
                    .padding(16)
                    .transition(.opacity)
                    .zIndex(99)
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .onReceive(timer) { _ in music.poll() }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onDrop(of: ["public.file-url"], isTargeted: $isDragTargeted) { providers in
            handleFileDrop(providers: providers)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showQueueSheet) {
            LocalQueueView(isPresented: $showQueueSheet)
        }
        .sheet(isPresented: $saveSheet) {
            VStack(alignment: .leading, spacing: 20) {
                Label(L10n.savePresetTitle, systemImage: "sparkles")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField(L10n.presetNamePlaceholder, text: $presetName)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Button(L10n.cancel) { saveSheet = false }
                        .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button(L10n.save) {
                        music.savePreset(presetName)
                        saveSheet = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(28)
            .frame(width: 380)
        }
    }
    
    private var appIconImage: NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let img = NSImage(named: "AppIcon") {
            return img
        }
        let fallbackPath = "Resources/AppIcon.png"
        if FileManager.default.fileExists(atPath: fallbackPath) {
            return NSImage(contentsOfFile: fallbackPath)
        }
        return nil
    }

    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    defer { group.leave() }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    } else if let url = item as? URL {
                        urls.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                music.addLocalFiles(urls)
            }
        }
        return true
    }

    // MARK: - Sidebar (Ширина 260px, аккуратные отступы под кнопки окна)
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Фиксированная шапка сайдбара: чистый отступ под кнопки окна macOS + логотип Aura
            VStack(alignment: .leading, spacing: 8) {
                // Выделенная зона под кнопки окна macOS (Traffic lights: x=18..72, y=12..28)
                Color.clear
                    .frame(height: 28)
                
                // Логотип приложения в точности по стилю фирменной иконки
                HStack(spacing: 12) {
                    if let icon = appIconImage {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: Theme.accent.opacity(0.4), radius: 6, x: 0, y: 0)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.accentGradient)
                    }
                    
                    Text("Λ U R Λ")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .tracking(4.5)
                        .foregroundStyle(Theme.accentGradient)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.yourSpace)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 2)
                    
                    ForEach(NavigationSection.allCases) { item in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { section = item }
                        } label: {
                            HStack(spacing: 8) {
                                Label(item.localizedTitle, systemImage: item.symbol)
                                    .font(.system(size: 12, weight: section == item ? .semibold : .regular))
                                Spacer()
                                if item == .settings && updater.updateAvailable {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 7, height: 7)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                section == item ? Theme.accent.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(section == item ? Theme.accent : Theme.textSecondary)
                        .padding(.horizontal, 6)
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    Text(L10n.nowInAura)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 14)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(music.playing ? Theme.green : Theme.textTertiary)
                            .frame(width: 7, height: 7)
                        Text(music.playing ? L10n.playback : L10n.paused)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    
                    Divider().padding(.vertical, 6)
                    
                    Toggle(isOn: $music.dynamicWallpaperEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.wallpaperFromMusic)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.wallpaperSub)
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .padding(.horizontal, 14)
                    .help("Автоматически ставить обложку текущего трека на обои и экран блокировки Mac")
                    
                    if music.dynamicWallpaperEnabled {
                        Picker(L10n.wallpaperStyle, selection: $music.wallpaperStyle) {
                            ForEach(WallpaperStyle.allCases) { style in
                                Label(style.localizedName, systemImage: style.symbol).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .controlSize(.small)
                        .padding(.horizontal, 14)
                        .padding(.top, 2)
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    // Заставка на весь экран
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            music.toggleCoverMode()
                        }
                    } label: {
                        Label(L10n.screensaverMode, systemImage: "sparkles.tv")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.top, 2)
                    .help("Полноэкранный плеер в стиле Lock Screen (Control+Command+F)")
                    
                    // Переход в мини-плеер из сайдбара
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            music.toggleMiniPlayer()
                        }
                    } label: {
                        Label(L10n.miniPlayer, systemImage: "pip")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
                    .help("Компактный режим Always on Top (Cmd+Shift+M)")
                    
                    Divider().padding(.vertical, 8)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.green)
                        Text(L10n.current == .ru ? "Aura для macOS" : "Aura for macOS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 260)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.sidebarBackground)
    }
    
    // MARK: - Settings View (Оформление, Язык, Фоновый режим, Сброс, О программе)
    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 1. Оформление (Тема интерфейса)
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.appearance)
                            .font(.system(size: 14, weight: .bold))
                        Text(L10n.appearanceSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                HStack(spacing: 12) {
                    ForEach(Appearance.allCases) { app in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appearance = app
                            }
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: app.symbol)
                                    .font(.system(size: 22))
                                    .foregroundStyle(appearance == app ? Theme.accent : Theme.textSecondary)
                                
                                Text(app.localizedName)
                                    .font(.system(size: 12, weight: appearance == app ? .semibold : .regular))
                                    .foregroundStyle(appearance == app ? Theme.textPrimary : Theme.textSecondary)
                                
                                if appearance == app {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 10))
                                        Text(L10n.current == .ru ? "Активна" : "Active")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundStyle(Theme.accent)
                                } else {
                                    Text(" ")
                                        .font(.system(size: 10))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                appearance == app ? Theme.accent.opacity(0.12) : Theme.cardBackground,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(appearance == app ? Theme.accent.opacity(0.6) : Theme.cardBorder, lineWidth: appearance == app ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
            
            // 2. Язык интерфейса
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.language)
                            .font(.system(size: 14, weight: .bold))
                        Text(L10n.languageSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                HStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            l10n.setLanguage(lang)
                        } label: {
                            HStack(spacing: 12) {
                                Text(lang == .ru ? "🇷🇺" : "🇬🇧")
                                    .font(.system(size: 22))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lang.title)
                                        .font(.system(size: 13, weight: l10n.language == lang ? .semibold : .regular))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(lang.shortTitle)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                                
                                Spacer()
                                
                                if l10n.language == lang {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                l10n.language == lang ? Theme.accent.opacity(0.12) : Theme.cardBackground,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(l10n.language == lang ? Theme.accent.opacity(0.6) : Theme.cardBorder, lineWidth: l10n.language == lang ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))

            // 3. Цвет акцента
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.language == .ru ? "Цвет акцента" : "Accent Color")
                            .font(.system(size: 14, weight: .bold))
                        Text(l10n.language == .ru ? "Цвет интерфейса, кнопок и эффектов" : "UI highlight, buttons, and effects color")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                // Preset swatches
                HStack(spacing: 8) {
                    ForEach(AccentColorManager.palette, id: \.name) { preset in
                        let isSelected = accentManager.accent == preset.color
                        Button {
                            accentManager.select(preset.color)
                            customAccentColor = preset.color
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 28, height: 28)
                                if isSelected {
                                    Circle()
                                        .strokeBorder(.white.opacity(0.9), lineWidth: 2.5)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(preset.name)
                        .scaleEffect(isSelected ? 1.18 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }

                    Spacer(minLength: 4)

                    // Custom colour picker
                    ColorPicker("", selection: $customAccentColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 28, height: 28)
                        .help(l10n.language == .ru ? "Свой цвет" : "Custom color")
                        .onChange(of: customAccentColor) { _, newColor in
                            accentManager.selectCustom(newColor)
                        }

                    // Reset to default
                    Button {
                        accentManager.resetToDefault()
                        customAccentColor = AccentColorManager.palette[0].color
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 28, height: 28)
                            .background(Theme.cardBackground, in: Circle())
                            .overlay(Circle().strokeBorder(Theme.cardBorder))
                    }
                    .buttonStyle(.plain)
                    .help(l10n.language == .ru ? "Сбросить цвет" : "Reset to default")
                }
            }
            .padding(20)
            .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))

            // 4. Фоновый режим и интеграция в macOS
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.backgroundModeSection)
                            .font(.system(size: 14, weight: .bold))
                        Text(L10n.backgroundSectionSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                VStack(spacing: 12) {
                    Toggle(isOn: $backgroundMode) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.runInBackground)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(L10n.whenWindowClosed)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.vertical, 8)
                    
                    Divider().opacity(0.4)
                    
                    Toggle(isOn: $hideFromDock) {
                        HStack(spacing: 12) {
                            Image(systemName: "dock.rectangle")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.hideFromDock)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(L10n.menuBarOnly)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.vertical, 8)
                    .onChange(of: hideFromDock) { _, _ in
                        WindowCloseHandler.shared.updateDockVisibility()
                    }
                    
                    Divider().opacity(0.4)
                    
                    Toggle(isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.toggle(enabled: $0) }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.launchAtLogin)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(L10n.launchAtLoginSub)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.vertical, 8)
                    
                    Divider().opacity(0.4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.onWindowClose)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(L10n.onWindowCloseSub)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        
                        Picker("", selection: $windowCloseBehavior) {
                            ForEach(WindowCloseBehavior.allCases) { behavior in
                                Text(behavior.localizedName).tag(behavior)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                    
                    Divider().opacity(0.4)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.onboardingWelcome)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.onboardingSubtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                        Button {
                            showOnboarding = true
                        } label: {
                            Text(L10n.openOnboarding)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(Theme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(20)
            .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
            
            // 5. Производительность и энергосбережение
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.performanceSectionTitle)
                            .font(.system(size: 14, weight: .bold))
                        Text(L10n.performanceSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                // Выбор качества (Visual Quality)
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.visualQualityTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    HStack(spacing: 10) {
                        ForEach(VisualQuality.allCases) { q in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    performance.quality = q
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(q == .automatic ? "⚡️" : (q == .high ? "💎" : (q == .balanced ? "⚖️" : "🔋")))
                                        Spacer()
                                        if performance.quality == q {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Theme.accent)
                                        }
                                    }
                                    Text(q.localizedName)
                                        .font(.system(size: 11, weight: performance.quality == q ? .bold : .medium))
                                        .foregroundStyle(performance.quality == q ? Theme.textPrimary : Theme.textSecondary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, minHeight: 65, alignment: .topLeading)
                                .padding(12)
                                .background(
                                    performance.quality == q ? Theme.accent.opacity(0.12) : Theme.cardBackground,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(performance.quality == q ? Theme.accent.opacity(0.6) : Theme.cardBorder, lineWidth: performance.quality == q ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().opacity(0.4)
                
                // Переключатель отключения тяжелых эффектов на батарее
                Toggle(isOn: $performance.disableExpensiveEffectsOnBattery) {
                    HStack(spacing: 12) {
                        Image(systemName: "battery.100.bolt")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.disableOnBatteryTitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.disableOnBatterySubtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .padding(.vertical, 4)
                
                Divider().opacity(0.4)
                
                // Диагностика нагрузки в реальном времени
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.diagnosticsTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        // Источник питания
                        HStack(spacing: 10) {
                            Image(systemName: performance.isOnBattery ? "battery.75" : "powerplug.fill")
                                .foregroundStyle(performance.isOnBattery ? Theme.orange : Theme.green)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.powerSourceTitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textTertiary)
                                Text(performance.powerSourceDescription)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                        
                        // Ограничение FPS
                        HStack(spacing: 10) {
                            Image(systemName: "speedometer")
                                .foregroundStyle(Theme.accent)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.currentFPSTitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textTertiary)
                                Text("\(performance.targetFPS) FPS (\(performance.effectiveQuality.localizedName))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                        
                        // Нагрев системы
                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(performance.thermalState == .nominal ? Theme.green : (performance.thermalState == .fair ? Theme.orange : Color.red))
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.thermalsTitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textTertiary)
                                Text(performance.thermalStateDescription)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                        
                        // Дисплеи и масштаб
                        HStack(spacing: 10) {
                            Image(systemName: "display.2")
                                .foregroundStyle(Theme.accentSecondary)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.monitorsTitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textTertiary)
                                Text("\(performance.screensDescription) · \(Int(performance.wallpaperPixelScale * 100))%")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                    }
                }
            }
            .padding(20)
            .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
            
            // 6. Сброс настроек и управление
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.resetSettingsTitle)
                            .font(.system(size: 14, weight: .bold))
                        Text(L10n.resetSettingsSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button {
                        withAnimation { music.settings = Atmosphere() }
                    } label: {
                        Label(L10n.resetToDefaults, systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.red.opacity(0.9))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.red.opacity(0.3)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
            
            // 7. Обновление ПО (Software Update)
            softwareUpdateCard
            
            // 8. О программе Aura
            HStack(spacing: 16) {
                if let icon = appIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.accentGradient)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Aura")
                            .font(.system(size: 15, weight: .bold))
                        Text("v\(updater.currentVersion)")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.15), in: Capsule())
                            .foregroundStyle(Theme.accent)
                    }
                    Text("\(L10n.nativeMacApp) • by Kodzy")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                Button {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "by Kodzy"
                        ]
                    )
                } label: {
                    Label(L10n.openAboutDialog, systemImage: "info.circle")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
        }
    }
    
    // MARK: - Карточка обновления ПО (Software Update)
    private var softwareUpdateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(updater.updateAvailable ? Color.orange : Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(L10n.updatesSectionTitle)
                            .font(.system(size: 14, weight: .bold))
                        
                        if updater.updateAvailable {
                            Text(L10n.newVersionAvailable)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.18), in: Capsule())
                                .foregroundStyle(Color.orange)
                        }
                    }
                    Text(L10n.updatesSectionSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                // Кнопка проверки
                Button {
                    updater.checkForUpdates(manual: true)
                } label: {
                    HStack(spacing: 6) {
                        if updater.isChecking {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text(updater.isChecking ? L10n.checkingUpdates : L10n.checkUpdatesButton)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                }
                .buttonStyle(.plain)
                .disabled(updater.isChecking)
            }
            
            // Текущая версия и статус
            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Text("\(L10n.currentVersionLabel):")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                    Text("v\(updater.currentVersion)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                }
                
                Divider().frame(height: 12).opacity(0.4)
                
                if let lastCheck = updater.lastCheckedDate {
                    HStack(spacing: 5) {
                        Text("\(L10n.lastChecked):")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                        Text(lastCheck, style: .time)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                Spacer()
                
                if updater.isUpToDate && !updater.updateAvailable {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.green)
                        Text(L10n.upToDate)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.green)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Если есть ошибка проверки
            if let err = updater.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.red)
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(10)
                .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // БЛОК ДОСТУПНОГО ОБНОВЛЕНИЯ
            if let release = updater.latestRelease, updater.updateAvailable {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Aura v\(release.versionString)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            if let releaseName = release.name, !releaseName.isEmpty {
                                Text(releaseName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            if let url = URL(string: release.htmlUrl) {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(L10n.viewOnGitHub)
                                    .font(.system(size: 11))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Список изменений (Release Notes)
                    if let notes = release.body, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.releaseNotesTitle)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                            
                            ScrollView {
                                Text(notes)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textPrimary.opacity(0.85))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(maxHeight: 120)
                            .padding(10)
                            .background(Theme.cardBackground.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                        }
                    }
                    
                    // Состояние загрузки / установки
                    switch updater.downloadState {
                    case .idle:
                        HStack(spacing: 12) {
                            Button {
                                updater.startDownload()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text(L10n.downloadAndInstall)
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        
                    case .downloading(let progress, let read, let total):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(L10n.downloading)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(String(format: "%.1f MB / %.1f MB (%.0f%%)", Double(read) / 1_048_576.0, Double(total) / 1_048_576.0, progress * 100))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            
                            ProgressView(value: progress)
                                .tint(Theme.accent)
                            
                            Button(L10n.cancelDownload) {
                                updater.cancelDownload()
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                        
                    case .readyToInstall:
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.green)
                                Text(L10n.readyToInstallDesc)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            
                            HStack(spacing: 12) {
                                Button {
                                    updater.installAndRelaunch()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "restart.circle.fill")
                                        Text(L10n.installAndRelaunch)
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Theme.green, in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.black)
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    updater.openDMGDirectly()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "externaldrive")
                                        Text(L10n.openDMG)
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .background(Theme.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.green.opacity(0.3)))
                        
                    case .failed(let msg):
                        VStack(alignment: .leading, spacing: 6) {
                            Text(msg)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.red)
                            Button(L10n.downloadAndInstall) {
                                updater.startDownload()
                            }
                            .font(.system(size: 11, weight: .medium))
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.accent.opacity(0.4)))
            }
            
            Divider().opacity(0.4)
            
            // Автоматическая проверка обновлений при запуске
            Toggle(isOn: $updater.autoCheckOnLaunch) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.autoCheckOnLaunch)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(L10n.autoCheckOnLaunchSub)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .toggleStyle(.switch)
            .padding(.horizontal, 2)
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(updater.updateAvailable ? Color.orange.opacity(0.4) : Theme.cardBorder))
    }
    
    // MARK: - Topbar
    private var topbar: some View {
        HStack {
            HStack(spacing: 8) {
                Text(L10n.current == .ru ? "Ваше пространство" : "Your Space")
                    .foregroundStyle(Theme.textTertiary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
                Text(section.localizedTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .font(.system(size: 11))
            
            Spacer()
            
            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        music.toggleMiniPlayer()
                    }
                } label: {
                    Label(L10n.miniPlayer, systemImage: "pip")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder))
                }
                .buttonStyle(.plain)
                .help("Cmd+Shift+M")
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        music.toggleCoverMode()
                    }
                } label: {
                    Label(L10n.screensaverMode, systemImage: "sparkles.tv")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder))
                }
                .buttonStyle(.plain)
                .help("Control+Command+F")
            }
            
            Text(L10n.companionBadge)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 8)
        }
        .padding(.horizontal, 32)
        .frame(height: 58)
    }
    
    // MARK: - Heading
    private var heading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.headingKicker)
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.accent)
            
            Text(headingTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            
            Text(L10n.headingSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
    }
    
    private var headingTitle: String {
        switch section {
        case .sources: return L10n.headingTitleSources
        case .presets: return L10n.headingTitlePresets
        case .effects: return L10n.headingTitleEffects
        case .lastfm: return L10n.headingTitleLastFM
        case .settings: return L10n.headingTitleSettings
        case .overview: return L10n.headingTitleOverview
        }
    }
    
    // MARK: - Overview Tab
    private var overview: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 24) {
                // Левая колонка: предпросмотр + плеер + эффекты
                VStack(spacing: 16) {
                    HStack {
                        HStack(spacing: 6) {
                            Text(L10n.preview)
                                .font(.system(size: 12, weight: .semibold))
                            Circle()
                                .fill(Theme.green)
                                .frame(width: 5, height: 5)
                        }
                        Spacer()
                        Text(music.activePlayerName ?? music.source.localizedName)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    
                    AtmosphereView()
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                    
                    player
                    
                    // Блок выбора настроений (эффектов) прямо под плеером без пустого зазора
                    effectLibrary
                    
                    HStack {
                        Label(
                            music.activePlayerName != nil ? "\(L10n.playingNow): \(music.activePlayerName!)" : L10n.waitingForMusic,
                            systemImage: "headphones"
                        )
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                music.toggleCoverMode()
                            }
                        } label: {
                            Label(L10n.screensaverMode, systemImage: "sparkles.tv")
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                
                // Правая колонка: точные настройки
                customization
                    .frame(width: 280)
            }
            
            // Баннер перехода в источники
            Button {
                section = .sources
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundStyle(Theme.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.bannerTitle)
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.bannerSub)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(18)
                .background(Theme.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.green.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Player Component
    private var player: some View {
        VStack(spacing: 12) {
            playerHeader
            playerProgressBar
        }
        .padding(14)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.cardBorder))
    }

    private var playerHeader: some View {
        HStack(spacing: 14) {
            AlbumImage(image: music.artwork ?? music.fallback)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(music.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(music.artist)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)

                    audioAnalysisBadge
                }
            }
            
            Spacer(minLength: 8)
            
            playerControls
            
            if music.source == .local {
                playerVolume
            }
        }
    }

    private var audioAnalysisBadge: some View {
        let mode = AudioAnalysisService.shared.analysisMode
        return Button {
            showAnalysisDetails.toggle()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: mode.icon)
                    .font(.system(size: 8))
                Text(mode.badgeTitle)
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(mode.color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(mode.color.opacity(0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(mode.color.opacity(0.3), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showAnalysisDetails) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: mode.icon)
                        .foregroundStyle(mode.color)
                    Text(mode.localizedName)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(analysisModeDescription(mode))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: 240)
            }
            .padding(12)
        }
    }

    private var playerControls: some View {
        HStack(spacing: 10) {
            if music.source == .local {
                Button {
                    showQueueSheet = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 11))
                        if !music.localQueue.isEmpty {
                            Text("\(music.localFileIndex + 1)/\(music.localQueue.count)")
                                .font(.system(size: 9, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Theme.cardBorder.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help(L10n.localQueueTitle)
            }

            Button { music.skip(-1) } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help(L10n.previousTrackHint)
            
            Button { music.toggle() } label: {
                Image(systemName: music.playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .frame(width: 34, height: 34)
                    .background(Theme.green, in: Circle())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .help(L10n.playPauseHint)
            
            Button { music.skip(1) } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help(L10n.nextTrackHint)
            
            Button {
                music.toggleLike()
            } label: {
                Image(systemName: music.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 14))
                    .foregroundStyle(music.isLiked ? Theme.magenta : Theme.textSecondary)
                    .shadow(color: music.isLiked ? Theme.magenta.opacity(0.6) : .clear, radius: 4)
            }
            .buttonStyle(.plain)
            .help(music.isLiked ? L10n.inFavorites : L10n.addToFavorites)
        }
    }

    private var playerVolume: some View {
        HStack(spacing: 6) {
            Button {
                music.toggleMute()
            } label: {
                Image(systemName: music.isMuted || music.volume == 0 ? "speaker.slash.fill" : (music.volume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.2.fill"))
                    .font(.caption)
                    .foregroundStyle(music.isMuted ? Color.red : Theme.textTertiary)
            }
            .buttonStyle(.plain)
            .help(music.isMuted ? (L10n.current == .ru ? "Включить звук" : "Unmute") : (L10n.current == .ru ? "Выключить звук" : "Mute"))

            Slider(value: Binding(
                get: { music.volume },
                set: {
                    music.volume = $0
                    if music.isMuted && $0 > 0 {
                        music.isMuted = false
                    }
                }
            ))
            .frame(width: 55)
            .controlSize(.mini)
        }
    }

    private var playerProgressBar: some View {
        HStack(spacing: 8) {
            Text(timestamp(music.position))
            Slider(
                value: Binding(
                    get: { min(music.position, max(1, music.duration)) },
                    set: { music.seek($0) }
                ),
                in: 0...max(1, music.duration)
            )
            .controlSize(.mini)
            .tint(music.artworkColor ?? Theme.accent)
            Text(timestamp(music.duration))
        }
        .font(.system(size: 9).monospacedDigit())
        .foregroundStyle(Theme.textSecondary)
    }

    private func analysisModeDescription(_ mode: AudioAnalysisMode) -> String {
        switch (mode, L10n.current) {
        case (.localFFT, .ru):
            return "Аппаратный 1024-точечный FFT (vDSP Accelerate) считывает спектр частот и ударные прямо из аудиопотока."
        case (.localFFT, .en):
            return "Hardware 1024-point FFT (vDSP Accelerate) analyzes audio frequencies and transients directly from the playback stream."
        case (.spotifyCloud, .ru):
            return "Синхронизация с официальными аудиохарактеристиками Spotify Web API: темп, энергия, танцевальность и сетка долей."
        case (.spotifyCloud, .en):
            return "Synchronized with official Spotify Web API audio features: tempo, energy, danceability, and beat-grid."
        case (.beatGrid, .ru):
            return "Интеллектуальная математическая сетка ритма (Smart Beat-Grid) адаптирует анимации под темп композиции."
        case (.beatGrid, .en):
            return "Adaptive Smart Beat-Grid calculates musical pulses and tempo curves for fluid animations."
        }
    }
    
    // MARK: - Customization Panel
    private var customization: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(Theme.accent)
                    Text(L10n.wallpaperSettings)
                        .font(.system(size: 13, weight: .bold))
                }
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Theme.textTertiary)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                // Выбор режима свечения
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.glowMode)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textTertiary)
                    
                    Menu {
                        ForEach(Effect.allCases) { eff in
                            Button {
                                withAnimation { music.settings.effect = eff }
                            } label: {
                                Label(eff.localizedName, systemImage: eff.symbol)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: music.settings.effect.symbol)
                                .foregroundStyle(Theme.accent)
                            Text(music.settings.effect.localizedName)
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Theme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.accent.opacity(0.35)))
                    }
                    .menuStyle(.borderlessButton)
                }
                
                VStack(spacing: 5) {
                    HStack {
                        Text(L10n.current == .ru ? "Интенсивность" : "Intensity")
                        Spacer()
                        Text("\(Int(music.settings.intensity * 100))%")
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Slider(value: $music.settings.intensity)
                        .tint(Theme.accent)
                }
                
                VStack(spacing: 5) {
                    HStack {
                        Text(L10n.current == .ru ? "Скорость анимации" : "Animation Speed")
                        Spacer()
                        Text(String(format: "%.1f×", music.settings.speed * 2))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Slider(value: $music.settings.speed)
                        .tint(Theme.accent)
                }
                
                VStack(spacing: 5) {
                    HStack {
                        Text(L10n.current == .ru ? "Размытие фона" : "Background Blur")
                        Spacer()
                        Text("\(Int(music.settings.blurRadius))px")
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Slider(value: $music.settings.blurRadius, in: 0...40)
                        .tint(Theme.accent)
                }
                
                VStack(spacing: 5) {
                    HStack {
                        Text(L10n.current == .ru ? "Размер обложки" : "Artwork Size")
                        Spacer()
                        Text("\(Int(music.settings.coverZoomLevel * 100))%")
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Slider(value: $music.settings.coverZoomLevel, in: 0.4...1.4)
                        .tint(Theme.accent)
                }
                
                VStack(spacing: 5) {
                    HStack {
                        Text(L10n.current == .ru ? "Масштаб свечения" : "Glow Scale")
                        Spacer()
                        Text(String(format: "%.1f×", music.settings.glowScale))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Slider(value: $music.settings.glowScale, in: 0.5...1.8)
                        .tint(Theme.accent)
                }
                
                // Audio Reactive (пульсация в такт музыке)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Audio Reactive", systemImage: "waveform.path.ecg")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Toggle("", isOn: $music.settings.audioReactive)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .tint(Theme.green)
                    }
                    
                    if music.settings.audioReactive {
                        VStack(spacing: 8) {
                            HStack {
                                Text(L10n.current == .ru ? "Чувствительность бита" : "Beat Sensitivity")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Text(String(format: "%.1f×", music.settings.reactiveSensitivity))
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Theme.green)
                            }
                            Slider(value: $music.settings.reactiveSensitivity, in: 0.5...2.0)
                                .tint(Theme.green)
                            
                            let mode = AudioAnalysisService.shared.analysisMode
                            HStack {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(mode.color)
                                        .frame(width: 5, height: 5)
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 9))
                                        .foregroundStyle(mode.color)
                                    Text(mode.localizedName)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                if mode == .localFFT {
                                    Text("1024-pt FFT")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(mode.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(mode.color.opacity(0.12), in: Capsule())
                                } else {
                                    Text("\(Int(AudioAnalysisService.shared.currentBPM)) BPM")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(mode.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(mode.color.opacity(0.12), in: Capsule())
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(12)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder, lineWidth: 1))
                
                // 8 палитр свечения
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(L10n.current == .ru ? "Палитра свечения" : "Glow Palette")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(AuraPalettes.all.first(where: { $0.id == music.settings.palette })?.localizedName ?? (L10n.current == .ru ? "Обложка" : "Artwork"))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 4), spacing: 8) {
                        ForEach(AuraPalettes.all) { p in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    music.settings.palette = p.id
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    ZStack {
                                        if p.id == 0 {
                                            if let artColor = music.artworkColor {
                                                Circle().fill(artColor)
                                            } else {
                                                Circle().fill(Theme.accentGradient)
                                            }
                                        } else {
                                            Circle().fill(
                                                LinearGradient(
                                                    colors: p.previewColors,
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        }
                                        
                                        if music.settings.palette == p.id {
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: 2)
                                                .frame(width: 22, height: 22)
                                                .shadow(color: Theme.accent, radius: 4)
                                        }
                                    }
                                    .frame(width: 18, height: 18)
                                    
                                    Text(p.localizedName)
                                        .font(.system(size: 8, weight: music.settings.palette == p.id ? .bold : .regular))
                                        .lineLimit(1)
                                        .foregroundStyle(music.settings.palette == p.id ? Theme.textPrimary : Theme.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 2)
                                .background(
                                    music.settings.palette == p.id ? Theme.accent.opacity(0.12) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(music.settings.palette == p.id ? Theme.accent.opacity(0.3) : Color.clear, lineWidth: 0.8)
                                )
                            }
                            .buttonStyle(.plain)
                            .help(p.localizedName)
                        }
                    }
                }
                
                Divider()
                
                Toggle(L10n.trackInfo, isOn: $music.settings.showInfo)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                
                Toggle(L10n.showClock, isOn: $music.settings.showClock)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                
                Divider()
                
                Text(L10n.atmosphereAndWallpapers)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                
                Toggle(L10n.playerOnLockscreen, isOn: $music.settings.showPlayerOnLockScreen)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .help("Виджет на экране блокировки Mac")
                
                Toggle(L10n.playerOnDesktop, isOn: $music.settings.showPlayerOnDesktop)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .help("Виджет на рабочем столе")
                
                Toggle(L10n.ambilightEdgeGlow, isOn: $music.settings.edgeGlow)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .help("Ambilight Edge Glow")
                
                Toggle(L10n.animatedDesktopCover, isOn: $music.settings.animatedDesktopCover)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .help("Desktop Animated Cover")
                
                // Выбор стиля пульсации обложки
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n.coverAnimationTitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(music.settings.coverAnimation.localizedName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3), spacing: 6) {
                        ForEach(CoverAnimation.allCases) { anim in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    music.settings.coverAnimation = anim
                                    if anim != .none && !music.settings.animatedDesktopCover {
                                        music.settings.animatedDesktopCover = true
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: anim.symbol)
                                        .font(.system(size: 10))
                                        .foregroundStyle(music.settings.coverAnimation == anim ? Theme.accent : Theme.textSecondary)
                                    Text(anim.localizedName)
                                        .font(.system(size: 8.5, weight: music.settings.coverAnimation == anim ? .bold : .regular))
                                        .lineLimit(1)
                                        .foregroundStyle(music.settings.coverAnimation == anim ? Theme.textPrimary : Theme.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 3)
                                .background(
                                    music.settings.coverAnimation == anim ? Theme.accent.opacity(0.12) : Color.white.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(music.settings.coverAnimation == anim ? Theme.accent.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 0.8)
                                )
                            }
                            .buttonStyle(.plain)
                            .help(anim.localizedName)
                        }
                    }
                }
                .padding(.vertical, 2)
                
                if music.settings.edgeGlow {
                    VStack(spacing: 5) {
                        HStack {
                            Text(L10n.glowBrightness)
                            Spacer()
                            Text("\(Int(music.settings.edgeGlowOpacity * 100))%")
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Slider(value: $music.settings.edgeGlowOpacity, in: 0.1...1.0)
                            .tint(Theme.accent)
                    }
                    
                    VStack(spacing: 5) {
                        HStack {
                            Text(L10n.glowSize)
                            Spacer()
                            Text("\(Int(music.settings.edgeGlowThickness)) px")
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Slider(value: $music.settings.edgeGlowThickness, in: 40...240)
                            .tint(Theme.accent)
                    }
                    
                    VStack(spacing: 5) {
                        HStack {
                            Text(L10n.glowShiftSpeed)
                            Spacer()
                            Text(String(format: "%.1f×", music.settings.edgeGlowSpeed))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Slider(value: $music.settings.edgeGlowSpeed, in: 0.2...2.5)
                            .tint(Theme.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(L10n.glowColor)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text(L10n.swatchName(music.settings.edgeGlowColorIndex))
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Theme.accent.opacity(0.14), in: Capsule())
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                            ForEach(0..<9, id: \.self) { idx in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        music.settings.edgeGlowColorIndex = idx
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        ZStack {
                                            edgeGlowCircle(idx)
                                                .frame(width: 16, height: 16)
                                            if music.settings.edgeGlowColorIndex == idx {
                                                Circle()
                                                    .strokeBorder(Color.white, lineWidth: 1.5)
                                                    .frame(width: 20, height: 20)
                                                    .shadow(color: Theme.accent.opacity(0.6), radius: 3)
                                            }
                                        }
                                        Text(L10n.swatchShortName(idx))
                                            .font(.system(size: 10, weight: music.settings.edgeGlowColorIndex == idx ? .semibold : .regular))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                            .foregroundStyle(music.settings.edgeGlowColorIndex == idx ? Theme.textPrimary : Theme.textSecondary)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 5)
                                    .background(
                                        music.settings.edgeGlowColorIndex == idx ? Theme.accent.opacity(0.16) : Color.white.opacity(0.04),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(
                                                music.settings.edgeGlowColorIndex == idx ? Theme.accent.opacity(0.6) : Color.white.opacity(0.06),
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                .help(L10n.swatchName(idx))
                            }
                        }
                    }
                }
                
                Divider()
                
                Button {
                    saveSheet = true
                } label: {
                    Label(L10n.saveAsPreset, systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.regular)
            }
            .font(.system(size: 11))
            .padding(18)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.cardBorder))
            
            Text(L10n.quoteText)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
                .lineSpacing(4)
                .padding(.horizontal, 6)
        }
    }
    
    // MARK: - Effect Library (Все 9 эффектов)
    private var effectLibrary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.chooseMood)
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Text(L10n.countEffects)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(Effect.allCases) { effect in
                    Button {
                        withAnimation { music.settings.effect = effect }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack {
                                LinearGradient(
                                    colors: effectGradient(for: effect),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: effect.symbol)
                                    .font(.system(size: 22, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .frame(height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            HStack {
                                Text(effect.localizedName)
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                if music.settings.effect == effect {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4)
                        }
                        .padding(3)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(music.settings.effect == effect ? Theme.accent : Theme.cardBorder)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var effectLibraryFull: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.nineMoodsTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Effect.allCases) { effect in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            music.settings.effect = effect
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                LinearGradient(
                                    colors: effectGradient(for: effect),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: effect.symbol)
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(effect.localizedName)
                                    .font(.headline)
                                Text(effectDescription(for: effect))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if music.settings.effect == effect {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accent)
                                    .font(.title3)
                            }
                        }
                        .padding(14)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(music.settings.effect == effect ? Theme.accent : Theme.cardBorder))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func effectGradient(for effect: Effect) -> [Color] {
        switch effect {
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
        }
    }
    
    private func effectDescription(for effect: Effect) -> String {
        switch (effect, L10n.current) {
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
        }
    }
    
    // MARK: - Sources Tab
    private var sources: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.sourcesSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(4)
            
            ForEach(Source.allCases) { source in
                sourceCard(for: source)
            }
        }
    }

    @ViewBuilder
    private func sourceCard(for source: Source) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 20) {
                SourceIconView(source: source, size: 24, color: Theme.accent)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(source.localizedName)
                            .font(.headline)
                        if music.source == source {
                            Text(L10n.current == .ru ? "Активен" : "Active")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent.opacity(0.15), in: Capsule())
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    Text(sourceDescription(source))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                Button(music.source == source ? (L10n.current == .ru ? "Выбрано" : "Selected") : (L10n.current == .ru ? "Выбрать" : "Select")) {
                    music.select(source)
                    section = .overview
                }
                .controlSize(.large)
            }

            sourceExtras(for: source)
        }
        .padding(20)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(music.source == source ? Theme.accent.opacity(0.4) : Theme.cardBorder))
    }

    @ViewBuilder
    private func sourceExtras(for source: Source) -> some View {
        if source == .spotify || source == .music {
            Divider().opacity(0.2)
            HStack(spacing: 12) {
                Button {
                    testSourceConnection(for: source)
                } label: {
                    Label(L10n.checkConnection, systemImage: "bolt.horizontal.circle")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(Theme.accent)

                let testResult = (source == .spotify ? spotifyTestResult : musicTestResult)
                if let res = testResult {
                    HStack(spacing: 5) {
                        Image(systemName: res.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        Text(res.message)
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(res.isSuccess ? Theme.green : Theme.orange)
                }
            }
        } else if source == .local {
            Divider().opacity(0.2)
            HStack(spacing: 12) {
                Button {
                    showQueueSheet = true
                } label: {
                    Label(
                        music.localQueue.isEmpty
                            ? L10n.localQueueTitle
                            : "\(L10n.localQueueTitle) (\(music.localQueue.count))",
                        systemImage: "list.bullet"
                    )
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(Theme.accent)

                Button {
                    music.openFiles()
                } label: {
                    Label(L10n.addFiles, systemImage: "plus")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.cardBorder.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(Theme.textPrimary)

                Text(L10n.dragDropFilesHint)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
        } else if source == .youtubeMusic || source == .yandexMusic || source == .nowPlaying {
            Divider().opacity(0.2)
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.system(size: 11))
                Text(L10n.current == .ru
                    ? "Нативная интеграция через системный Now Playing (MediaRemote)"
                    : "Native integration via system Now Playing (MediaRemote)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func testSourceConnection(for source: Source) {
        let bundleID = source == .spotify ? "com.spotify.client" : "com.apple.Music"
        Task { @MainActor in
            let result = await AutomationPermissionManager.shared.testConnection(bundleID: bundleID)
            if source == .spotify {
                spotifyTestResult = result
            } else {
                musicTestResult = result
            }
            AppNotificationManager.shared.show(
                type: result.isSuccess ? .success : .warning,
                title: result.isSuccess ? L10n.connectionSuccess : L10n.connectionFailed,
                message: result.message,
                actionTitle: result.permissionStatus == .denied ? L10n.openSettingsAction : nil,
                action: result.permissionStatus == .denied ? {
                    AutomationPermissionManager.shared.openAutomationSettings()
                } : nil
            )
        }
    }
    
    private func sourceDescription(_ source: Source) -> String {
        switch source {
        case .auto: return L10n.autoDetectDesc
        case .demo: return L10n.demoDesc
        case .spotify: return L10n.spotifyDesc
        case .music: return L10n.appleMusicDesc
        case .local: return L10n.localFilesDesc
        case .youtubeMusic: return L10n.current == .ru
            ? "Нативное подключение к YouTube Music через систему (браузеры, PWA, десктоп)"
            : "Native connection to YouTube Music via system (browsers, PWA, desktop)"
        case .yandexMusic: return L10n.current == .ru
            ? "Нативное подключение к Яндекс Музыке через систему (приложение или браузер)"
            : "Native connection to Yandex Music via system (app or browser)"
        case .nowPlaying: return L10n.current == .ru
            ? "Универсальный перехват любого активного медиаплеера macOS (Now Playing)"
            : "Universal capture of any active macOS media player (Now Playing)"
        }
    }

    
    // MARK: - Presets Tab
    private var presetLibrary: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Button {
                    saveSheet = true
                } label: {
                    Label(L10n.current == .ru ? "Новый пресет" : "New Preset", systemImage: "plus")
                }
                .controlSize(.large)
                
                Button {
                    music.exportPresets()
                } label: {
                    Label(L10n.exportPresets, systemImage: "square.and.arrow.up")
                }
                .controlSize(.large)
                .disabled(music.presets.isEmpty)
                
                Button {
                    music.importPresets()
                } label: {
                    Label(L10n.importPresets, systemImage: "square.and.arrow.down")
                }
                .controlSize(.large)
            }
            
            if music.presets.isEmpty {
                ContentUnavailableView(
                    L10n.noPresets,
                    systemImage: "square.stack",
                    description: Text(L10n.createFirstPreset)
                )
            } else {
                ForEach(music.presets) { preset in
                    HStack {
                        Image(systemName: preset.settings.effect.symbol)
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.headline)
                            Text("\(preset.settings.effect.localizedName) · \(L10n.current == .ru ? "Интенсивность" : "Intensity") \(Int(preset.settings.intensity * 100))%")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(L10n.applyPreset) {
                            music.settings = preset.settings
                            section = .overview
                        }
                        
                        Button(role: .destructive) {
                            music.presets.removeAll { $0.id == preset.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .help(L10n.deletePreset)
                    }
                    .padding(18)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder))
                }
            }
        }
    }
    
    // MARK: - Footer
    private var footer: some View {
        HStack {
            Text(L10n.footerNote)
            Spacer()
            Text(L10n.footerCopyright)
        }
        .font(.system(size: 10))
        .foregroundStyle(Theme.textTertiary)
        .padding(.top, 10)
    }
    
    private func timestamp(_ seconds: Double) -> String {
        let s = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", s / 60, s % 60)
    }
    
    @ViewBuilder
    private func edgeGlowCircle(_ index: Int) -> some View {
        switch index {
        case 1:
            // 1. Радужный спектр (Разноцветный круг / Полный 360° Rainbow Angular Gradient)
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.22, blue: 0.35),  // Red/Pink
                            Color(red: 1.0, green: 0.58, blue: 0.10),  // Orange
                            Color(red: 1.0, green: 0.88, blue: 0.15),  // Yellow
                            Color(red: 0.15, green: 0.90, blue: 0.45), // Green
                            Color(red: 0.0, green: 0.85, blue: 1.0),   // Cyan
                            Color(red: 0.35, green: 0.40, blue: 1.0),  // Indigo/Blue
                            Color(red: 0.85, green: 0.20, blue: 0.95), // Magenta
                            Color(red: 1.0, green: 0.22, blue: 0.35)   // Red wrap
                        ]),
                        center: .center
                    )
                )
        case 2:
            // 2. «Северное сияние» (Многоцветный перелив: Тиал, Изумруд, Электрический Циан, Космический Индиго)
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.92, blue: 0.82),  // Teal
                            Color(red: 0.10, green: 0.95, blue: 0.45), // Emerald
                            Color(red: 0.15, green: 0.65, blue: 1.0),  // Electric Blue
                            Color(red: 0.55, green: 0.20, blue: 0.98), // Indigo
                            Color(red: 0.0, green: 0.92, blue: 0.82)   // Wrap
                        ]),
                        center: .center
                    )
                )
        case 3:
            // 3. «Неоновый закат» (Многоцветный перелив: Фуксия, Закатный Янтарь, Маджента, Ультрафиолет)
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.15, blue: 0.60),  // Hot Pink
                            Color(red: 1.0, green: 0.45, blue: 0.15),  // Sunset Amber
                            Color(red: 0.95, green: 0.18, blue: 0.85), // Magenta
                            Color(red: 0.55, green: 0.12, blue: 0.90), // Dusk Violet
                            Color(red: 1.0, green: 0.15, blue: 0.60)   // Wrap
                        ]),
                        center: .center
                    )
                )
        case 4:
            Circle().fill(Color(red: 1.0, green: 0.65, blue: 0.20))  // Янтарь
        case 5:
            Circle().fill(Color(red: 0.0, green: 0.95, blue: 1.0))   // Неон циан
        case 6:
            Circle().fill(Color(red: 0.85, green: 0.27, blue: 0.94)) // Пурпур
        case 7:
            Circle().fill(Color(red: 0.12, green: 0.92, blue: 0.60)) // Изумруд
        case 8:
            Circle().fill(Color.white)                               // Белый жемчуг
        default:
            Circle().fill(music.artworkColor ?? Theme.accent)        // Цвет обложки
        }
    }
}
