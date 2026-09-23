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
                .blur(radius: music.settings.blurRadius)
                .scaleEffect(1.15 + (isReactive ? beatImpact * 0.02 : 0.0))
                .clipped()
            
            // 2. Палитра наложения
            paletteOverlay(geo: geo)
            
            // 3. Радиальное рассеянное свечение с деликатной пульсацией в такт битам
            if music.settings.effect != .minimal {
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
        let coverScale = music.settings.computeCoverScale(
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
                .blur(radius: music.settings.blurRadius)
                .scaleEffect(1.08)
                .clipped()
            
            // 2. Палитра наложения с деликатным затемнением для читаемости
            paletteOverlay(geo: geo)
                .opacity(0.35)
            
            // 3. Атмосферный визуальный эффект из «Выберите настроение» на весь экран
            if music.settings.effect != .minimal {
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
                            .shadow(color: .black.opacity(0.55), radius: 10, y: 4)
                            .scaleEffect(coverScale)
                        
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
                neonPulseView(t: t, size: size * 0.45, beatImpact: beatImpact)
            case .orbit:
                orbitView(t: t, size: size * 0.55)
            case .waves:
                wavesView(t: t, size: size * 0.65)
            case .prism:
                prismView(t: t, size: size * 0.5)
            case .aurora:
                auroraView(t: t, size: size * 0.75)
            case .cosmicBreath:
                cosmicBreathView(t: t, size: size * 0.55)
            case .aura:
                auraGlowView(t: t, size: size * 0.55, beatImpact: beatImpact)
            case .nebula:
                nebulaView(t: t, size: size * 0.55, beatImpact: beatImpact)
            case .cyberGrid:
                cyberGridView(t: t, size: size * 0.65, beatImpact: beatImpact)
            case .supernova:
                supernovaView(t: t, size: size * 0.55, beatImpact: beatImpact)
            case .vinyl, .minimal:
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
        let coverScale = music.settings.computeCoverScale(
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
                .blur(radius: max(32, music.settings.blurRadius))
                .opacity(0.70)
                .clipped()
            
            // 2. Палитра наложения
            paletteOverlay(geo: geo)
                .opacity(0.45)
            
            // 3. Деликатный мягкий фоновый свет строго за обложкой
            RadialGradient(
                colors: [activeGlowColor.opacity(dynamicGlow * 0.45), .clear],
                center: .center,
                startRadius: 15,
                endRadius: artSize * 1.4
            )
            .scaleEffect(pulseScale)
            .blendMode(.screen)
            
            // 4. Парящая чистая обложка по центру (без визуализаторов и шума)
            VStack(spacing: 14) {
                if music.settings.effect == .vinyl {
                    vinylView(t: t, size: artSize, beatImpact: beatImpact, beatPhase: beatPhase)
                } else {
                    AlbumImage(image: music.artwork ?? music.fallback)
                        .frame(width: artSize, height: artSize)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.55), radius: 32, y: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.20), lineWidth: 1.2)
                        )
                        .scaleEffect(coverScale)
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
                    neonPulseView(t: t, size: artSize, beatImpact: beatImpact)
                case .orbit:
                    orbitView(t: t, size: artSize)
                case .waves:
                    wavesView(t: t, size: artSize)
                case .prism:
                    prismView(t: t, size: artSize)
                case .aurora:
                    auroraView(t: t, size: artSize)
                case .cosmicBreath:
                    cosmicBreathView(t: t, size: artSize)
                case .aura:
                    auraGlowView(t: t, size: artSize, beatImpact: beatImpact)
                case .nebula:
                    nebulaView(t: t, size: artSize, beatImpact: beatImpact)
                case .cyberGrid:
                    cyberGridView(t: t, size: artSize, beatImpact: beatImpact)
                case .supernova:
                    supernovaView(t: t, size: artSize, beatImpact: beatImpact)
                case .vinyl, .minimal:
                    EmptyView()
                }
                
                // Сама обложка или вращающийся виниловый диск
                if music.settings.effect == .vinyl {
                    vinylView(t: t, size: artSize, beatImpact: beatImpact, beatPhase: beatPhase)
                } else {
                    AlbumImage(image: music.artwork ?? music.fallback)
                        .frame(width: artSize, height: artSize)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.42), radius: 26, y: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.white.opacity(0.18), lineWidth: 1.2)
                        )
                        .scaleEffect(music.settings.computeCoverScale(
                            t: t,
                            beatImpact: beatImpact,
                            beatPhase: beatPhase,
                            isPlaying: music.playing
                        ))
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
        default: // Тёплая (динамическая из обложки)
            if let artColor = music.artworkColor {
                artColor.opacity(0.22).blendMode(.overlay)
            }
            Color.black.opacity(0.22)
        }
    }
    
    // MARK: - Эффекты оформления
    
    // Эффект: Волны (Waves)
    @ViewBuilder
    private func wavesView(t: Double, size: CGFloat) -> some View {
        let (c1, c2, c3) = artworkGlowColors
        let cols = [c1, c2, c3, c1, c2, c3]
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Ellipse()
                    .stroke(cols[i].opacity(music.settings.intensity * (0.30 - Double(i) * 0.03)), lineWidth: 1.3)
                    .frame(
                        width: size * (1.2 + Double(i) * 0.26),
                        height: size * (0.8 + Double(i) * 0.20)
                    )
                    .offset(y: sin(t * 2.0 + Double(i) * 0.6) * 10)
            }
        }
    }

    
    // Эффект: Орбита (Orbit)
    @ViewBuilder
    private func orbitView(t: Double, size: CGFloat) -> some View {
        let (c1, c2, c3) = artworkGlowColors
        let orbitColors = [c1, c2, c3]
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(orbitColors[i].opacity(0.32 * music.settings.intensity), lineWidth: 1.2)
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(orbitColors[i].opacity(0.9))
                            .frame(width: 7, height: 7)
                            .shadow(color: orbitColors[i], radius: 5)
                    }
                    .frame(width: size * (1.45 + Double(i) * 0.35), height: size * (1.45 + Double(i) * 0.35))
                    .rotation3DEffect(.degrees(60), axis: (x: 1, y: 0, z: 0))
                    .rotationEffect(.degrees(t * 24 + Double(i) * 55))
            }
        }
    }

    
    // Эффект: Северное сияние (Aurora Borealis)
    @ViewBuilder
    private func auroraView(t: Double, size: CGFloat) -> some View {
        let (c1, c2, c3) = artworkGlowColors
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                LinearGradient(
                    colors: [
                        c1.opacity(0.38 * music.settings.intensity),
                        c2.opacity(0.28 * music.settings.intensity),
                        c3.opacity(0.20 * music.settings.intensity),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: size * 2.4, height: size * 1.5)
                .offset(x: sin(t * 0.8 + Double(i) * 1.5) * 35, y: cos(t * 0.6 + Double(i)) * 18)
                .rotationEffect(.degrees(Double(i) * 8 - 4 + sin(t * 0.5) * 5))
                .blur(radius: 32)
                .blendMode(.screen)
            }
        }
    }

    
    // Эффект: Виниловая пластинка (Vinyl Record)
    @ViewBuilder
    private func vinylView(t: Double, size: CGFloat, beatImpact: Double, beatPhase: Double) -> some View {
        let vinylSize = size * 1.18
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
                        startRadius: 15,
                        endRadius: vinylSize * 0.5
                    )
                )
                .frame(width: vinylSize, height: vinylSize)
                .shadow(color: .black.opacity(0.55), radius: 24, y: 12)
            
            // Звуковые бороздки
            ForEach(1..<8, id: \.self) { ring in
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    .frame(width: vinylSize * (0.35 + Double(ring) * 0.08))
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
            AlbumImage(image: music.artwork ?? music.fallback)
                .frame(width: vinylSize * 0.38, height: vinylSize * 0.38)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5))
            
            // Центральное отверстие
            Circle()
                .fill(Color.black)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
        }
        .rotationEffect(.degrees(reduceMotion ? 0 : t * 36))
        .scaleEffect(music.settings.computeCoverScale(
            t: t,
            beatImpact: beatImpact,
            beatPhase: beatPhase,
            isPlaying: music.playing
        ))
    }
    
    // Эффект: Неоновый пульс (Cyber Neon Pulse)
    @ViewBuilder
    private func neonPulseView(t: Double, size: CGFloat, beatImpact: Double = 0.0) -> some View {
        let (c1, c2, _) = artworkGlowColors
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                let phase = Double(i) * 0.25
                let progress = (t * (0.6 + music.settings.speed * 0.8) + phase).truncatingRemainder(dividingBy: 1.0)
                let p = progress < 0 ? progress + 1.0 : progress
                let scale = 1.0 + p * 0.70 * music.settings.glowScale + (beatImpact * 0.12)
                let alpha = max(0, 1.0 - p) * music.settings.intensity * (0.75 + beatImpact * 0.25)
                
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                c1.opacity(alpha),
                                c2.opacity(alpha)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.2 + (beatImpact * 1.0)
                    )
                    .frame(width: size * scale, height: size * scale)
                    .shadow(color: c1.opacity(alpha * 0.8), radius: 14 + (beatImpact * 8))
            }
        }
    }

    
    // Эффект: Призма (Chromatic Dispersion Prism)
    @ViewBuilder
    private func prismView(t: Double, size: CGFloat) -> some View {
        let (c1, c2, c3) = artworkGlowColors
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let angle = t * 18.0 + Double(i) * 55.0
                AngularGradient(
                    colors: [
                        c1.opacity(0.32 * music.settings.intensity),
                        c2.opacity(0.32 * music.settings.intensity),
                        c3.opacity(0.22 * music.settings.intensity),
                        .clear
                    ],
                    center: .center,
                    startAngle: .degrees(angle),
                    endAngle: .degrees(angle + 180)
                )
                .frame(width: size * 2.2, height: size * 2.2)
                .blur(radius: 35)
                .blendMode(.screen)
            }
        }
    }

    
    // Эффект: Дыхание космоса (Cosmic Breath Nebula)
    @ViewBuilder
    private func cosmicBreathView(t: Double, size: CGFloat) -> some View {
        let (c1, c2, _) = artworkGlowColors
        ZStack {
            RadialGradient(
                colors: [
                    c1.opacity(0.40 * music.settings.intensity),
                    c2.opacity(0.30 * music.settings.intensity),
                    .clear
                ],
                center: .center,
                startRadius: 15,
                endRadius: size * 1.3
            )
            .frame(width: size * 2.2, height: size * 2.2)
            .scaleEffect(0.9 + abs(sin(t * 0.8)) * 0.25)
            .blur(radius: 28)
            .blendMode(.screen)
        }
    }

    
    // Эффект: Аура (Aura Radiant Glow)
    @ViewBuilder
    private func auraGlowView(t: Double, size: CGFloat, beatImpact: Double) -> some View {
        let (c1, c2, c3) = artworkGlowColors
        ZStack {
            // Первый слой — основной доминантный цвет
            RadialGradient(
                colors: [c1.opacity(0.55 * music.settings.intensity), c1.opacity(0.20), .clear],
                center: .center,
                startRadius: 20,
                endRadius: size * 1.2 * music.settings.glowScale
            )
            .frame(width: size * 2.2, height: size * 2.2)
            .scaleEffect(1.0 + (music.settings.audioReactive ? beatImpact * 0.15 : sin(t * 1.5) * 0.10))
            .blendMode(.screen)
            
            // Второй слой — акцентный цвет смещён и пульсирует
            RadialGradient(
                colors: [c2.opacity(0.40 * music.settings.intensity), .clear],
                center: .center,
                startRadius: 15,
                endRadius: size * 0.9 * music.settings.glowScale
            )
            .frame(width: size * 1.8, height: size * 1.8)
            .offset(x: sin(t * 0.7) * size * 0.12, y: cos(t * 0.5) * size * 0.10)
            .scaleEffect(1.0 + (music.settings.audioReactive ? beatImpact * 0.12 : sin(t * 2.1 + 1.0) * 0.08))
            .blendMode(.screen)
            
            // Третий слой — тихий оттенок для глубины
            RadialGradient(
                colors: [c3.opacity(0.28 * music.settings.intensity), .clear],
                center: .center,
                startRadius: 10,
                endRadius: size * 0.7 * music.settings.glowScale
            )
            .frame(width: size * 1.5, height: size * 1.5)
            .offset(x: cos(t * 0.9 + 0.8) * size * 0.08, y: sin(t * 0.65 + 0.5) * size * 0.09)
            .blendMode(.screen)
        }
    }
    
    // MARK: - Новые визуальные эффекты
    
    // Эффект: Жидкая туманность (Fluid Nebula)
    @ViewBuilder
    private func nebulaView(t: Double, size: CGFloat, beatImpact: Double) -> some View {
        let (c1, c2, c3) = artworkGlowColors
        let orbColors = [c1, c2, c3, c1]
        
        ZStack {
            // Центральное светящееся плазменное кольцо
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [c1, c2, c3, c1],
                        center: .center,
                        startAngle: .degrees(t * 40),
                        endAngle: .degrees(t * 40 + 360)
                    ),
                    lineWidth: max(4.0, 12.0 * CGFloat(beatImpact))
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 14)
                .scaleEffect(1.0 + CGFloat(beatImpact * 0.16))
                .blendMode(.screen)
            
            // 4 органические переливающиеся сферы туманности
            ForEach(0..<4, id: \.self) { i in
                let angle = t * (0.6 + Double(i) * 0.2) + Double(i) * (.pi / 2.0)
                let radius = size * (0.55 + Double(i) * 0.12)
                let x = cos(angle) * radius
                let y = sin(angle * 1.3) * (radius * 0.85)
                let orbSize = size * (0.75 + Double(i) * 0.15)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                orbColors[i].opacity(0.65 * music.settings.intensity),
                                orbColors[i].opacity(0.25 * music.settings.intensity),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: orbSize / 2.0
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                    .offset(x: x, y: y)
                    .blur(radius: 22)
                    .scaleEffect(1.0 + CGFloat(beatImpact * 0.22))
                    .blendMode(.screen)
            }
        }
    }
    
    // Эффект: Кибер-сетка (Cyber Grid)
    @ViewBuilder
    private func cyberGridView(t: Double, size: CGFloat, beatImpact: Double) -> some View {
        let (c1, c2, _) = artworkGlowColors
        let gridWidth = size * 2.2
        let gridHeight = size * 1.4
        
        ZStack {
            // Неоновая линия горизонта с сиянием
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, c1.opacity(0.85 * music.settings.intensity), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: gridWidth, height: 2.5 + CGFloat(beatImpact * 3.0))
                .offset(y: size * 0.38)
                .blur(radius: 2)
                .shadow(color: c1, radius: 8)
            
            // 3D-плоскость сетки горизонта
            ZStack {
                // Горизонтальные бегущие линии (перспектива)
                ForEach(0..<7, id: \.self) { i in
                    let step = (Double(i) / 7.0 + t * 0.4).truncatingRemainder(dividingBy: 1.0)
                    let yPos = pow(step, 2.0) * (gridHeight * 0.75)
                    let lineOpacity = (1.0 - step) * 0.45 * music.settings.intensity
                    
                    Rectangle()
                        .fill(c2.opacity(lineOpacity))
                        .frame(width: gridWidth * (0.3 + step * 0.7), height: 1.2)
                        .offset(y: yPos)
                }
                
                // Продольные лучи сетки, уходящие в глубину
                ForEach(-4...4, id: \.self) { i in
                    let xOffset = CGFloat(i) * (gridWidth * 0.10)
                    Path { path in
                        path.move(to: CGPoint(x: gridWidth / 2.0 + xOffset * 0.2, y: 0))
                        path.addLine(to: CGPoint(x: gridWidth / 2.0 + xOffset * 1.4, y: gridHeight * 0.75))
                    }
                    .stroke(c1.opacity(0.28 * music.settings.intensity), lineWidth: 1.0)
                    .frame(width: gridWidth, height: gridHeight * 0.75)
                }
            }
            .frame(width: gridWidth, height: gridHeight * 0.75)
            .offset(y: size * 0.40)
            .rotation3DEffect(.degrees(65), axis: (x: 1, y: 0, z: 0))
        }
    }
    
    // Эффект: Сверхновая (Supernova)
    @ViewBuilder
    private func supernovaView(t: Double, size: CGFloat, beatImpact: Double) -> some View {
        let (c1, c2, c3) = artworkGlowColors
        let burstScale = 1.0 + CGFloat(beatImpact * 0.55)
        
        ZStack {
            // Вспышка взрывной ударной волны при ударе бочки
            Circle()
                .stroke(
                    c1.opacity((0.25 + beatImpact * 0.65) * music.settings.intensity),
                    lineWidth: 1.5 + CGFloat(beatImpact * 2.5)
                )
                .frame(width: size * 1.55 * burstScale, height: size * 1.55 * burstScale)
                .blur(radius: 3)
                .shadow(color: c1.opacity(0.8), radius: 10)
            
            // Вторичное кольцо световых частиц
            Circle()
                .stroke(
                    c2.opacity(0.35 * music.settings.intensity),
                    style: StrokeStyle(lineWidth: 1.2, dash: [4, 8])
                )
                .frame(width: size * 1.85, height: size * 1.85)
                .rotationEffect(.degrees(t * 30))
            
            // Радиальные звездные лучи
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * 30.0 + t * 12.0
                let rayLen = size * (0.65 + Double(i % 3) * 0.18) * (1.0 + beatImpact * 0.35)
                let col = (i % 2 == 0) ? c1 : c3
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [col.opacity(0.7 * music.settings.intensity), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2.0, height: rayLen)
                    .offset(y: -(size * 0.65 + rayLen / 2.0))
                    .rotationEffect(.degrees(angle))
                    .blendMode(.screen)
            }
        }
    }
}


