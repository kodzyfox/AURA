import SwiftUI
import AppKit
import Combine

struct CoverView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @EnvironmentObject var music: MusicController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?
    @State private var currentTime = Date()
    
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TimelineView(.animation(minimumInterval: PerformanceManager.shared.overlayFrameInterval, paused: reduceMotion || !music.playing)) { context in
            let t = reduceMotion || !music.playing ? 0 : context.date.timeIntervalSinceReferenceDate
            let currentPos = music.currentPlaybackPosition(at: context.date)
            
            GeometryReader { geo in
                ZStack {
                    // 1. Полноэкранный кинематографичный фон на основе обложки
                    Color.black.ignoresSafeArea()
                    
                    if let artwork = music.artwork ?? music.fallback {
                        Image(nsImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .blur(radius: 65)
                            .opacity(0.42)
                            .scaleEffect(1.2)
                            .ignoresSafeArea()
                    }
                    
                    // Динамический свет в тон обложки
                    if let tint = music.artworkColor {
                        RadialGradient(
                            colors: [tint.opacity(0.35 * music.settings.intensity), .clear],
                            center: .center,
                            startRadius: 100,
                            endRadius: max(geo.size.width, geo.size.height) * 0.7
                        )
                        .blendMode(.screen)
                        .ignoresSafeArea()
                    }
                    
                    // Затемняющие градиенты сверху и снизу для идеальной читаемости
                    VStack {
                        LinearGradient(
                            colors: [Color.black.opacity(0.4), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        
                        Spacer()
                        
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 180)
                    }
                    .ignoresSafeArea()
                    
                    // 2. Идеальная вертикальная компоновка (Часы -> Обложка -> Название/Артист -> Плеер внизу)
                    VStack(spacing: 0) {
                        // Верхняя панель: Системные часы и дата
                        VStack(spacing: 3) {
                            Text(currentTime, format: .dateTime.hour().minute())
                                .font(.system(size: geo.size.height > 800 ? 44 : 36, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                            
                            Text(formattedDate)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 1)
                        }
                        .padding(.top, geo.size.height > 800 ? 36 : 24)
                        
                        Spacer(minLength: 12)
                        
                        // Чёткая сбалансированная центральная обложка с мягкой парящей анимацией
                        let availableHeight = geo.size.height - 360
                        let baseDimension = min(geo.size.width * 0.45, availableHeight, 420)
                        let coverDimension = max(180, baseDimension * music.settings.coverZoomLevel)
                        
                        let motion = music.settings.computeCoverMotion(
                            t: t,
                            beatImpact: AudioAnalysisService.shared.beatImpact(at: currentPos),
                            beatPhase: AudioAnalysisService.shared.beatPhase(at: currentPos),
                            isPlaying: music.playing
                        )
                        AlbumImage(image: music.artwork ?? music.fallback)
                            .frame(width: coverDimension, height: coverDimension)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.65), radius: 45 + motion.shadowExtraRadius, y: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(.white.opacity(0.18), lineWidth: 1.2)
                            )
                            .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                            .offset(y: motion.offsetY)
                        
                        // Название трека и артист по центру (в точности как на скриншоте)
                        VStack(spacing: 4) {
                            Text(music.title)
                                .font(.system(size: geo.size.height > 800 ? 24 : 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.55), radius: 6, y: 2)
                                .lineLimit(1)
                            
                            Text(music.artist)
                                .font(.system(size: geo.size.height > 800 ? 15 : 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.75))
                                .shadow(color: .black.opacity(0.40), radius: 4, y: 1)
                                .lineLimit(1)
                        }
                        .padding(.top, 16)
                        
                        Spacer(minLength: 14)
                        
                        // Компактный парящий стеклянный плеер (iOS 17)
                        floatingGlassPlayer(t: t)
                            .padding(.bottom, geo.size.height > 800 ? 30 : 18)
                    }
                    
                    // 3. Пульсирующее и переливающееся свечение по периметру экрана
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
                    }
                    
                    // Верхние элементы интерфейса: индикатор режима справа и кнопка закрытия
                    VStack {
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Theme.accent)
                                Text("Λ U R Λ  •  \(music.settings.effect.localizedName.uppercased())")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .tracking(2.2)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08), in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.3), lineWidth: 0.8))
                            .padding(.top, 32)
                            .padding(.trailing, 12)
                            
                            Button {
                                music.toggleCoverMode()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white.opacity(0.70))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 30)
                            .padding(.trailing, 28)
                            .opacity(showControls ? 1 : 0)
                            .help(L10n.current == .ru ? "Выйти из заставки (Escape)" : "Exit Screensaver (Escape)")
                        }
                        Spacer()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .onContinuousHover { phase in
                    switch phase {
                    case .active:
                        userActivityDetected()
                    case .ended:
                        break
                    }
                }
            }
        }
        .onReceive(clockTimer) { newDate in
            currentTime = newDate
        }
        .onAppear {
            userActivityDetected()
            // Гарантируем системный полноэкранный режим
            DispatchQueue.main.async {
                if let window = NSApp.keyWindow, !window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
        }
        .onDisappear {
            hideTask?.cancel()
        }
        .onExitCommand {
            music.toggleCoverMode()
        }
    }
    
    // MARK: - Компактный парящий стеклянный плеер в точности как на iOS 17 Lock Screen (Скриншот 3)
    private func floatingGlassPlayer(t: Double) -> some View {
        VStack(spacing: 12) {
            // 1. Название трека и артист по центру
            VStack(spacing: 3) {
                Text(music.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(music.artist)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            
            // 2. Таймлайн с прогрессом и временем слева/справа
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { min(music.position, max(1, music.duration)) },
                        set: { music.seek($0) }
                    ),
                    in: 0...max(1, music.duration)
                )
                .controlSize(.mini)
                .tint(.white.opacity(0.95))
                
                HStack {
                    Text(timestamp(music.position))
                        .font(.system(size: 11, weight: .regular).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.60))
                    
                    Spacer()
                    
                    Text(timestamp(music.duration > 0 ? music.duration : 0))
                        .font(.system(size: 11, weight: .regular).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.60))
                }
            }
            .padding(.horizontal, 4)
            
            // 3. Ряд контролов: << | Большая круглая кнопка Play/Pause | >>
            HStack(spacing: 0) {
                // Избранное (слева)
                Button {
                    music.isLiked.toggle()
                } label: {
                    Image(systemName: music.isLiked ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundStyle(music.isLiked ? Color.yellow : .white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .frame(width: 32)
                
                Spacer()
                
                // Назад <<
                Button {
                    music.skip(-1)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.92))
                
                Spacer()
                
                // Play / Pause (Крупная круглая кнопка с акцентным цветом альбома как на скриншоте 3)
                Button {
                    music.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(music.artworkColor ?? Color(red: 0.44, green: 0.54, blue: 0.46))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: music.playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.12))
                            .offset(x: music.playing ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Вперед >>
                Button {
                    music.skip(1)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.92))
                
                Spacer()
                
                // Аудиовыход (справа)
                Button {
                    // Индикатор
                } label: {
                    Image(systemName: "airplayaudio")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .frame(width: 32)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: 420)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.40), radius: 24, y: 12)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.language == .ru ? "ru_RU" : "en_US")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: currentTime).capitalized
    }
    
    private func userActivityDetected() {
        showControls = true
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showControls = false
                }
                NSCursor.setHiddenUntilMouseMoves(true)
            }
        }
    }
    
    private func timestamp(_ seconds: Double) -> String {
        let s = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
