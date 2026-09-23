import AppKit
import SwiftUI

// MARK: - Менеджер живого оверлея на рабочем столе macOS
// Создает прозрачные, не перехватывающие клики окна прямо над обоями рабочего стола,
// благодаря чему свечение реально пульсирует и переливается в реальном времени.
@MainActor final class DesktopOverlayManager {
    static let shared = DesktopOverlayManager()
    
    private var windows: [NSWindow] = []
    private weak var musicController: MusicController?
    
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
            closeAll()
            return
        }
        let needsOverlay = music.playing && music.activePlayerName != nil && (music.settings.edgeGlow || music.settings.animatedDesktopCover)
        if needsOverlay {
            if windows.isEmpty {
                reconfigureWindows()
            }
        } else {
            // При паузе или стопе немедленно убираем окна оверлея,
            // чтобы обложка мгновенно исчезала с рабочего стола
            closeAll()
        }
    }
    
    func reconfigureWindows() {
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
    
    var body: some View {
        let isPaused = reduceMotion || !music.playing || (!music.settings.edgeGlow && !music.settings.animatedDesktopCover)
        let performance = PerformanceManager.shared
        TimelineView(.animation(minimumInterval: performance.overlayFrameInterval, paused: isPaused)) { context in
            let t = isPaused ? 0 : context.date.timeIntervalSinceReferenceDate
            let currentPos = music.currentPlaybackPosition(at: context.date)
            
            ZStack {
                Color.clear.ignoresSafeArea()
                
                // 1. Живое пульсирующее и переливающееся свечение по периметру экрана (Ambilight)
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
                
                // 2. Режим анимированной парящей обложки и эффектов по центру рабочего стола
                if music.settings.animatedDesktopCover && music.playing && music.activePlayerName != nil {
                    GeometryReader { geo in
                        let beatImpact = music.settings.audioReactive ? AudioAnalysisService.shared.beatImpact(at: currentPos, sensitivity: music.settings.reactiveSensitivity) : 0.0
                        let beatPhase = music.settings.audioReactive ? AudioAnalysisService.shared.beatPhase(at: currentPos) : 0.0
                        let baseDim = min(geo.size.width * 0.32, geo.size.height * 0.40, 480)
                        let coverDim = max(160, baseDim * music.settings.coverZoomLevel)
                        
                        ZStack {
                            // 1. Центральная сцена с обложкой (строго по центру экрана)
                            ZStack {
                                // Фоновые эффекты за обложкой
                                switch music.settings.effect {
                                case .neonPulse:
                                    ForEach(0..<4, id: \.self) { i in
                                        let phase = Double(i) * 0.25
                                        let progress = (t * (0.6 + music.settings.speed * 0.8) + phase).truncatingRemainder(dividingBy: 1.0)
                                        let scale = 1.0 + progress * 0.75 * music.settings.glowScale + (beatImpact * 0.12)
                                        let alpha = max(0, 1.0 - progress) * music.settings.intensity * (0.75 + beatImpact * 0.25)
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.0, green: 0.95, blue: 1.0).opacity(alpha),
                                                        Color(red: 0.85, green: 0.27, blue: 0.94).opacity(alpha)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2.2 + (beatImpact * 1.0)
                                            )
                                            .frame(width: coverDim * scale, height: coverDim * scale)
                                            .shadow(color: Color(red: 0.0, green: 0.95, blue: 1.0).opacity(alpha * 0.8), radius: 14 + (beatImpact * 8))
                                    }
                                    
                                case .orbit:
                                    ForEach(0..<3, id: \.self) { i in
                                        Circle()
                                            .stroke(Color.white.opacity(0.24 * music.settings.intensity), lineWidth: 1.2)
                                            .overlay(alignment: .top) {
                                                Circle()
                                                    .fill(Color.white.opacity(0.9))
                                                    .frame(width: 8, height: 8)
                                                    .shadow(color: .white, radius: 5)
                                            }
                                            .frame(width: coverDim * (1.5 + Double(i) * 0.35), height: coverDim * (1.5 + Double(i) * 0.35))
                                            .rotation3DEffect(.degrees(60), axis: (x: 1, y: 0, z: 0))
                                            .rotationEffect(.degrees(t * 22 + Double(i) * 55))
                                    }
                                    
                                case .waves:
                                    ForEach(0..<6, id: \.self) { i in
                                        Ellipse()
                                            .stroke(Color.white.opacity(music.settings.intensity * (0.24 - Double(i) * 0.03)), lineWidth: 1.4)
                                            .frame(
                                                width: coverDim * (1.2 + Double(i) * 0.28),
                                                height: coverDim * (0.8 + Double(i) * 0.22)
                                            )
                                            .offset(y: sin(t * 2.0 + Double(i) * 0.6) * 12)
                                    }
                                    
                                case .prism where performance.shouldUseExpensiveEffects:
                                    ForEach(0..<3, id: \.self) { i in
                                        let angle = t * 18.0 + Double(i) * 55.0
                                        AngularGradient(
                                            colors: [
                                                Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.32 * music.settings.intensity),
                                                Color(red: 0.85, green: 0.27, blue: 0.94).opacity(0.32 * music.settings.intensity),
                                                Color(red: 1.0, green: 0.75, blue: 0.20).opacity(0.22 * music.settings.intensity),
                                                .clear
                                            ],
                                            center: .center,
                                            startAngle: .degrees(angle),
                                            endAngle: .degrees(angle + 180)
                                        )
                                        .frame(width: coverDim * 2.0, height: coverDim * 2.0)
                                        .blur(radius: 40)
                                        .blendMode(.screen)
                                    }
                                    
                                case .aurora where performance.shouldUseExpensiveEffects:
                                    ForEach(0..<3, id: \.self) { i in
                                        LinearGradient(
                                            colors: [
                                                Color.mint.opacity(0.35 * music.settings.intensity),
                                                Color.purple.opacity(0.25 * music.settings.intensity),
                                                Color.blue.opacity(0.18 * music.settings.intensity),
                                                .clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(width: coverDim * 2.5, height: coverDim * 1.5)
                                        .offset(x: sin(t * 0.8 + Double(i) * 1.5) * 40, y: cos(t * 0.6 + Double(i)) * 20)
                                        .rotationEffect(.degrees(Double(i) * 8 - 4 + sin(t * 0.5) * 5))
                                        .blur(radius: 35)
                                        .blendMode(.screen)
                                    }
                                    
                                case .cosmicBreath where performance.shouldUseExpensiveEffects:
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.10, green: 0.85, blue: 1.0).opacity(0.40 * music.settings.intensity),
                                            Color(red: 0.50, green: 0.15, blue: 0.90).opacity(0.30 * music.settings.intensity),
                                            .clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: coverDim * 1.3
                                    )
                                    .frame(width: coverDim * 2.2, height: coverDim * 2.2)
                                     .scaleEffect(0.9 + abs(sin(t * 0.8)) * 0.25)

                                case .prism, .aurora, .cosmicBreath:
                                    EmptyView()
                                     
                                case .aura:
                                    let glowCol = music.settings.edgeGlowColor(artworkColor: music.artworkColor)
                                    RadialGradient(
                                        colors: [glowCol.opacity(0.55 * music.settings.intensity), glowCol.opacity(0.18), .clear],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: coverDim * 1.15 * music.settings.glowScale
                                    )
                                    .frame(width: coverDim * 2.2, height: coverDim * 2.2)
                                    .scaleEffect(1.0 + (music.settings.audioReactive ? beatImpact * 0.15 : 0.0))
                                    .blendMode(.screen)
                                    
                                case .nebula:
                                    let glowCol = music.settings.edgeGlowColor(artworkColor: music.artworkColor)
                                    Circle()
                                        .stroke(glowCol.opacity(0.6 * music.settings.intensity), lineWidth: max(4.0, 10.0 * CGFloat(beatImpact)))
                                        .frame(width: coverDim * 1.3, height: coverDim * 1.3)
                                        .blur(radius: 16)
                                        .scaleEffect(1.0 + CGFloat(beatImpact * 0.15))
                                        .blendMode(.screen)
                                        
                                case .cyberGrid:
                                    let glowCol = music.settings.edgeGlowColor(artworkColor: music.artworkColor)
                                    Rectangle()
                                        .fill(LinearGradient(colors: [.clear, glowCol.opacity(0.7 * music.settings.intensity), .clear], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: coverDim * 1.8, height: 3.0 + CGFloat(beatImpact * 4.0))
                                        .offset(y: coverDim * 0.45)
                                        .blur(radius: 3)
                                        
                                case .supernova:
                                    let glowCol = music.settings.edgeGlowColor(artworkColor: music.artworkColor)
                                    Circle()
                                        .stroke(glowCol.opacity((0.3 + beatImpact * 0.6) * music.settings.intensity), lineWidth: 2.0 + CGFloat(beatImpact * 3.0))
                                        .frame(width: coverDim * (1.3 + CGFloat(beatImpact * 0.4)), height: coverDim * (1.3 + CGFloat(beatImpact * 0.4)))
                                        .blur(radius: 4)
                                        
                                case .vinyl, .minimal:
                                    EmptyView()
                                }
                                
                                // Центральный элемент: Виниловая пластинка или Обложка
                                if music.settings.effect == .vinyl {
                                    // Виниловая пластинка с вращением
                                    let vinylSize = coverDim * 1.18
                                    ZStack {
                                        // Черный виниловый диск
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        Color(white: 0.12),
                                                        Color(white: 0.05),
                                                        Color(white: 0.15),
                                                        Color(white: 0.04)
                                                    ],
                                                    center: .center,
                                                    startRadius: 20,
                                                    endRadius: vinylSize * 0.5
                                                )
                                            )
                                            .frame(width: vinylSize, height: vinylSize)
                                            .shadow(color: .black.opacity(0.55), radius: 32, y: 16)
                                        
                                        // Звуковые бороздки
                                        ForEach(1..<9, id: \.self) { ring in
                                            Circle()
                                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                                .frame(width: vinylSize * (0.35 + Double(ring) * 0.075))
                                        }
                                        
                                        // Блик света на виниле
                                        Circle()
                                            .stroke(
                                                AngularGradient(
                                                    colors: [.clear, .white.opacity(0.14), .clear, .white.opacity(0.14), .clear],
                                                    center: .center
                                                ),
                                                lineWidth: vinylSize * 0.35
                                            )
                                            .frame(width: vinylSize * 0.65, height: vinylSize * 0.65)
                                        
                                        // Центральное «яблоко» пластинки с обложкой
                                        if let art = music.artwork ?? music.fallback {
                                            Image(nsImage: art)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: vinylSize * 0.38, height: vinylSize * 0.38)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 2))
                                        }
                                        
                                        // Центральное отверстие
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 16, height: 16)
                                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                                    }
                                    .rotationEffect(.degrees(reduceMotion ? 0 : t * 36))
                                    .scaleEffect(music.settings.computeCoverScale(
                                        t: t,
                                        beatImpact: beatImpact,
                                        beatPhase: beatPhase,
                                        isPlaying: music.playing
                                    ))
                                } else {
                                    // Стандартная парящая обложка
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
                                            .shadow(color: .black.opacity(0.65), radius: 36, y: 16)
                                            .scaleEffect(music.settings.computeCoverScale(
                                                t: t,
                                                beatImpact: beatImpact,
                                                beatPhase: beatPhase,
                                                isPlaying: music.playing
                                            ))
                                    }
                                }
                            }
                            .frame(width: coverDim, height: coverDim)
                            
                            // 2. Название трека и артист под обложкой с просторным отступом
                            if music.settings.showInfo {
                                let textGap: CGFloat = music.settings.effect == .vinyl ? 56 : 48
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
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: music.playing)
            .animation(.easeInOut(duration: 0.4), value: music.settings.edgeGlow)
            .animation(.easeInOut(duration: 0.4), value: music.settings.animatedDesktopCover)
        }
        .allowsHitTesting(false)
    }
}
