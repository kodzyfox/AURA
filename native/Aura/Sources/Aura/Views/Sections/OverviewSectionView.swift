import SwiftUI

enum OverviewSettingsTab: Int, CaseIterable, Identifiable {
    case glow = 0
    case atmosphere = 1
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .glow: return L10n.current == .ru ? "Свечение" : "Glow"
        case .atmosphere: return L10n.current == .ru ? "Обои и Вырез" : "Wallpapers & Notch"
        }
    }
    
    var icon: String {
        switch self {
        case .glow: return "sparkles"
        case .atmosphere: return "display"
        }
    }
}

struct OverviewSectionView: View {
    @EnvironmentObject var music: MusicController
    @Binding var section: NavigationSection
    @Binding var saveSheet: Bool
    @Binding var showQueueSheet: Bool
    
    @State private var showAnalysisDetails = false
    @State private var settingsTab: OverviewSettingsTab = .glow

    var body: some View {
        overview
    }

    // MARK: - Overview Content
    private var overview: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 24) {
                // Левая колонка: предпросмотр + плеер + эффекты
                VStack(spacing: 16) {
                    HStack(alignment: .center, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(L10n.preview)
                                .font(.system(size: 12, weight: .semibold))
                            Circle()
                                .fill(music.playing ? Theme.green : Theme.textTertiary)
                                .frame(width: 5, height: 5)
                        }
                        
                        Spacer()
                        
                        // Селектор стиля обоев для предпросмотра (Постер / На весь экран / Минимализм)
                        HStack(spacing: 4) {
                            ForEach(WallpaperStyle.allCases) { style in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        music.wallpaperStyle = style
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: style.symbol)
                                            .font(.system(size: 9))
                                        Text(style.localizedName)
                                            .font(.system(size: 9.5, weight: music.wallpaperStyle == style ? .bold : .medium))
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(
                                        music.wallpaperStyle == style ? Theme.accent.opacity(0.2) : Color.white.opacity(0.04),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(music.wallpaperStyle == style ? Theme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 0.8)
                                    )
                                    .foregroundStyle(music.wallpaperStyle == style ? Theme.textPrimary : Theme.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .help(style.localizedName)
                            }
                        }
                        
                        Spacer()
                        
                        // Быстрое меню выбора анимации/пульсации обложки
                        Menu {
                            ForEach(CoverAnimation.allCases) { anim in
                                Button {
                                    withAnimation {
                                        music.settings.coverAnimation = anim
                                    }
                                } label: {
                                    Label(anim.localizedName, systemImage: anim.symbol)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: music.settings.coverAnimation.symbol)
                                    .font(.system(size: 9))
                                    .foregroundStyle(music.settings.coverAnimation == .none ? Theme.textTertiary : Theme.accent)
                                Text(music.settings.coverAnimation.localizedName)
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundStyle(music.settings.coverAnimation == .none ? Theme.textTertiary : Theme.textPrimary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 7))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.06), lineWidth: 0.8))
                        }
                        .menuStyle(.borderlessButton)
                        .help(L10n.coverAnimationTitle)
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
                    .frame(width: 300)
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

    // MARK: - Effect Library (Мини-библиотека под плеером)
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
                            EffectThumbnailPreview(effect: effect, isSelected: music.settings.effect == effect)
                            
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
            
            VStack(alignment: .leading, spacing: 14) {
                // Переключатель вкладок настроек
                HStack(spacing: 4) {
                    ForEach(OverviewSettingsTab.allCases) { tab in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                settingsTab = tab
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 10))
                                Text(tab.title)
                                    .font(.system(size: 10, weight: settingsTab == tab ? .bold : .medium))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                settingsTab == tab ? Theme.accent.opacity(0.18) : Color.white.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(
                                        settingsTab == tab ? Theme.accent.opacity(0.45) : Color.white.opacity(0.05),
                                        lineWidth: 0.8
                                    )
                            )
                            .foregroundStyle(settingsTab == tab ? Theme.textPrimary : Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 2)
                
                if settingsTab == .glow {
                    // === ВКЛАДКА 1: СВЕЧЕНИЕ И ЭФФЕКТЫ ===
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
                            Text("\(Int(max(2.0, music.settings.blurRadius)))px")
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Slider(
                            value: Binding(
                                get: { max(2.0, music.settings.blurRadius) },
                                set: { music.settings.blurRadius = max(2.0, $0) }
                            ),
                            in: 2...40
                        )
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
                    
                    // Выбор режима анимации / пульсации обложки
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(L10n.coverAnimationTitle)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .layoutPriority(1)
                            Spacer()
                            Text(music.settings.coverAnimation.localizedName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(music.settings.coverAnimation == .none ? Theme.textTertiary : Theme.accent)
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                            ForEach(CoverAnimation.allCases) { anim in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        music.settings.coverAnimation = anim
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: anim.symbol)
                                            .font(.system(size: 10))
                                            .foregroundStyle(music.settings.coverAnimation == anim ? Theme.accent : Theme.textSecondary)
                                        Text(anim.localizedName)
                                            .font(.system(size: 9.5, weight: music.settings.coverAnimation == anim ? .bold : .regular))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                            .foregroundStyle(music.settings.coverAnimation == anim ? Theme.textPrimary : Theme.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 8)
                                    .background(
                                        music.settings.coverAnimation == anim ? Theme.accent.opacity(0.14) : Color.white.opacity(0.04),
                                        in: RoundedRectangle(cornerRadius: 7)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .strokeBorder(music.settings.coverAnimation == anim ? Theme.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 0.8)
                                    )
                                }
                                .buttonStyle(.plain)
                                .help(anim.localizedDescription)
                            }
                        }
                        
                        Text(music.settings.coverAnimation.localizedDescription)
                            .font(.system(size: 9.5))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
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
                } else {
                    // === ВКЛАДКА 2: ОБОИ, ЭКРАН И ЧЕЛКА MACBOOK ===
                    // Свечение вокруг выреза экрана / Dynamic Island
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(L10n.notchGlowToggle, systemImage: "macbook.gen2")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Toggle("", isOn: $music.settings.notchGlow)
                                .toggleStyle(.switch)
                                .controlSize(.mini)
                                .tint(Theme.accent)
                        }
                        
                        Text(L10n.notchGlowSub)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                        
                        if music.settings.notchGlow {
                            VStack(alignment: .leading, spacing: 10) {
                                // 3-позиционный селектор режима, который идеально помещается в карточку
                                HStack(spacing: 5) {
                                    ForEach(NotchGlowMode.allCases) { mode in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.18)) {
                                                music.settings.notchGlowMode = mode
                                            }
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: modeIcon(mode))
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(music.settings.notchGlowMode == mode ? Theme.accent : Theme.textSecondary)
                                                Text(modeShortName(mode))
                                                    .font(.system(size: 9.5, weight: music.settings.notchGlowMode == mode ? .bold : .medium))
                                                    .lineLimit(1)
                                                    .foregroundStyle(music.settings.notchGlowMode == mode ? Theme.textPrimary : Theme.textTertiary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 7)
                                            .padding(.horizontal, 3)
                                            .background(
                                                music.settings.notchGlowMode == mode ? Theme.accent.opacity(0.18) : Color.white.opacity(0.04),
                                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .strokeBorder(
                                                        music.settings.notchGlowMode == mode ? Theme.accent.opacity(0.55) : Color.white.opacity(0.06),
                                                        lineWidth: 1
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .help(mode.localizedName)
                                    }
                                }
                                
                                Text(modeDescription(music.settings.notchGlowMode))
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(Theme.textTertiary)
                                    .lineSpacing(2)
                                    .padding(.horizontal, 2)
                                
                                VStack(spacing: 4) {
                                    HStack {
                                        Text(L10n.notchRadiusLabel)
                                            .foregroundStyle(Theme.textSecondary)
                                        Spacer()
                                        Text("\(Int(music.settings.notchGlowRadius)) pt")
                                            .monospacedDigit()
                                    }
                                    Slider(value: $music.settings.notchGlowRadius, in: 10...45)
                                        .tint(Theme.accent)
                                }
                                
                                Toggle(L10n.notchHUDOnTrackChangeToggle, isOn: $music.settings.notchHUDOnTrackChange)
                                    .font(.system(size: 10.5))
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder, lineWidth: 1))
                        }
                    }
                    
                    Divider()
                    
                    // Ambilight Edge Glow
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(L10n.ambilightEdgeGlow, systemImage: "sparkles.rectangle.stack")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Toggle("", isOn: $music.settings.edgeGlow)
                                .toggleStyle(.switch)
                                .controlSize(.mini)
                                .tint(Theme.accent)
                        }
                        
                        if music.settings.edgeGlow {
                            VStack(spacing: 8) {
                                VStack(spacing: 4) {
                                    HStack {
                                        Text(L10n.glowBrightness)
                                        Spacer()
                                        Text("\(Int(music.settings.edgeGlowOpacity * 100))%")
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                    Slider(value: $music.settings.edgeGlowOpacity, in: 0.1...1.0)
                                        .tint(Theme.accent)
                                }
                                
                                VStack(spacing: 4) {
                                    HStack {
                                        Text(L10n.glowSize)
                                        Spacer()
                                        Text("\(Int(music.settings.edgeGlowThickness)) px")
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                    Slider(value: $music.settings.edgeGlowThickness, in: 40...240)
                                        .tint(Theme.accent)
                                }
                                
                                VStack(spacing: 4) {
                                    HStack {
                                        Text(L10n.glowShiftSpeed)
                                        Spacer()
                                        Text(String(format: "%.1f×", music.settings.edgeGlowSpeed))
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                    Slider(value: $music.settings.edgeGlowSpeed, in: 0.2...2.5)
                                        .tint(Theme.accent)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(L10n.glowColor)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(Theme.textSecondary)
                                        Spacer()
                                        Text(L10n.swatchName(music.settings.edgeGlowColorIndex))
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(Theme.accent)
                                    }
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3), spacing: 5) {
                                        ForEach(0..<9, id: \.self) { idx in
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.18)) {
                                                    music.settings.edgeGlowColorIndex = idx
                                                }
                                            } label: {
                                                HStack(spacing: 5) {
                                                    ZStack {
                                                        edgeGlowCircle(idx)
                                                            .frame(width: 14, height: 14)
                                                        if music.settings.edgeGlowColorIndex == idx {
                                                            Circle()
                                                                .strokeBorder(Color.white, lineWidth: 1.5)
                                                                .frame(width: 18, height: 18)
                                                                .shadow(color: Theme.accent.opacity(0.6), radius: 3)
                                                        }
                                                    }
                                                    Text(L10n.swatchShortName(idx))
                                                        .font(.system(size: 9.5, weight: music.settings.edgeGlowColorIndex == idx ? .semibold : .regular))
                                                        .lineLimit(1)
                                                        .minimumScaleFactor(0.8)
                                                        .foregroundStyle(music.settings.edgeGlowColorIndex == idx ? Theme.textPrimary : Theme.textSecondary)
                                                    Spacer(minLength: 0)
                                                }
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 4)
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
                            .padding(10)
                            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder, lineWidth: 1))
                        }
                    }
                    
                    Divider()
                    
                    // Виджеты на экране блокировки и рабочем столе
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.atmosphereAndWallpapers)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textTertiary)
                        
                        Toggle(L10n.playerOnLockscreen, isOn: $music.settings.showPlayerOnLockScreen)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .help(L10n.current == .ru ? "Виджет на экране блокировки Mac" : "Mac Lock Screen widget")
                        
                        Toggle(L10n.playerOnDesktop, isOn: $music.settings.showPlayerOnDesktop)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .help(L10n.current == .ru ? "Виджет на рабочем столе" : "Desktop widget")
                        
                        Toggle(L10n.animatedDesktopCover, isOn: $music.settings.animatedDesktopCover)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .help(L10n.current == .ru ? "Анимированная обложка на рабочем столе" : "Animated desktop cover")
                    }
                    
                    // Выбор стиля пульсации обложки
                    if music.settings.animatedDesktopCover {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(L10n.coverAnimationTitle)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                                    .layoutPriority(1)
                                Spacer()
                                Text(music.settings.coverAnimation.localizedName)
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                            }
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                                ForEach(CoverAnimation.allCases) { anim in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.18)) {
                                            music.settings.coverAnimation = anim
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: anim.symbol)
                                                .font(.system(size: 9.5))
                                                .foregroundStyle(music.settings.coverAnimation == anim ? Theme.accent : Theme.textSecondary)
                                            Text(anim.localizedName)
                                                .font(.system(size: 9, weight: music.settings.coverAnimation == anim ? .bold : .regular))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)
                                                .foregroundStyle(music.settings.coverAnimation == anim ? Theme.textPrimary : Theme.textTertiary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 7)
                                        .background(
                                            music.settings.coverAnimation == anim ? Theme.accent.opacity(0.14) : Color.white.opacity(0.04),
                                            in: RoundedRectangle(cornerRadius: 6)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(music.settings.coverAnimation == anim ? Theme.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 0.8)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .help(anim.localizedDescription)
                                }
                            }
                            
                            Text(music.settings.coverAnimation.localizedDescription)
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.textTertiary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 1)
                        }
                        .padding(.vertical, 2)
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
            .padding(16)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.cardBorder))
            
            Text(L10n.quoteText)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
                .lineSpacing(4)
                .padding(.horizontal, 6)
        }
    }

    private func modeIcon(_ mode: NotchGlowMode) -> String {
        switch mode {
        case .ambientHalo: return "sparkles"
        case .audioWings: return "waveform"
        case .dynamicIsland: return "capsule.portrait"
        }
    }

    private func modeShortName(_ mode: NotchGlowMode) -> String {
        switch mode {
        case .ambientHalo: return L10n.current == .ru ? "Ореол" : "Halo"
        case .audioWings: return L10n.current == .ru ? "Крылья" : "Wings"
        case .dynamicIsland: return L10n.current == .ru ? "Остров HUD" : "Island HUD"
        }
    }

    private func modeDescription(_ mode: NotchGlowMode) -> String {
        switch mode {
        case .ambientHalo:
            return L10n.current == .ru ? "Неоновый контур вокруг выреза, пульсирующий в такт музыке" : "Neon contour hugging the notch, pulsing to music"
        case .audioWings:
            return L10n.current == .ru ? "10-полосный спектральный эквалайзер по бокам от челки" : "10-band spectral equalizer beside the notch"
        case .dynamicIsland:
            return L10n.current == .ru ? "Интерактивная капсула мини-плеера с быстрым управлением" : "Interactive mini-player HUD with quick controls"
        }
    }

    private func timestamp(_ seconds: Double) -> String {
        let s = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    @ViewBuilder
    private func edgeGlowCircle(_ index: Int) -> some View {
        switch index {
        case 1:
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.22, blue: 0.35),
                            Color(red: 1.0, green: 0.58, blue: 0.10),
                            Color(red: 1.0, green: 0.88, blue: 0.15),
                            Color(red: 0.15, green: 0.90, blue: 0.45),
                            Color(red: 0.0, green: 0.85, blue: 1.0),
                            Color(red: 0.35, green: 0.40, blue: 1.0),
                            Color(red: 0.85, green: 0.20, blue: 0.95),
                            Color(red: 1.0, green: 0.22, blue: 0.35)
                        ]),
                        center: .center
                    )
                )
        case 2:
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.92, blue: 0.82),
                            Color(red: 0.10, green: 0.95, blue: 0.45),
                            Color(red: 0.15, green: 0.65, blue: 1.0),
                            Color(red: 0.55, green: 0.20, blue: 0.98),
                            Color(red: 0.0, green: 0.92, blue: 0.82)
                        ]),
                        center: .center
                    )
                )
        case 3:
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.15, blue: 0.60),
                            Color(red: 1.0, green: 0.45, blue: 0.15),
                            Color(red: 0.95, green: 0.18, blue: 0.85),
                            Color(red: 0.55, green: 0.12, blue: 0.90),
                            Color(red: 1.0, green: 0.15, blue: 0.60)
                        ]),
                        center: .center
                    )
                )
        case 4:
            Circle().fill(Color(red: 1.0, green: 0.65, blue: 0.20))
        case 5:
            Circle().fill(Color(red: 0.0, green: 0.95, blue: 1.0))
        case 6:
            Circle().fill(Color(red: 0.85, green: 0.27, blue: 0.94))
        case 7:
            Circle().fill(Color(red: 0.12, green: 0.92, blue: 0.60))
        case 8:
            Circle().fill(Color.white)
        default:
            Circle().fill(music.artworkColor ?? Theme.accent)
        }
    }
}
