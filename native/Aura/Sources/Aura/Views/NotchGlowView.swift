import SwiftUI
import AppKit

// MARK: - Прецизионная форма кромки выреза MacBook (с учетом верхних ушек и скругления)
struct PhysicalNotchContour: Shape {
    var centerX: CGFloat? = nil
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat
    var earRadius: CGFloat = 6.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = centerX ?? rect.midX
        let left = midX - width / 2.0
        let right = midX + width / 2.0
        let bottom = height
        let r = cornerRadius
        let ear = earRadius
        
        if ear > 0.5 {
            // 1. Верхний край экрана слева от ушка челки
            path.move(to: CGPoint(x: left - ear, y: 0))
            
            // 2. Верхнее левое ушко (плавный переход от менюбара в вертикаль челки)
            path.addCurve(
                to: CGPoint(x: left, y: ear),
                control1: CGPoint(x: left - ear * 0.45, y: 0),
                control2: CGPoint(x: left, y: ear * 0.45)
            )
        } else {
            path.move(to: CGPoint(x: left, y: 0))
        }
        
        // 3. Левая вертикальная грань челки
        path.addLine(to: CGPoint(x: left, y: bottom - r))
        
        // 4. Нижний левый скругленный угол
        path.addCurve(
            to: CGPoint(x: left + r, y: bottom),
            control1: CGPoint(x: left, y: bottom - r * 0.45),
            control2: CGPoint(x: left + r * 0.45, y: bottom)
        )
        
        // 5. Нижняя горизонтальная кромка челки (плотно прилегает к физической челке)
        path.addLine(to: CGPoint(x: right - r, y: bottom))
        
        // 6. Нижний правый скругленный угол
        path.addCurve(
            to: CGPoint(x: right, y: bottom - r),
            control1: CGPoint(x: right - r * 0.45, y: bottom),
            control2: CGPoint(x: right, y: bottom - r * 0.45)
        )
        
        // 7. Правая вертикальная грань челки
        if ear > 0.5 {
            path.addLine(to: CGPoint(x: right, y: ear))
            
            // 8. Верхнее правое ушко (плавный переход из вертикали челки вправо в менюбар)
            path.addCurve(
                to: CGPoint(x: right + ear, y: 0),
                control1: CGPoint(x: right, y: ear * 0.45),
                control2: CGPoint(x: right + ear * 0.45, y: 0)
            )
        } else {
            path.addLine(to: CGPoint(x: right, y: 0))
        }
        
        return path
    }
}

// MARK: - Главное представление Notch Glow и Dynamic Island HUD
struct NotchGlowView: View {
    @ObservedObject var music: MusicController
    let notch: NotchInfo
    var isHovered: Bool
    var isTemporarilyExpanded: Bool
    var onHoverChanged: ((Bool) -> Void)?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var isExpanded: Bool {
        isHovered || isTemporarilyExpanded
    }
    
    var body: some View {
        let performance = PerformanceManager.shared
        let isPaused = reduceMotion || !music.playing
        
        TimelineView(.animation(minimumInterval: performance.overlayFrameInterval, paused: isPaused)) { context in
            let currentPos = music.currentPlaybackPosition(at: context.date)
            let isAudioActive = music.playing && !reduceMotion && music.settings.audioReactive
            let beatImpact = isAudioActive ? AudioAnalysisService.shared.beatImpact(at: currentPos, sensitivity: music.settings.reactiveSensitivity) : 0.0
            let t = isPaused ? 0.0 : context.date.timeIntervalSinceReferenceDate * (0.4 + music.settings.speed * 0.6)
            
            let glowColor = music.settings.edgeGlowColor(artworkColor: music.artworkColor)
            
            ZStack(alignment: .top) {
                // 1. Неоновый ореол свечения (Halo)
                ambientHaloLayer(glowColor: glowColor, beatImpact: beatImpact, t: t)
                    .allowsHitTesting(false)
                
                // 2. Аудио-крылья эквалайзера по бокам от челки (если выбран соответствующий режим)
                if (music.settings.notchGlowMode == .audioWings || music.settings.notchGlowMode == .dynamicIsland) && !isExpanded {
                    audioWingsLayer(glowColor: glowColor, beatImpact: beatImpact, currentPos: currentPos, t: t)
                        .allowsHitTesting(false)
                }
                
                // 3. Вырез / Капсула Dynamic Island / Интерактивный HUD
                dynamicIslandHUD(glowColor: glowColor, beatImpact: beatImpact, currentPos: currentPos, t: t)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
    
    // MARK: - 1. Слой неонового ореола вокруг выреза
    @ViewBuilder
    private func ambientHaloLayer(glowColor: Color, beatImpact: Double, t: Double) -> some View {
        let baseRadius = CGFloat(music.settings.notchGlowRadius)
        let dynamicRadius = baseRadius * (1.0 + CGFloat(beatImpact * 0.35))
        let dynamicIntensity = (0.60 + beatImpact * 0.40) * music.settings.intensity
        let earR: CGFloat = notch.hasPhysicalNotch ? 6.0 : 0.0
        
        ZStack(alignment: .top) {
            // Мягкий внешний размытый ореол света, струящийся из-под челки вниз
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(0.45 * dynamicIntensity),
                            glowColor.opacity(0.16 * dynamicIntensity),
                            glowColor.opacity(0.0)
                        ],
                        center: .top,
                        startRadius: 4,
                        endRadius: notch.height + dynamicRadius * 1.6
                    )
                )
                .frame(
                    width: (notch.width + dynamicRadius * 2.2),
                    height: (notch.height + dynamicRadius * 1.6) * 2.0
                )
                .position(x: notch.centerX, y: 0)
                .blur(radius: max(8, dynamicRadius * 0.55))
                .blendMode(.screen)
            
            // Четкий контурный градиент прямо по кромке выреза (0pt сдвига!)
            if !isExpanded {
                let contour = PhysicalNotchContour(
                    centerX: notch.centerX,
                    width: notch.width,
                    height: notch.height,
                    cornerRadius: notch.cornerRadius,
                    earRadius: earR
                )
                
                // 1. Широкий атмосферный ореол
                contour
                    .stroke(
                        glowColor.opacity(0.35 * dynamicIntensity),
                        style: StrokeStyle(lineWidth: 12.0 + CGFloat(beatImpact * 6.0), lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 12.0)
                
                // 2. Средняя аура свечения
                contour
                    .stroke(
                        glowColor.opacity(0.65 * dynamicIntensity),
                        style: StrokeStyle(lineWidth: 6.0 + CGFloat(beatImpact * 3.0), lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 4.5)
                
                // 3. Яркая неоновая трубка точно по кромке
                contour
                    .stroke(
                        LinearGradient(
                            colors: [
                                glowColor.opacity(0.3),
                                glowColor.opacity(0.95),
                                glowColor.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.2 + CGFloat(beatImpact * 1.2), lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 0.8)
                    .shadow(color: glowColor.opacity(0.85 * dynamicIntensity), radius: 4, y: 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isExpanded)
    }
    
    // MARK: - 2. Аудио-крылья эквалайзера слева и справа от выреза
    @ViewBuilder
    private func audioWingsLayer(glowColor: Color, beatImpact: Double, currentPos: Double, t: Double) -> some View {
        let bars = AudioAnalysisService.shared.spectrumBars(at: currentPos, count: 12)
        let earR: CGFloat = notch.hasPhysicalNotch ? 6.0 : 0.0
        let wingGap: CGFloat = 14.0
        let leftWingCenter = notch.centerX - (notch.width / 2.0) - earR - wingGap - 10.0
        let rightWingCenter = notch.centerX + (notch.width / 2.0) + earR + wingGap + 10.0
        let centerY = notch.height / 2.0 // Точно по центру высоты менюбара (16.0 pt)
        
        ZStack {
            // Левое крыло
            HStack(alignment: .center, spacing: 3.5) {
                ForEach((0..<5).reversed(), id: \.self) { i in
                    let val = i < bars.count ? CGFloat(bars[i]) : 0.2
                    let barH = max(4.0, val * 18.0 * (1.0 + CGFloat(beatImpact * 0.45)))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [glowColor.opacity(0.95), glowColor.opacity(0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2.5, height: barH)
                        .shadow(color: glowColor.opacity(0.6), radius: 3)
                }
            }
            .position(x: leftWingCenter, y: centerY)
            
            // Правое крыло
            HStack(alignment: .center, spacing: 3.5) {
                ForEach(6..<11, id: \.self) { i in
                    let val = i < bars.count ? CGFloat(bars[i]) : 0.2
                    let barH = max(4.0, val * 18.0 * (1.0 + CGFloat(beatImpact * 0.45)))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [glowColor.opacity(0.95), glowColor.opacity(0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2.5, height: barH)
                        .shadow(color: glowColor.opacity(0.6), radius: 3)
                }
            }
            .position(x: rightWingCenter, y: centerY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .transition(.opacity)
    }
    
    // MARK: - 3. Интерактивная капсула Dynamic Island
    @ViewBuilder
    private func dynamicIslandHUD(glowColor: Color, beatImpact: Double, currentPos: Double, t: Double) -> some View {
        let containerWidth: CGFloat = isExpanded ? max(420.0, notch.width + 40.0) : (notch.width + 36.0)
        let containerHeight: CGFloat = isExpanded ? (notch.height + 76.0) : (notch.height + 12.0)
        let leadingOffset = max(0, notch.centerX - (containerWidth / 2.0))
        
        HStack(spacing: 0) {
            Color.clear
                .frame(width: leadingOffset, height: 1)
                .allowsHitTesting(false)
            
            ZStack(alignment: .top) {
                if isExpanded {
                    VStack(spacing: 4) {
                        // Чувствительная зона самой челки вверху
                        Color.clear
                            .frame(height: notch.height)
                        
                        // Раскрытый плеер
                        expandedHUDCard(glowColor: glowColor, currentPos: currentPos)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.90, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.90, anchor: .top).combined(with: .opacity)
                    ))
                } else if music.settings.notchGlowMode == .dynamicIsland {
                    collapsedNotchCapsule(glowColor: glowColor, beatImpact: beatImpact)
                        .frame(width: notch.width + 36.0, height: notch.height + 12.0, alignment: .top)
                        .transition(.opacity)
                } else {
                    // Режимы Ореол и Крылья в свернутом состоянии
                    if !notch.hasPhysicalNotch {
                        standardVirtualPill(glowColor: glowColor, beatImpact: beatImpact)
                            .allowsHitTesting(false)
                    }
                    Color.clear
                        .frame(width: notch.width + 36.0, height: notch.height + 12.0, alignment: .top)
                        .contentShape(Rectangle())
                }
            }
            .frame(width: containerWidth, height: containerHeight, alignment: .top)
            .contentShape(Rectangle())
            .onHover { hovering in
                onHoverChanged?(hovering)
            }
            
            Spacer(minLength: 0)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    // Свернутая капсула выреза
    @ViewBuilder
    private func collapsedNotchCapsule(glowColor: Color, beatImpact: Double) -> some View {
        if !notch.hasPhysicalNotch {
            // Для внешних мониторов без физического пластика рисуем изящную черную капсулу
            HStack(spacing: 8) {
                // Мини-обложка или точка источника
                if let art = music.artwork ?? music.fallback {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(glowColor)
                        .frame(width: 7, height: 7)
                }
                
                // Волновой индикатор воспроизведения
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(glowColor)
                            .frame(width: 2, height: music.playing ? CGFloat(6 + (i == 1 ? beatImpact * 8 : beatImpact * 4)) : 4)
                    }
                }
            }
            .padding(.horizontal, 10)
            .frame(height: notch.height)
            .background(Color.black.opacity(0.92), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
        } else {
            // Для встроенной челки MacBook: чувствительный триггер на всю ширину челки
            Color.clear
                .frame(width: notch.width + 24, height: notch.height + 6)
                .contentShape(Rectangle())
        }
    }
    
    // Раскрытая карточка мини-плеера Dynamic Island
    @ViewBuilder
    private func expandedHUDCard(glowColor: Color, currentPos: Double) -> some View {
        HStack(spacing: 12) {
            // Обложка трека
            if let art = music.artwork ?? music.fallback {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 5)
            }
            
            // Название трека, автор и полоса прогресса
            VStack(alignment: .leading, spacing: 3) {
                Text(music.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(music.artist)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                
                // Прогресс-бар
                GeometryReader { barGeo in
                    let progress = music.duration > 0 ? min(1.0, max(0.0, currentPos / music.duration)) : 0.0
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 3)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [glowColor, glowColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(3, barGeo.size.width * CGFloat(progress)), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.top, 2)
            }
            .frame(width: 170)
            
            // Кнопки управления треком
            HStack(spacing: 8) {
                Button(action: { music.skip(-1) }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                
                Button(action: { music.toggle() }) {
                    Image(systemName: music.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                
                Button(action: { music.skip(1) }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                
                Button(action: { music.toggleLike() }) {
                    Image(systemName: music.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 12))
                        .foregroundStyle(music.isLiked ? Color.red : Color.white.opacity(0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.06, green: 0.07, blue: 0.10).opacity(0.96))
                .shadow(color: .black.opacity(0.55), radius: 16, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(glowColor.opacity(0.35), lineWidth: 1.0)
                )
        )
    }
    
    // Стандартный виртуальный островок для мониторов без челки
    @ViewBuilder
    private func standardVirtualPill(glowColor: Color, beatImpact: Double) -> some View {
        Capsule()
            .fill(Color.black.opacity(0.92))
            .frame(width: notch.width, height: notch.height)
            .overlay(
                Capsule().strokeBorder(glowColor.opacity(0.4 + beatImpact * 0.4), lineWidth: 1)
            )
            .position(x: notch.centerX, y: notch.height / 2.0)
    }
}
