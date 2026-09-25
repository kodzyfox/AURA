import SwiftUI

struct AtmosphereView: View {
    @EnvironmentObject var music: MusicController
    @ObservedObject private var analysis = AudioAnalysisService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        // TimelineView работает непрерывно в режиме предпросмотра (приостанавливается только при Reduce Motion в macOS)
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate * (0.25 + music.settings.speed * 0.6)
            let currentPos = music.currentPlaybackPosition(at: context.date)
            
            // Расчет аудио-реактивности в такт музыке (Spotify Audio Analysis / Smart Beat-Grid)
            let isReactive = music.settings.audioReactive && music.playing && !reduceMotion
            let beatImpact = isReactive ? AudioAnalysisService.shared.beatImpact(at: currentPos, sensitivity: music.settings.reactiveSensitivity) : 0.0
            let beatPhase = isReactive ? AudioAnalysisService.shared.beatPhase(at: currentPos) : 0.0
            let pulseScale = 1.0 + (isReactive ? beatImpact * 0.035 : 0.0)
            let dynamicGlow = music.settings.intensity * (1.0 + (isReactive ? beatImpact * 0.20 : 0.0))
            
            GeometryReader { geo in
                ZStack {
                    switch music.wallpaperStyle {
                    case .poster:
                        posterView(t: t, geo: geo, isReactive: isReactive, beatImpact: beatImpact, beatPhase: beatPhase, pulseScale: pulseScale, dynamicGlow: dynamicGlow, date: context.date)
                    case .fill:
                        fillView(t: t, geo: geo, isReactive: isReactive, beatImpact: beatImpact, beatPhase: beatPhase, dynamicGlow: dynamicGlow, date: context.date)
                    case .center:
                        centerMinimalView(t: t, geo: geo, isReactive: isReactive, beatImpact: beatImpact, beatPhase: beatPhase, dynamicGlow: dynamicGlow, pulseScale: pulseScale, date: context.date)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
        }
    }
    
    // MARK: - Режим 1: «Атмосферный постер»
    @ViewBuilder
    private func posterView(
        t: Double,
        geo: GeometryProxy,
        isReactive: Bool,
        beatImpact: Double,
        beatPhase: Double,
        pulseScale: Double,
        dynamicGlow: Double,
        date: Date
    ) -> some View {
        ZStack {
            // 1. Размытый фоновый артворк
            AlbumImage(image: music.artwork ?? music.fallback)
                .blur(radius: max(2.0, music.settings.blurRadius))
                .scaleEffect(1.15 + (isReactive ? beatImpact * 0.02 : 0.0))
                .clipped()
            
            // 2. Палитра наложения
            paletteOverlay(geo: geo)
            
            // 3. Радиальное рассеянное свечение с деликатной пульсацией в такт битам
            if music.settings.effect != .minimal && music.settings.palette != 8 {
                let glowRadius = geo.size.width * 0.55 * music.settings.glowScale * (1.0 + (isReactive ? beatImpact * 0.15 : 0.0))
                RadialGradient(
                    colors: [activeGlowColor.opacity(dynamicGlow * 0.65), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: max(50, glowRadius)
                )
                .scaleEffect(pulseScale)
                .blendMode(.screen)
            }
            
            // 4. Главная центрированная сцена: Обложка с выбранным эффектом строго вокруг нее
            centerContentScene(t: t, geo: geo, beatImpact: beatImpact, beatPhase: beatPhase)
            
            // 5. Наложение статуса и времени
            VStack {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.accent)
                        Text("Λ U R Λ")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(3.5)
                    }
                    
                    Spacer()
                    
                    if music.settings.showClock {
                        Text(date, style: .time)
                            .font(.system(size: 14, weight: .medium))
                            .monospacedDigit()
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if music.settings.audioReactive && music.playing {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Theme.green)
                                    .frame(width: 5, height: 5)
                                    .scaleEffect(1.0 + beatImpact * 0.4)
                                Text("\(Int(AudioAnalysisService.shared.currentBPM)) BPM")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Theme.green)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.green.opacity(0.15), in: Capsule())
                        }
                        
                        Text(music.settings.effect.localizedName.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                
                Spacer()
                
                HStack {
                    Text(music.playing ? (L10n.current == .ru ? "●  Погрузитесь в музыку" : "●  Immerse in the music") : (L10n.current == .ru ? "●  Время остановиться" : "●  Time to pause"))
                        .font(.system(size: 10, weight: .medium))
                    Spacer()
                }
            }
            .padding(20)
            .foregroundStyle(.white.opacity(0.75))
        }
    }
    
    // MARK: - Режим 2: «На весь экран» (Fill Screen)
    @ViewBuilder
    private func fillView(
        t: Double,
        geo: GeometryProxy,
        isReactive: Bool,
        beatImpact: Double,
        beatPhase: Double,
        dynamicGlow: Double,
        date: Date
    ) -> some View {
        let motion = music.settings.computeCoverMotion(
            t: t,
            beatImpact: beatImpact,
            beatPhase: beatPhase,
            isPlaying: music.playing
        )
        
        ZStack {
            // 1. Полноразмерный кинематографичный артворк на весь фон
            AlbumImage(image: music.artwork ?? music.fallback)
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .blur(radius: max(2.0, music.settings.blurRadius))
                .scaleEffect(1.08)
                .clipped()
            
            // 2. Палитра наложения с деликатным затемнением для читаемости
            paletteOverlay(geo: geo)
                .opacity(0.35)
            
            // 3. Атмосферный визуальный эффект из «Выберите настроение» на весь экран
            if music.settings.effect != .minimal && music.settings.palette != 8 {
                let glowRadius = geo.size.width * 0.55 * music.settings.glowScale * (1.0 + (isReactive ? beatImpact * 0.15 : 0.0))
                RadialGradient(
                    colors: [activeGlowColor.opacity(dynamicGlow * 0.60), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: max(50, glowRadius)
                )
                .blendMode(.screen)
                
                backgroundAtmosphereEffect(t: t, geo: geo, beatImpact: beatImpact)
                    .opacity(0.85)
            }
            
            // 4. Затемняющие градиенты сверху и снизу для идеальной читаемости
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.60), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 70)
                
                Spacer()
                
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.70)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
            
            // 5. Верхняя статусная панель и нижняя плашка с миниатюрой обложки (Скриншот 1)
            VStack {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.accent)
                        Text("Λ U R Λ")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(3.5)
                    }
                    
                    Spacer()
                    
                    if music.settings.showClock {
                        Text(date, style: .time)
                            .font(.system(size: 14, weight: .medium))
                            .monospacedDigit()
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if music.settings.audioReactive && music.playing {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Theme.green)
                                    .frame(width: 5, height: 5)
                                    .scaleEffect(1.0 + beatImpact * 0.4)
                                Text("\(Int(AudioAnalysisService.shared.currentBPM)) BPM")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Theme.green)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.green.opacity(0.15), in: Capsule())
                        }
                        
                        Text(music.settings.effect.localizedName.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                
                Spacer()
                
                // Нижняя панель: плавающая миниатюра обложки трека и эквалайзер (Скриншот 1)
                if music.settings.showInfo {
                    HStack(spacing: 12) {
                        // Квадратная плавающая мини-обложка в нижнем левом углу
                        AlbumImage(image: music.artwork ?? music.fallback)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(.white.opacity(0.20), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.55), radius: 10 + motion.shadowExtraRadius * 0.25, y: 4)
                            .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                            .offset(y: motion.offsetY * 0.4)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(music.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
                            
                            HStack(spacing: 8) {
                                Text(music.artist)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .lineLimit(1)
                                    .shadow(color: .black.opacity(0.6), radius: 4, y: 1)
                                
                                if isReactive {
                                    let mode = analysis.analysisMode
                                    HStack(spacing: 3) {
                                        Circle()
                                            .fill(mode.color)
                                            .frame(width: 4, height: 4)
                                        Text(mode.badgeTitle)
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.85))
                                    }
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.4), in: Capsule())
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Компактный спектральный эквалайзер
                        if music.settings.effect != .minimal {
                            let bars = AudioAnalysisService.shared.spectrumBars(at: music.currentPlaybackPosition(), count: 13)
                            HStack(alignment: .bottom, spacing: 2.5) {
                                ForEach(0..<13, id: \.self) { i in
                                    let barHeight: CGFloat = isReactive
                                        ? CGFloat(3.0 + bars[i] * 16.0 * (1.0 + beatImpact * 0.3))
                                        : CGFloat(3.0 + abs(sin(t * 3.0 + Double(i) * 0.4)) * 12.0)
                                    Capsule()
                                        .fill(Color.white.opacity(isReactive ? 0.85 : 0.6))
                                        .frame(width: 2.5, height: barHeight)
                                }
                            }
                            .frame(height: 22)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .padding(20)
            .foregroundStyle(.white.opacity(0.75))
        }
    }
    
    // Фоновая атмосфера для режима «На весь экран»
    @ViewBuilder
    private func backgroundAtmosphereEffect(t: Double, geo: GeometryProxy, beatImpact: Double) -> some View {
        let size = max(geo.size.width, geo.size.height) * 0.75
        ZStack {
            switch music.settings.effect {
            case .neonPulse:
                NeonPulseVisualizerView(t: t, size: size * 0.45, colors: artworkGlowColors, beatImpact: beatImpact, speed: music.settings.speed, glowScale: music.settings.glowScale, intensity: music.settings.intensity)
            case .orbit:
                OrbitVisualizerView(t: t, size: size * 0.55, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
            case .waves:
                WavesVisualizerView(t: t, size: size * 0.65, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
            case .prism:
                PrismVisualizerView(t: t, size: size * 0.55, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
            case .aurora:
                AuroraVisualizerView(t: t, size: size * 0.75, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
            case .cosmicBreath:
                CosmicBreathVisualizerView(t: t, size: size * 0.55, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
            case .aura:
                AuraVisualizerView(t: t, size: size * 0.55, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity, glowScale: music.settings.glowScale)
            case .nebula:
                FluidNebulaVisualizerView(t: t, size: size * 0.55, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
            case .cyberGrid:
                CyberGridVisualizerView(t: t, size: size * 0.65, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
            case .supernova:
                SupernovaVisualizerView(t: t, size: size * 0.55, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
            case .minimal:
                MinimalVisualizerView(size: size * 0.5)
            case .vinyl, .cd:
                EmptyView()
            }
        }
        .allowsHitTesting(false)
        .blur(radius: 12)
        .blendMode(.screen)
    }
    
    // MARK: - Режим 3: «Минимализм» (Minimalism)
    @ViewBuilder
    private func centerMinimalView(
        t: Double,
        geo: GeometryProxy,
        isReactive: Bool,
        beatImpact: Double,
        beatPhase: Double,
        dynamicGlow: Double,
        pulseScale: Double,
        date: Date
    ) -> some View {
        let baseArt = min(geo.size.height * 0.46, 220)
        let artSize = max(90, baseArt * music.settings.coverZoomLevel)
        let motion = music.settings.computeCoverMotion(
            t: t,
            beatImpact: beatImpact,
            beatPhase: beatPhase,
            isPlaying: music.playing
        )
        
        ZStack {
            // 1. Спокойный мягкий глубоко размытый фон
            AlbumImage(image: music.artwork ?? music.fallback)
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .blur(radius: max(2.0, music.settings.blurRadius))
                .opacity(0.70)
                .clipped()
            
            // 2. Палитра наложения
            paletteOverlay(geo: geo)
                .opacity(0.45)
            
            // 3. Деликатный мягкий фоновый свет строго за обложкой
            if music.settings.palette != 8 {
                RadialGradient(
                    colors: [activeGlowColor.opacity(dynamicGlow * 0.45), .clear],
                    center: .center,
                    startRadius: 15,
                    endRadius: artSize * 1.4
                )
                .scaleEffect(pulseScale)
                .blendMode(.screen)
            }
            
            // 4. Парящая чистая обложка по центру (без визуализаторов и шума)
            VStack(spacing: 14) {
                if music.settings.effect == .vinyl {
                    VinylVisualizerView(t: t, size: artSize, artwork: music.artwork ?? music.fallback, beatImpact: beatImpact, beatPhase: beatPhase, isPlaying: music.playing, reduceMotion: reduceMotion)
                        .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                        .offset(y: motion.offsetY)
                } else if music.settings.effect == .cd {
                    CDVisualizerView(t: t, size: artSize, artwork: music.artwork ?? music.fallback, beatImpact: beatImpact, isPlaying: music.playing, reduceMotion: reduceMotion)
                        .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                        .offset(y: motion.offsetY)
                } else {
                    AlbumImage(image: music.artwork ?? music.fallback)
                        .frame(width: artSize, height: artSize)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.55), radius: 32 + motion.shadowExtraRadius, y: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.20), lineWidth: 1.2)
                        )
                        .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                        .offset(y: motion.offsetY)
                }
                
                // Название трека и артист
                if music.settings.showInfo {
                    VStack(spacing: 4) {
                        Text(music.title)
                            .font(.system(size: geo.size.height > 500 ? 20 : 16, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.6), radius: 6, y: 2)
                        
                        Text(music.artist)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .opacity(0.80)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
                    }
                    .padding(.horizontal, 20)
                    .foregroundStyle(.white)
                }
            }
            .frame(width: geo.size.width)
            
            // 5. Верхняя и нижняя панель
            VStack {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.accent)
                        Text("Λ U R Λ")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(3.5)
                    }
                    
                    Spacer()
                    
                    if music.settings.showClock {
                        Text(date, style: .time)
                            .font(.system(size: 14, weight: .medium))
                            .monospacedDigit()
                    }
                    
                    Spacer()
                    
                    Text(L10n.current == .ru ? "МИНИМАЛИЗМ" : "MINIMALISM")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(.white.opacity(0.85))
                }
                
                Spacer()
                
                HStack {
                    Text(music.playing ? (L10n.current == .ru ? "●  Чистый фокус на звуке" : "●  Pure focus on music") : (L10n.current == .ru ? "●  Пауза" : "●  Paused"))
                        .font(.system(size: 10, weight: .medium))
                    Spacer()
                }
            }
            .padding(20)
            .foregroundStyle(.white.opacity(0.75))
        }
    }
    
    // MARK: - Центральная сцена с привязкой эффектов к обложке (для режима «Постер»)
    @ViewBuilder
    private func centerContentScene(t: Double, geo: GeometryProxy, beatImpact: Double, beatPhase: Double) -> some View {
        let baseArt = min(geo.size.height * 0.44, 280)
        let artSize = max(90, baseArt * music.settings.coverZoomLevel)
        
        VStack(spacing: 14) {
            ZStack {
                // Фоновые эффекты строго центрированы относительно обложки
                switch music.settings.effect {
                case .neonPulse:
                    NeonPulseVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, speed: music.settings.speed, glowScale: music.settings.glowScale, intensity: music.settings.intensity)
                case .orbit:
                    OrbitVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
                case .waves:
                    WavesVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
                case .prism:
                    PrismVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
                case .aurora:
                    AuroraVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
                case .cosmicBreath:
                    CosmicBreathVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
                case .aura:
                    AuraVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity, glowScale: music.settings.glowScale)
                case .nebula:
                    FluidNebulaVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
                case .cyberGrid:
                    CyberGridVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
                case .supernova:
                    SupernovaVisualizerView(t: t, size: artSize, colors: artworkGlowColors, beatImpact: beatImpact, intensity: music.settings.intensity)
                case .minimal:
                    MinimalVisualizerView(size: artSize)
                case .vinyl, .cd:
                    EmptyView()
                }
                
                // Сама обложка, вращающийся виниловый диск или компакт-диск
                let motion = music.settings.computeCoverMotion(
                    t: t,
                    beatImpact: beatImpact,
                    beatPhase: beatPhase,
                    isPlaying: music.playing
                )
                if music.settings.effect == .vinyl {
                    VinylVisualizerView(t: t, size: artSize, artwork: music.artwork ?? music.fallback, beatImpact: beatImpact, beatPhase: beatPhase, isPlaying: music.playing, reduceMotion: reduceMotion)
                        .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                        .offset(y: motion.offsetY)
                } else if music.settings.effect == .cd {
                    CDVisualizerView(t: t, size: artSize, artwork: music.artwork ?? music.fallback, beatImpact: beatImpact, isPlaying: music.playing, reduceMotion: reduceMotion)
                        .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                        .offset(y: motion.offsetY)
                } else {
                    AlbumImage(image: music.artwork ?? music.fallback)
                        .frame(width: artSize, height: artSize)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.42), radius: 26 + motion.shadowExtraRadius, y: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.white.opacity(0.18), lineWidth: 1.2)
                        )
                        .scaleEffect(x: motion.scaleX, y: motion.scaleY)
                        .offset(y: motion.offsetY)
                }
            }
            .frame(width: artSize, height: artSize)
            
            // Название трека и автор
            if music.settings.showInfo {
                VStack(spacing: 4) {
                    Text(music.title)
                        .font(.system(size: geo.size.height > 500 ? 22 : 17, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.5), radius: 8, y: 2)
                    
                    Text(music.artist)
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .opacity(0.85)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.4), radius: 5, y: 1)
                }
                .padding(.horizontal, 20)
                .foregroundStyle(.white)
            }
            
            // Спектральный визуализатор и статус источника аудио
            if music.settings.effect != .minimal {
                let bars = AudioAnalysisService.shared.spectrumBars(at: music.currentPlaybackPosition(), count: 21)
                HStack(alignment: .center, spacing: 3) {
                    ForEach(0..<21, id: \.self) { i in
                        let barHeight: CGFloat = music.settings.audioReactive && music.playing
                            ? CGFloat(4.0 + bars[i] * 18.0 * (1.0 + beatImpact * 0.35))
                            : CGFloat(4.0 + abs(sin(t * 3.5 + Double(i) * 0.3)) * 14.0)
                        Capsule()
                            .fill(Color.white.opacity(music.settings.audioReactive && music.playing ? 0.75 : 0.55))
                            .frame(width: 2.5, height: barHeight)
                    }
                }
                .frame(height: 24)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                
                if music.settings.audioReactive && music.playing {
                    let mode = analysis.analysisMode
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mode.color)
                            .frame(width: 4.5, height: 4.5)
                            .shadow(color: mode.color.opacity(0.8), radius: 3)
                        Text(mode.badgeTitle)
                            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.35))
                            .overlay(Capsule().stroke(mode.color.opacity(0.4), lineWidth: 0.8))
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
    }
    
    // Динамический цвет с учетом извлечения из обложки
    private var activeGlowColor: Color {
        switch music.settings.palette {
        case 1: // Aura Неон
            return Color(red: 0.0, green: 0.95, blue: 1.0)
        case 2: // Киберпанк
            return Color(red: 0.85, green: 0.27, blue: 0.94)
        case 3: // Северное сияние
            return Color(red: 0.10, green: 0.90, blue: 0.65)
        case 4: // Закат
            return Color(red: 1.0, green: 0.45, blue: 0.35)
        case 5: // Глубокий океан
            return Color(red: 0.15, green: 0.55, blue: 1.0)
        case 6: // Лаванда
            return Color(red: 0.75, green: 0.50, blue: 1.0)
        case 7: // Ночной космос
            return Color(red: 0.45, green: 0.60, blue: 0.90)
        case 8: // Без свечения
            return .clear
        default: // Обложка
            return music.artworkColor ?? Theme.accent
        }
    }
    
    /// Три цвета для многоцветного свечения, зависящего от выбранной палитры.
    /// При palette == 0 («Обложка») возвращает реальные доминантные цвета из artwork.
    private var artworkGlowColors: (Color, Color, Color) {
        switch music.settings.palette {
        case 1: // Aura Неон
            return (Color(red: 0.0, green: 0.95, blue: 1.0),
                    Color(red: 0.85, green: 0.27, blue: 0.94),
                    Color(red: 0.40, green: 0.60, blue: 1.0))
        case 2: // Киберпанк
            return (Color(red: 0.58, green: 0.20, blue: 1.0),
                    Color(red: 1.0,  green: 0.20, blue: 0.65),
                    Color(red: 0.85, green: 0.27, blue: 0.94))
        case 3: // Северное сияние
            return (Color(red: 0.10, green: 0.90, blue: 0.65),
                    Color(red: 0.0,  green: 0.85, blue: 1.0),
                    Color(red: 0.40, green: 0.95, blue: 0.55))
        case 4: // Закат
            return (Color(red: 1.0, green: 0.32, blue: 0.45),
                    Color(red: 1.0, green: 0.68, blue: 0.22),
                    Color(red: 1.0, green: 0.45, blue: 0.15))
        case 5: // Глубокий океан
            return (Color(red: 0.15, green: 0.45, blue: 1.0),
                    Color(red: 0.0,  green: 0.88, blue: 0.96),
                    Color(red: 0.25, green: 0.55, blue: 0.90))
        case 6: // Лаванда
            return (Color(red: 0.72, green: 0.45, blue: 1.0),
                    Color(red: 0.90, green: 0.65, blue: 0.98),
                    Color(red: 0.55, green: 0.35, blue: 0.85))
        case 7: // Ночной космос
            return (Color(red: 0.15, green: 0.22, blue: 0.40),
                    Color(red: 0.55, green: 0.68, blue: 0.95),
                    Color(red: 0.30, green: 0.45, blue: 0.75))
        default: // palette == 0: Обложка — реальные цвета из artwork
            let palette = music.artworkPalette
            let fallback = music.artworkColor ?? Theme.accent
            let c1 = palette.indices.contains(0) ? palette[0] : fallback
            let c2 = palette.indices.contains(1) ? palette[1] : fallback.opacity(0.8)
            let c3 = palette.indices.contains(2) ? palette[2] : fallback.opacity(0.6)
            return (c1, c2, c3)
        }
    }

    
    @ViewBuilder
    private func paletteOverlay(geo: GeometryProxy) -> some View {
        switch music.settings.palette {
        case 1: // Aura Неон (Циан + Маджента)
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.24),
                    Color(red: 0.85, green: 0.27, blue: 0.94).opacity(0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            Color.black.opacity(0.25)
        case 2: // Киберпанк
            Color(red: 0.70, green: 0.15, blue: 0.95).opacity(0.28).blendMode(.overlay)
            Color.black.opacity(0.25)
        case 3: // Северное сияние
            Color(red: 0.05, green: 0.85, blue: 0.60).opacity(0.25).blendMode(.overlay)
            Color.black.opacity(0.22)
        case 4: // Закат
            LinearGradient(
                colors: [Color.red.opacity(0.25), Color.orange.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            ).blendMode(.overlay)
            Color.black.opacity(0.22)
        case 5: // Глубокий океан
            Color(red: 0.05, green: 0.35, blue: 0.85).opacity(0.30).blendMode(.overlay)
            Color.black.opacity(0.25)
        case 6: // Лаванда
            Color.purple.opacity(0.28).blendMode(.overlay)
            Color.black.opacity(0.22)
        case 7: // Ночной космос
            Color.black.opacity(0.55)
            Color(red: 0.10, green: 0.15, blue: 0.35).opacity(0.25)
        case 8: // Без свечения — делаем задний фон на 25% темнее
            Color.black.opacity(0.25)
        default: // Тёплая (динамическая из обложки)
            if let artColor = music.artworkColor {
                artColor.opacity(0.22).blendMode(.overlay)
            }
            Color.black.opacity(0.22)
        }
    }
}


