import AppKit
import SwiftUI

// MARK: - Менеджер живого оверлея на рабочем столе macOS
// Создает прозрачные, не перехватывающие клики окна прямо над обоями рабочего стола,
// благодаря чему свечение реально пульсирует и переливается в реальном времени.
@MainActor final class DesktopOverlayManager {
    static let shared = DesktopOverlayManager()
    
    private var windows: [NSWindow] = []
    private weak var musicController: MusicController?
    /// Отложенная задача закрытия оверлея (даёт время обоям восстановиться)
    private var delayedCloseTask: Task<Void, Never>?
    
    private init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.reconfigureWindows()
            }
        }
    }
    
    func start(with music: MusicController) {
        self.musicController = music
        updateOverlayState()
    }
    
    func updateOverlayState() {
        guard let music = musicController else {
            cancelDelayedClose()
            closeAll()
            return
        }
        let needsOverlay = music.playing && music.activePlayerName != nil && (music.settings.edgeGlow || music.settings.animatedDesktopCover)
        if needsOverlay {
            // Воспроизведение возобновилось — отменяем отложенное закрытие
            cancelDelayedClose()
            if windows.isEmpty {
                reconfigureWindows()
            }
        } else {
            // При паузе или стопе: НЕ закрываем окна сразу.
            // Даём macOS время восстановить оригинальные обои (~0.8с),
            // пока SwiftUI анимация fade-out (0.4с) прикрывает переход.
            // Без этой задержки пользователь видит остаточное изображение —
            // размытый фон AURA без обложки, пока Finder не обновит обои.
            scheduleDelayedClose()
        }
    }
    
    /// Откладываем закрытие окон, чтобы оверлей прикрывал переход обоев
    private func scheduleDelayedClose() {
        // Если уже запланировано — не дублируем
        guard delayedCloseTask == nil else { return }
        delayedCloseTask = Task { @MainActor [weak self] in
            // 0.8с: 0.4с на SwiftUI fade-out + 0.4с запас на замену обоев macOS
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            self?.closeAll()
            self?.delayedCloseTask = nil
        }
    }
    
    private func cancelDelayedClose() {
        delayedCloseTask?.cancel()
        delayedCloseTask = nil
    }
    
    func reconfigureWindows() {
        cancelDelayedClose()
        closeAll()
        guard let music = musicController else { return }
        guard music.playing && music.activePlayerName != nil && (music.settings.edgeGlow || music.settings.animatedDesktopCover) else { return }
        
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            // Размещаем окно прямо над обоями, но строго под иконками Finder
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.isExcludedFromWindowsMenu = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            
            let hostingView = NSHostingView(rootView: DesktopAmbientOverlayView(music: music))
            hostingView.frame = CGRect(origin: .zero, size: screen.frame.size)
            hostingView.autoresizingMask = [.width, .height]
            window.contentView = hostingView
            
            window.orderFrontRegardless()
            windows.append(window)
        }
    }
    
    func closeAll() {
        cancelDelayedClose()
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }
}

// MARK: - SwiftUI View для живого свечения и парящей обложки на рабочем столе
struct DesktopAmbientOverlayView: View {
    @ObservedObject var music: MusicController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var currentGlowColors: (Color, Color, Color) {
        let c1 = music.settings.edgeGlowColor(artworkColor: music.artworkColor)
        let c2 = music.artworkPalette.indices.contains(1) ? music.artworkPalette[1] : Color(red: 0.85, green: 0.27, blue: 0.94)
        let c3 = music.artworkPalette.indices.contains(2) ? music.artworkPalette[2] : Color(red: 0.0, green: 0.95, blue: 1.0)
        return (c1, c2, c3)
    }
    
    var body: some View {
        let isPaused = reduceMotion || !music.playing || (!music.settings.edgeGlow && !music.settings.animatedDesktopCover)
        let performance = PerformanceManager.shared
        TimelineView(.animation(minimumInterval: performance.overlayFrameInterval, paused: isPaused)) { context in
            let t = isPaused ? 0 : context.date.timeIntervalSinceReferenceDate
            let currentPos = music.currentPlaybackPosition(at: context.date)
            
            ZStack {
                Color.clear.ignoresSafeArea()
                
                // 1. Пульсирующее Ambilight-свечение по краям экрана
                if music.settings.edgeGlow {
                    EdgeGlowView(
                        baseColor: music.settings.edgeGlowColor(artworkColor: music.artworkColor),
                        palette: music.artworkPalette,
                        opacity: music.settings.edgeGlowOpacity,
                        thickness: music.settings.edgeGlowThickness,
                        speed: music.settings.edgeGlowSpeed,
                        time: t,
                        trackPosition: currentPos,
                        isPlaying: music.playing,
                        audioReactive: music.settings.audioReactive,
                        sensitivity: music.settings.reactiveSensitivity,
                        colorIndex: music.settings.edgeGlowColorIndex,
                        reduceMotion: reduceMotion
                    )
                    .transition(.opacity)
                }
                
                // 2. Парящая обложка и атмосферные эффекты по центру рабочего стола
                if music.settings.animatedDesktopCover && music.playing && music.activePlayerName != nil {
                    GeometryReader { geo in
                        desktopFloatingScene(geo: geo, t: t, currentPos: currentPos)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: music.playing)
            .animation(.easeInOut(duration: 0.4), value: music.settings.edgeGlow)
            .animation(.easeInOut(duration: 0.4), value: music.settings.animatedDesktopCover)
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func desktopFloatingScene(geo: GeometryProxy, t: Double, currentPos: Double) -> some View {
        let beatImpact = music.settings.audioReactive ? AudioAnalysisService.shared.beatImpact(at: currentPos, sensitivity: music.settings.reactiveSensitivity) : 0.0
        let beatPhase = music.settings.audioReactive ? AudioAnalysisService.shared.beatPhase(at: currentPos) : 0.0
        let baseDim = min(geo.size.width * 0.32, geo.size.height * 0.40, 480)
        let coverDim = max(160, baseDim * music.settings.coverZoomLevel)
        
        ZStack {
            ZStack {
                visualizerBackground(coverDim: coverDim, t: t, beatImpact: beatImpact)
                coverArtView(coverDim: coverDim, t: t, beatImpact: beatImpact, beatPhase: beatPhase)
            }
            .frame(width: coverDim, height: coverDim)
            
            if music.settings.showInfo {
                let textGap: CGFloat = (music.settings.effect == .vinyl || music.settings.effect == .cd) ? 56 : 48
                VStack(spacing: 6) {
                    Text(music.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.85), radius: 10, y: 3)
                        .lineLimit(1)
                    
                    Text(music.artist)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.75), radius: 6, y: 2)
                        .lineLimit(1)
                }
                .offset(y: (coverDim / 2.0) + textGap)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private func visualizerBackground(coverDim: CGFloat, t: Double, beatImpact: Double) -> some View {
        let glowColors = currentGlowColors
        switch music.settings.effect {
        case .neonPulse:
            NeonPulseVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, speed: music.settings.speed, glowScale: music.settings.glowScale, intensity: music.settings.intensity)
        case .orbit:
            OrbitVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
        case .waves:
            WavesVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
        case .prism:
            PrismVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
        case .aurora:
            AuroraVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
        case .cosmicBreath:
            CosmicBreathVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
        case .aura:
            AuraVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity, glowScale: music.settings.glowScale)
        case .nebula:
            FluidNebulaVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
        case .cyberGrid:
            CyberGridVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
        case .supernova:
            SupernovaVisualizerView(t: t, size: coverDim, colors: glowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
        case .minimal:
            MinimalVisualizerView(size: coverDim)
        case .vinyl, .cd:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func coverArtView(coverDim: CGFloat, t: Double, beatImpact: Double, beatPhase: Double) -> some View {
        let motion = music.settings.computeCoverMotion(
            t: t,
            beatImpact: beatImpact,
            beatPhase: beatPhase,
            isPlaying: music.playing
        )
        if music.settings.effect == .vinyl {
            VinylVisualizerView(
                t: t,
                size: coverDim,
                artwork: music.artwork ?? music.fallback,
                beatImpact: beatImpact,
                beatPhase: beatPhase,
                isPlaying: music.playing,
                reduceMotion: reduceMotion
            )
            .scaleEffect(x: motion.scaleX, y: motion.scaleY)
            .offset(y: motion.offsetY)
        } else if music.settings.effect == .cd {
            CDVisualizerView(
                t: t,
                size: coverDim,
                artwork: music.artwork ?? music.fallback,
                beatImpact: beatImpact,
                isPlaying: music.playing,
                reduceMotion: reduceMotion
            )
            .scaleEffect(x: motion.scaleX, y: motion.scaleY)
            .offset(y: motion.offsetY)
        } else {
            if let art = music.artwork ?? music.fallback {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: coverDim, height: coverDim)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.20), lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.65), radius: 36 + motion.shadowExtraRadius, y: 16)
                    .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                    .offset(y: motion.offsetY)
            }
        }
    }
}
