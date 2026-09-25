import SwiftUI

// MARK: - Универсальный генератор и библиотека визуализаторов AURA
// Каждый эффект имеет собственную уникальную геометрию, анимацию и концепцию.

// MARK: - 1. Винил (Vinyl Record)
struct VinylVisualizerView: View {
    let t: Double
    let size: CGFloat
    let artwork: NSImage?
    let beatImpact: Double
    var beatPhase: Double = 0.0
    let isPlaying: Bool
    let reduceMotion: Bool

    init(t: Double, size: CGFloat, artwork: NSImage?, beatImpact: Double, beatPhase: Double = 0.0, isPlaying: Bool, reduceMotion: Bool) {
        self.t = t
        self.size = size
        self.artwork = artwork
        self.beatImpact = beatImpact
        self.beatPhase = beatPhase
        self.isPlaying = isPlaying
        self.reduceMotion = reduceMotion
    }
    
    var body: some View {
        let vinylSize = size * 1.20
        ZStack {
            // Тень пластинки
            Circle()
                .fill(Color.black.opacity(0.65))
                .frame(width: vinylSize, height: vinylSize)
                .blur(radius: 24)
                .offset(y: 12)
            
            // Основной виниловый диск с микроканавками
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.14),
                            Color(white: 0.05),
                            Color(white: 0.16),
                            Color(white: 0.04),
                            Color(white: 0.12)
                        ],
                        center: .center,
                        startRadius: 18,
                        endRadius: vinylSize * 0.5
                    )
                )
                .frame(width: vinylSize, height: vinylSize)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
            
            // 8 звуковых дорожек-бороздок
            ForEach(1..<9, id: \.self) { ring in
                Circle()
                    .stroke(Color.white.opacity(0.055), lineWidth: 0.9)
                    .frame(width: vinylSize * (0.36 + Double(ring) * 0.075))
            }
            
            // Реалистичный двойной угловой световой блик на виниле
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.16),
                            .clear,
                            Color.white.opacity(0.04),
                            .clear,
                            Color.white.opacity(0.16),
                            .clear
                        ],
                        center: .center
                    ),
                    lineWidth: vinylSize * 0.36
                )
                .frame(width: vinylSize * 0.64, height: vinylSize * 0.64)
            
            // Центральное бумажное яблоко с артворком
            ZStack {
                if let art = artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: vinylSize * 0.38, height: vinylSize * 0.38)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.accentGradient)
                        .frame(width: vinylSize * 0.38, height: vinylSize * 0.38)
                }
                
                Circle()
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.8)
                    .frame(width: vinylSize * 0.38, height: vinylSize * 0.38)
                
                // Внутреннее отверстие шпинделя
                Circle()
                    .fill(Color.black)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
            }
        }
        .rotationEffect(.degrees(reduceMotion ? 0 : t * (isPlaying ? 38 : 0)))
        .scaleEffect(1.0 + (isPlaying ? beatImpact * 0.025 : 0.0))
    }
}

// MARK: - 2. Компакт-диск (Holographic Compact Disc)
struct CDVisualizerView: View {
    let t: Double
    let size: CGFloat
    let artwork: NSImage?
    let beatImpact: Double
    var beatPhase: Double = 0.0
    let isPlaying: Bool
    let reduceMotion: Bool

    init(t: Double, size: CGFloat, artwork: NSImage?, beatImpact: Double, beatPhase: Double = 0.0, isPlaying: Bool, reduceMotion: Bool) {
        self.t = t
        self.size = size
        self.artwork = artwork
        self.beatImpact = beatImpact
        self.beatPhase = beatPhase
        self.isPlaying = isPlaying
        self.reduceMotion = reduceMotion
    }
    
    var body: some View {
        let cdSize = size * 1.18
        ZStack {
            // Тень диска
            Circle()
                .fill(Color.black.opacity(0.55))
                .frame(width: cdSize, height: cdSize)
                .blur(radius: 20)
                .offset(y: 10)
            
            // Металлическая серебристая зеркальная основа CD
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.88),
                            Color(white: 0.72),
                            Color(white: 0.85),
                            Color(white: 0.68)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: cdSize * 0.5
                    )
                )
                .frame(width: cdSize, height: cdSize)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 1.2))
            
            // Микро-треки данных
            ForEach(1..<7, id: \.self) { ring in
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.7)
                    .frame(width: cdSize * (0.42 + Double(ring) * 0.09))
            }
            
            // Вращающийся голографический радужный перелив дифракции
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .clear,
                            Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.45),
                            Color(red: 0.85, green: 0.20, blue: 0.95).opacity(0.45),
                            Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.45),
                            Color(red: 0.10, green: 0.90, blue: 0.50).opacity(0.40),
                            .clear,
                            Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.45),
                            Color(red: 0.85, green: 0.20, blue: 0.95).opacity(0.45),
                            Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.45),
                            .clear
                        ],
                        center: .center
                    ),
                    lineWidth: cdSize * 0.32
                )
                .frame(width: cdSize * 0.68, height: cdSize * 0.68)
                .blendMode(.colorDodge)
                .rotationEffect(.degrees(reduceMotion ? 0 : -t * 22))
            
            // Прозрачное акриловое центральное кольцо
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: cdSize * 0.34, height: cdSize * 0.34)
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
            
            // Центральная круглая наклейка-яблоко
            ZStack {
                if let art = artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cdSize * 0.26, height: cdSize * 0.26)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.accentGradient)
                        .frame(width: cdSize * 0.26, height: cdSize * 0.26)
                }
                
                Circle()
                    .strokeBorder(Color.white.opacity(0.45), lineWidth: 1.5)
                    .frame(width: cdSize * 0.26, height: cdSize * 0.26)
                
                // Центральное отверстие
                Circle()
                    .fill(Color.black)
                    .frame(width: cdSize * 0.10, height: cdSize * 0.10)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 1))
            }
        }
        .rotationEffect(.degrees(reduceMotion ? 0 : t * (isPlaying ? 45 : 0)))
        .scaleEffect(1.0 + (isPlaying ? beatImpact * 0.03 : 0.0))
    }
}

// MARK: - 3. Неоновый пульс (Cyberpunk HUD Pulse)
struct NeonPulseVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let speed: Double
    let glowScale: Double
    let intensity: Double
    
    var body: some View {
        let (c1, c2, _) = colors
        let effIntensity = max(0.42, intensity)
        let baseAlpha = effIntensity * (0.85 + beatImpact * 0.35)
        
        ZStack {
            // 1. Широкие расширяющиеся тактические неоновые импульсы (до 2.1x)
            ForEach(0..<4, id: \.self) { i in
                let phase = Double(i) * 0.25
                let progress = (t * (0.65 + speed * 0.55) + phase).truncatingRemainder(dividingBy: 1.0)
                let p = progress < 0 ? progress + 1.0 : progress
                let scale = 1.15 + p * 0.95 * glowScale + (beatImpact * 0.16)
                let alpha = max(0, 1.0 - p) * baseAlpha
                
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [c1.opacity(alpha * 0.9), c2.opacity(alpha * 0.6), c1.opacity(alpha * 0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5 + CGFloat(beatImpact * 1.8)
                    )
                    .frame(width: size * scale, height: size * scale)
                    .shadow(color: c1.opacity(alpha * 0.8), radius: 12 + CGFloat(beatImpact * 10))
            }
            
            // 2. Киберпанк-угловые скобки HUD (Targeting brackets, 1.48x)
            HUDCornerBracketsShape()
                .stroke(
                    LinearGradient(
                        colors: [c1, c2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.4 + CGFloat(beatImpact * 1.5)
                )
                .frame(width: size * 1.45 + CGFloat(beatImpact * 12), height: size * 1.45 + CGFloat(beatImpact * 12))
                .shadow(color: c1, radius: 10 + CGFloat(beatImpact * 8))
            
            // 3. Угловые видоискатели и перекрестия HUD
            ForEach(0..<4, id: \.self) { corner in
                let angle = Double(corner) * 90.0 + 45.0
                let rad = angle * .pi / 180.0
                let dist = size * 0.86
                Circle()
                    .stroke(c1.opacity(0.85 * effIntensity), lineWidth: 1.5)
                    .frame(width: 9, height: 9)
                    .overlay(
                        Circle().fill(c2.opacity(0.9 * effIntensity)).frame(width: 3.5, height: 3.5)
                    )
                    .offset(x: cos(rad) * dist, y: sin(rad) * dist)
            }
            
            // 4. Горизонтальная линия ECG / Пульсовая волна (как на иконке)
            HStack(spacing: 0) {
                // Левая пульсовая ветвь
                HUDECGLineShape(t: t * 3.5, beatImpact: beatImpact, isReversed: true)
                    .stroke(
                        LinearGradient(
                            colors: [.clear, c1.opacity(effIntensity * 0.85), c2.opacity(effIntensity * 0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.2
                    )
                    .frame(width: size * 0.72, height: 36)
                    .shadow(color: c1.opacity(effIntensity * 0.7), radius: 6)
                
                Spacer()
                    .frame(width: size * 1.05) // Пространство для центральной обложки
                
                // Правая пульсовая ветвь
                HUDECGLineShape(t: t * 3.5 + 1.2, beatImpact: beatImpact, isReversed: false)
                    .stroke(
                        LinearGradient(
                            colors: [c2.opacity(effIntensity * 0.95), c1.opacity(effIntensity * 0.85), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.2
                    )
                    .frame(width: size * 0.72, height: 36)
                    .shadow(color: c2.opacity(effIntensity * 0.7), radius: 6)
            }
            .frame(width: size * 2.5)
            
            // 5. Боковые вертикальные неоновые эквалайзеры HUD (по 12 сегментов)
            HStack {
                // Левый спектрограф
                VStack(spacing: 4.5) {
                    ForEach(0..<12, id: \.self) { i in
                        let active = (sin(t * 4.6 + Double(i) * 0.55) + 1.0) / 2.0 + beatImpact * 0.45
                        let isLit = active > 0.40
                        HStack(spacing: 3) {
                            Text(String(format: "%02d", 12 - i))
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(c1.opacity(isLit ? 0.7 : 0.2))
                            Capsule()
                                .fill(isLit ? c1 : c1.opacity(0.18))
                                .frame(width: isLit ? 16 + CGFloat(active * 14) : 8, height: 3)
                                .shadow(color: c1.opacity(isLit ? 0.85 : 0), radius: 5)
                        }
                    }
                }
                .offset(x: -size * 0.88)
                
                Spacer()
                
                // Правый спектрограф
                VStack(spacing: 4.5) {
                    ForEach(0..<12, id: \.self) { i in
                        let active = (cos(t * 4.2 + Double(i) * 0.52) + 1.0) / 2.0 + beatImpact * 0.45
                        let isLit = active > 0.40
                        HStack(spacing: 3) {
                            Capsule()
                                .fill(isLit ? c2 : c2.opacity(0.18))
                                .frame(width: isLit ? 16 + CGFloat(active * 14) : 8, height: 3)
                                .shadow(color: c2.opacity(isLit ? 0.85 : 0), radius: 5)
                            Text(String(format: "%02d", 12 - i))
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(c2.opacity(isLit ? 0.7 : 0.2))
                        }
                    }
                }
                .offset(x: size * 0.88)
            }
            .frame(width: size * 2.2)
        }
    }
}

// Форма волны кардиограммы / импульса (ECG Waveform)
struct HUDECGLineShape: Shape {
    let t: Double
    let beatImpact: Double
    let isReversed: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let w = rect.width
        let h = rect.height
        
        let startX = isReversed ? rect.minX : rect.minX
        let endX = isReversed ? rect.maxX : rect.maxX
        
        path.move(to: CGPoint(x: startX, y: midY))
        
        // Линия с характерными пиками кардиограммы
        let p1 = w * 0.25
        let p2 = w * 0.45
        let p3 = w * 0.55
        let p4 = w * 0.65
        let p5 = w * 0.82
        
        let pulseHeight = (h * 0.42) * CGFloat(1.0 + beatImpact * 0.8)
        let wave = sin(t) * 4.0
        
        path.addLine(to: CGPoint(x: p1, y: midY))
        path.addLine(to: CGPoint(x: p2, y: midY - CGFloat(wave)))
        // Небольшой предварительный зубец
        path.addLine(to: CGPoint(x: p2 + 6, y: midY + 5))
        // Острый R-пик кардиограммы
        path.addLine(to: CGPoint(x: p3, y: midY - pulseHeight))
        // S-пик вниз
        path.addLine(to: CGPoint(x: p4, y: midY + pulseHeight * 0.55))
        // Возврат к изолинии
        path.addLine(to: CGPoint(x: p5, y: midY))
        path.addLine(to: CGPoint(x: endX, y: midY))
        
        return path
    }
}

// Форма угловых скобок кибер-HUD
struct HUDCornerBracketsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arm: CGFloat = min(rect.width, rect.height) * 0.16
        
        // Верхний левый
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))
        
        // Верхний правый
        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))
        
        // Нижний правый
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))
        
        // Нижний левый
        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))
        
        return path
    }
}

// MARK: - 4. Кибер-сетка (Synthwave Perspective Grid)
struct CyberGridVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    
    var body: some View {
        let (c1, c2, _) = colors
        let effIntensity = max(0.42, intensity)
        let gridWidth = size * 3.2
        let gridHeight = size * 1.5
        let sunSize = size * 1.6
        
        ZStack {
            // 1. Верхнее неоновое звездное небо в ретро-стиле
            ForEach(0..<14, id: \.self) { i in
                let seed = Double(i) * 73.0
                let xPos = (sin(seed) * 0.5) * Double(size * 2.6)
                let yPos = -size * 0.85 - (cos(seed * 1.3) * 0.5 + 0.5) * Double(size * 0.5)
                let starTwinkle = abs(sin(t * 2.0 + Double(i)))
                
                Circle()
                    .fill(Color.white.opacity(0.35 + starTwinkle * 0.6))
                    .frame(width: i % 3 == 0 ? 3.5 : 2.0, height: i % 3 == 0 ? 3.5 : 2.0)
                    .shadow(color: c1.opacity(effIntensity), radius: 3)
                    .offset(x: CGFloat(xPos), y: CGFloat(yPos))
            }
            
            // 2. Огромное ретро-солнце Synthwave, возвышающееся над обложкой
            ZStack {
                // Внешнее свечение солнца (Corona)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.35, blue: 0.2).opacity(0.55 * effIntensity),
                                Color(red: 0.9, green: 0.05, blue: 0.6).opacity(0.25 * effIntensity),
                                .clear
                            ],
                            center: .center,
                            startRadius: sunSize * 0.2,
                            endRadius: sunSize * 0.75
                        )
                    )
                    .frame(width: sunSize * 1.45, height: sunSize * 1.45)
                    .blur(radius: 20)
                
                // Тело солнца с полосами-прорезями (Scanline slits)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.92, blue: 0.3), // Яркий солнечный верх
                                Color(red: 1.0, green: 0.45, blue: 0.1), // Оранжевый
                                Color(red: 0.95, green: 0.10, blue: 0.55) // Пурпурный низ
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: sunSize, height: sunSize)
                    .mask {
                        VStack(spacing: 3.2) {
                            ForEach(0..<14, id: \.self) { i in
                                Rectangle()
                                    // Верхние полосы сплошные, к низу прорези всё шире
                                    .frame(height: max(1.8, CGFloat(14 - i) * 2.2))
                            }
                        }
                    }
                    .shadow(color: Color(red: 1.0, green: 0.3, blue: 0.1).opacity(0.8 * effIntensity), radius: 24)
            }
            .scaleEffect(1.0 + CGFloat(beatImpact * 0.08))
            .offset(y: -size * 0.62)
            
            // 3. 3D-плоскость неоновой сетки, бегущей вперед
            ZStack {
                // Горизонтальные бегущие линии (перспективное сжатие)
                ForEach(0..<10, id: \.self) { i in
                    let step = (Double(i) / 10.0 + t * 0.5).truncatingRemainder(dividingBy: 1.0)
                    let p = step < 0 ? step + 1.0 : step
                    let yPos = pow(p, 2.4) * (gridHeight * 0.9)
                    let lineOpacity = (0.2 + p * 0.8) * effIntensity
                    let lineWidth = gridWidth * (0.3 + p * 0.7)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, c1.opacity(lineOpacity), c2.opacity(lineOpacity), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: lineWidth, height: 1.6 + CGFloat(p * 2.0))
                        .offset(y: yPos)
                        .shadow(color: c1.opacity(lineOpacity * 0.7), radius: 4)
                }
                
                // Продольные лучи сетки, уходящие в глубину к точке схода
                ForEach(-7...7, id: \.self) { i in
                    let norm = CGFloat(i) / 7.0
                    Path { path in
                        path.move(to: CGPoint(x: gridWidth / 2.0 + norm * (gridWidth * 0.08), y: 0))
                        path.addLine(to: CGPoint(x: gridWidth / 2.0 + norm * (gridWidth * 0.52), y: gridHeight * 0.9))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [c2.opacity(0.15 * effIntensity), c1.opacity(0.70 * effIntensity)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.4
                    )
                    .frame(width: gridWidth, height: gridHeight * 0.9)
                }
            }
            .frame(width: gridWidth, height: gridHeight * 0.9)
            .offset(y: size * 0.54)
            .rotation3DEffect(.degrees(66), axis: (x: 1, y: 0, z: 0))
            
            // 4. Ослепительная неоновая линия горизонта (Laser Horizon Line)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, c1.opacity(effIntensity), Color.white.opacity(effIntensity), c2.opacity(effIntensity), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: gridWidth * 1.1, height: 3.0 + CGFloat(beatImpact * 3.5))
                .offset(y: size * 0.52)
                .shadow(color: c1, radius: 12 + CGFloat(beatImpact * 8))
        }
    }
}

// MARK: - 5. Орбита (Celestial 3D Orbit)
struct OrbitVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    
    var body: some View {
        let (c1, c2, c3) = colors
        let effIntensity = max(0.42, intensity)
        let baseRadius = size * 1.05
        
        ZStack {
            // 1. Внешнее астролябическое координатное кольцо с делениями (2.3x)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [c1.opacity(0.35 * effIntensity), c2.opacity(0.15 * effIntensity), c3.opacity(0.35 * effIntensity)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 1.4, dash: [4, 8])
                )
                .frame(width: size * 2.35, height: size * 2.35)
                .rotationEffect(.degrees(t * 5.0))
            
            // 2. Наклонная 3D Орбита 1 (Главный эллипс, размах 2.5x)
            ZStack {
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [c1.opacity(0.85 * effIntensity), c2.opacity(0.35 * effIntensity), c1.opacity(0.70 * effIntensity)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.8 + CGFloat(beatImpact * 1.0)
                    )
                    .frame(width: baseRadius * 2.35, height: baseRadius * 1.25)
                    .shadow(color: c1.opacity(0.6 * effIntensity), radius: 8)
                
                // Главный спутник с хвостом частиц
                let angle1 = t * 1.7
                let radX = baseRadius * 1.175
                let radY = baseRadius * 0.625
                
                // Хвост спутника
                ForEach(1...4, id: \.self) { trail in
                    let lag = angle1 - Double(trail) * 0.08
                    Circle()
                        .fill(c1.opacity((0.8 - Double(trail) * 0.18) * effIntensity))
                        .frame(width: max(2, 8 - CGFloat(trail) * 1.5), height: max(2, 8 - CGFloat(trail) * 1.5))
                        .offset(x: cos(lag) * radX, y: sin(lag) * radY)
                }
                
                // Главное небесное тело (спутник)
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10 + CGFloat(beatImpact * 4), height: 10 + CGFloat(beatImpact * 4))
                        .shadow(color: c1, radius: 10 + CGFloat(beatImpact * 6))
                    Circle()
                        .stroke(c1, lineWidth: 2)
                        .frame(width: 14 + CGFloat(beatImpact * 5), height: 14 + CGFloat(beatImpact * 5))
                    
                    // Микро-спутник, вращающийся вокруг основного
                    Circle()
                        .fill(c2)
                        .frame(width: 4, height: 4)
                        .offset(x: cos(t * 8.0) * 12, y: sin(t * 8.0) * 12)
                }
                .offset(x: cos(angle1) * radX, y: sin(angle1) * radY)
            }
            .rotationEffect(.degrees(-22))
            
            // 3. Наклонная 3D Орбита 2 (Перекрестный эллипс, 2.1x)
            ZStack {
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [c2.opacity(0.80 * effIntensity), c3.opacity(0.30 * effIntensity)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.6
                    )
                    .frame(width: baseRadius * 2.05, height: baseRadius * 1.10)
                    .shadow(color: c2.opacity(0.5 * effIntensity), radius: 6)
                
                // Спутник 2 с обратным направлением
                let angle2 = -t * 1.4 + 1.8
                let rad2X = baseRadius * 1.025
                let rad2Y = baseRadius * 0.55
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 8 + CGFloat(beatImpact * 3), height: 8 + CGFloat(beatImpact * 3))
                    .overlay(Circle().stroke(c2, lineWidth: 1.5).frame(width: 12, height: 12))
                    .shadow(color: c2, radius: 8)
                    .offset(x: cos(angle2) * rad2X, y: sin(angle2) * rad2Y)
            }
            .rotationEffect(.degrees(38))
            
            // 4. Полярная круговая орбита 3 (наклон 75°)
            Ellipse()
                .stroke(c3.opacity(0.40 * effIntensity), style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
                .frame(width: baseRadius * 1.85, height: baseRadius * 0.85)
                .rotationEffect(.degrees(-70 + sin(t * 0.4) * 8))
            
            // 5. Созвездия и орбитальные узлы (8 узловых звезд)
            ForEach(0..<8, id: \.self) { i in
                let ang = Double(i) * (.pi / 4.0) + t * 0.12
                let dist = baseRadius * (1.18 + (i % 2 == 0 ? 0.15 : -0.08))
                let pulse = abs(sin(t * 2.0 + Double(i)))
                
                Circle()
                    .fill(Color.white.opacity(0.4 + pulse * 0.55))
                    .frame(width: i % 2 == 0 ? 5 : 3.5, height: i % 2 == 0 ? 5 : 3.5)
                    .shadow(color: c1, radius: 4)
                    .offset(x: cos(ang) * dist, y: sin(ang) * dist)
            }
        }
    }
}

// MARK: - 6. Волны (Acoustic Wave Ripples & Spectrum)
struct WavesVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    
    var body: some View {
        let (c1, c2, c3) = colors
        let effIntensity = max(0.42, intensity)
        
        ZStack {
            // 1. Расходящиеся концентрические акустические звуковые волны (до 2.7x)
            ForEach(0..<6, id: \.self) { i in
                let phase = Double(i) * (1.0 / 6.0)
                let progress = (t * 0.75 + phase).truncatingRemainder(dividingBy: 1.0)
                let p = progress < 0 ? progress + 1.0 : progress
                let waveScale = 1.15 + p * 1.55 + (beatImpact * 0.18)
                let alpha = max(0, 1.0 - p) * 0.75 * effIntensity
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [c1.opacity(alpha), c2.opacity(alpha * 0.8), c3.opacity(alpha * 0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.8 + CGFloat((1.0 - p) * 2.2 + beatImpact * 1.5)
                    )
                    .frame(width: size * waveScale, height: size * waveScale)
                    .shadow(color: c1.opacity(alpha * 0.6), radius: 8 + CGFloat(beatImpact * 6))
            }
            
            // 2. Круговой 360-градусный аудио-спектрограф (Circular Equalizer, 36 полос)
            ForEach(0..<36, id: \.self) { i in
                let angle = Double(i) * (360.0 / 36.0)
                let freq = abs(sin(t * 4.2 + Double(i) * 0.52))
                let barHeight = 8.0 + freq * 28.0 * (1.0 + beatImpact * 0.6)
                let rayDist = (size * 0.74) + barHeight / 2.0
                let isPeak = freq > 0.75
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                isPeak ? Color.white : c1.opacity(0.95 * effIntensity),
                                c2.opacity(0.35 * effIntensity)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2.8, height: CGFloat(barHeight))
                    .shadow(color: c1.opacity(effIntensity * (isPeak ? 0.9 : 0.4)), radius: 4)
                    .offset(y: -CGFloat(rayDist))
                    .rotationEffect(.degrees(angle))
            }
            
            // 3. Волновые гармонические дуги (как на иконке «Волны»)
            ForEach(0..<3, id: \.self) { arc in
                let arcScale = 1.25 + Double(arc) * 0.35 + (sin(t * 2.5 + Double(arc)) * 0.05)
                Circle()
                    .trim(from: 0.15, to: 0.35)
                    .stroke(c1.opacity(0.65 * effIntensity), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: size * arcScale, height: size * arcScale)
                    .rotationEffect(.degrees(t * 15.0 + Double(arc * 60)))
                
                Circle()
                    .trim(from: 0.65, to: 0.85)
                    .stroke(c2.opacity(0.65 * effIntensity), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: size * arcScale, height: size * arcScale)
                    .rotationEffect(.degrees(t * 15.0 + Double(arc * 60)))
            }
        }
    }
}

// MARK: - 7. Призма (Chromatic Dispersion Prism)
struct PrismVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    
    var body: some View {
        let effIntensity = max(0.42, intensity)
        let rainbow: [Color] = [
            Color(red: 1.0, green: 0.15, blue: 0.2),  // Red
            Color(red: 1.0, green: 0.55, blue: 0.1),  // Orange
            Color(red: 1.0, green: 0.90, blue: 0.15), // Yellow
            Color(red: 0.15, green: 0.95, blue: 0.4), // Green
            Color(red: 0.05, green: 0.85, blue: 1.0), // Cyan
            Color(red: 0.20, green: 0.35, blue: 1.0), // Blue
            Color(red: 0.70, green: 0.20, blue: 0.95) // Violet
        ]
        
        ZStack {
            // 1. Ореол хроматической дисперсии (широкий круговой спектр 2.5x)
            AngularGradient(
                colors: rainbow + [rainbow.first!],
                center: .center,
                startAngle: .degrees(t * 18.0),
                endAngle: .degrees(t * 18.0 + 360)
            )
            .frame(width: size * 2.5, height: size * 2.5)
            .blur(radius: 36)
            .opacity(0.40 * effIntensity * (1.0 + beatImpact * 0.4))
            .blendMode(.screen)
            
            // 2. Кристаллические призматические треугольники (как на иконке «Призма»)
            ForEach(0..<3, id: \.self) { i in
                let triScale = 1.35 + Double(i) * 0.38
                PrismTriangleShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.70 * effIntensity),
                                rainbow[i * 2].opacity(0.60 * effIntensity),
                                rainbow[(i * 2 + 3) % 7].opacity(0.30 * effIntensity)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.6 + CGFloat(beatImpact * 1.2)
                    )
                    .frame(width: size * triScale, height: size * triScale)
                    .rotationEffect(.degrees(Double(i) * 30.0 + sin(t * 0.8 + Double(i)) * 12.0))
                    .shadow(color: rainbow[i * 2].opacity(0.5 * effIntensity), radius: 8)
            }
            
            // 3. Входящий сфокусированный луч белого света (слева)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.95 * effIntensity)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 1.1, height: 3.5 + CGFloat(beatImpact * 2.5))
                .shadow(color: .white, radius: 8)
                .offset(x: -size * 0.95)
                .rotationEffect(.degrees(-15))
            
            // 4. Веер преломленного радужного спектра (справа, 7 широких лучей до 2.6x)
            ForEach(0..<7, id: \.self) { i in
                let fanAngle = Double(i) * 11.0 - 33.0 + sin(t * 1.2) * 5.0
                let col = rainbow[i]
                let rayWidth = size * 1.55
                let rayThickness = 6.0 + CGFloat(beatImpact * 6.0)
                
                LinearGradient(
                    colors: [
                        col.opacity(0.85 * effIntensity),
                        col.opacity(0.40 * effIntensity),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: rayWidth, height: rayThickness)
                .offset(x: size * 0.92)
                .rotationEffect(.degrees(15 + fanAngle))
                .blur(radius: 2.5)
                .blendMode(.screen)
            }
            
            // 5. Алмазные спектральные искры
            ForEach(0..<6, id: \.self) { i in
                let ang = Double(i) * 60.0 + t * 25.0
                let rad = ang * .pi / 180.0
                let dist = size * 0.95 + CGFloat(sin(t * 3.0 + Double(i)) * 15.0)
                Circle()
                    .fill(rainbow[i])
                    .frame(width: 5, height: 5)
                    .shadow(color: rainbow[i], radius: 6)
                    .offset(x: cos(rad) * dist, y: sin(rad) * dist)
            }
        }
    }
}

// Форма треугольника призмы со скругленными вершинами
struct PrismTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let btmRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let btmLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        path.move(to: top)
        path.addLine(to: btmRight)
        path.addLine(to: btmLeft)
        path.closeSubpath()
        return path
    }
}

// MARK: - 8. Северное сияние (Aurora Borealis Curtains)
struct AuroraVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    
    var body: some View {
        let effIntensity = max(0.42, intensity)
        
        ZStack {
            // 1. Широкие струящиеся драпировки полярного сияния (3.0x ширина)
            ForEach(0..<4, id: \.self) { i in
                let xShift = sin(t * 0.65 + Double(i) * 1.5) * 55.0
                let rot = sin(t * 0.45 + Double(i)) * 14.0
                let curtainColors: [Color] = [
                    Color(red: 0.1, green: 0.95, blue: 0.55).opacity(0.60 * effIntensity), // Aurora Green
                    Color(red: 0.05, green: 0.85, blue: 0.85).opacity(0.45 * effIntensity), // Arctic Mint
                    Color(red: 0.65, green: 0.15, blue: 0.85).opacity(0.35 * effIntensity), // Deep Violet
                    .clear
                ]
                
                LinearGradient(
                    colors: curtainColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: size * 3.0, height: size * 1.9)
                .offset(x: xShift, y: -size * 0.35)
                .rotationEffect(.degrees(rot + Double(i * 8 - 12)))
                .blur(radius: 28)
                .blendMode(.screen)
            }
            
            // 2. Ветровые светящиеся полосы (Wind Streamers, как на иконке «Северное сияние»)
            ForEach(0..<3, id: \.self) { w in
                let yOffset = -size * 0.45 + CGFloat(w * 40)
                let wavePhase = t * 1.5 + Double(w) * 1.8
                
                AuroraWindStreamerShape(phase: wavePhase)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color(red: 0.2, green: 0.95, blue: 0.65).opacity(0.85 * effIntensity),
                                Color(red: 0.7, green: 0.3, blue: 0.95).opacity(0.65 * effIntensity),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.8 + CGFloat(beatImpact * 2.0)
                    )
                    .frame(width: size * 2.8, height: 44)
                    .offset(y: yOffset)
                    .shadow(color: Color(red: 0.2, green: 0.95, blue: 0.65).opacity(0.7 * effIntensity), radius: 10)
            }
            
            // 3. Волнообразные гребни света и ионизированные кванты
            ForEach(0..<12, id: \.self) { i in
                let norm = Double(i) / 11.0 - 0.5
                let posX = norm * Double(size * 2.5)
                let posY = -size * 0.65 + sin(t * 2.2 + Double(i) * 0.7) * 26.0
                let pulse = abs(sin(t * 3.0 + Double(i)))
                
                Circle()
                    .fill(Color(red: 0.2, green: 0.95, blue: 0.65).opacity(0.75 * effIntensity))
                    .frame(width: 8 + CGFloat(pulse * 6 + beatImpact * 6), height: 8 + CGFloat(pulse * 6 + beatImpact * 6))
                    .blur(radius: 3)
                    .shadow(color: .white, radius: 4)
                    .offset(x: CGFloat(posX), y: CGFloat(posY))
            }
        }
    }
}

// Плавная ветровая струя полярного сияния (Синусоидальный стример)
struct AuroraWindStreamerShape: Shape {
    let phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let midY = rect.midY
        let amp = rect.height * 0.42
        
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: w, by: 12) {
            let relativeX = Double(x / w)
            let y = midY + sin(relativeX * 4.0 * .pi + phase) * amp
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

// MARK: - 9. Сверхновая (Supernova Starburst Explosion)
struct SupernovaVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    
    var body: some View {
        let (c1, c2, _) = colors
        let effIntensity = max(0.42, intensity)
        let burstScale = 1.0 + CGFloat(beatImpact * 0.55)
        
        ZStack {
            // 1. Ослепительное ядро вспышки и оптический ореол линзы (2.5x)
            RadialGradient(
                colors: [
                    Color.white.opacity(0.95 * effIntensity),
                    c1.opacity(0.70 * effIntensity),
                    c2.opacity(0.35 * effIntensity),
                    .clear
                ],
                center: .center,
                startRadius: 15,
                endRadius: size * 1.25
            )
            .frame(width: size * 2.5, height: size * 2.5)
            .scaleEffect(burstScale)
            .blur(radius: 20)
            .blendMode(.screen)
            
            // 2. Расширяющиеся сферические ударные волны взрыва
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [c1.opacity(0.85 * effIntensity), Color.white.opacity(0.9 * effIntensity), c2.opacity(0.5 * effIntensity)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.2 + CGFloat(beatImpact * 3.5)
                )
                .frame(width: size * 1.55 * burstScale, height: size * 1.55 * burstScale)
                .shadow(color: c1.opacity(0.8 * effIntensity), radius: 14 + CGFloat(beatImpact * 10))
            
            // Вторичная пульсирующая волна релятивистских частиц
            Circle()
                .stroke(c2.opacity(0.60 * effIntensity), style: StrokeStyle(lineWidth: 1.5, dash: [6, 10]))
                .frame(width: size * 2.2 * (0.95 + CGFloat(sin(t * 2.5) * 0.08)), height: size * 2.2 * (0.95 + CGFloat(sin(t * 2.5) * 0.08)))
                .rotationEffect(.degrees(t * 22.0))
            
            // 3. Главные дифракционные лучи (Star Spikes — как на иконке «Сверхновая», 2.8x)
            // 4 основных луча (горизонтальный и вертикальный крест)
            ForEach(0..<4, id: \.self) { i in
                let angle = Double(i) * 90.0 + sin(t * 0.5) * 2.0
                let spikeLength = size * 2.8 * (1.0 + beatImpact * 0.3)
                
                // Тонкий сверхъяркий белый сердечник луча
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.95 * effIntensity), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: spikeLength, height: 2.5 + CGFloat(beatImpact * 2.5))
                    .rotationEffect(.degrees(angle))
                    .shadow(color: .white, radius: 6)
                
                // Широкое дифракционное сияние луча
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, c1.opacity(0.65 * effIntensity), c2.opacity(0.35 * effIntensity), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: spikeLength * 0.85, height: 10 + CGFloat(beatImpact * 12))
                    .rotationEffect(.degrees(angle))
                    .blur(radius: 4)
                    .blendMode(.screen)
            }
            
            // 4 диагональных вторичных луча (угол 45°, размах 2.1x)
            ForEach(0..<4, id: \.self) { i in
                let angle = Double(i) * 90.0 + 45.0 + sin(t * 0.5) * 2.0
                let spikeLength = size * 2.05 * (1.0 + beatImpact * 0.25)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, c1.opacity(0.80 * effIntensity), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: spikeLength, height: 1.8 + CGFloat(beatImpact * 1.5))
                    .rotationEffect(.degrees(angle))
                    .shadow(color: c1, radius: 4)
            }
            
            // 4. Корональные радиальные выбросы плазмы (24 вспышки вокруг)
            ForEach(0..<24, id: \.self) { i in
                let angle = Double(i) * 15.0 + t * 8.0
                let isLong = (i % 3 == 0)
                let flareLen = size * (isLong ? 0.65 : 0.35) * (1.0 + beatImpact * 0.5)
                let dist = (size * 0.72) + flareLen / 2.0
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9 * effIntensity), c1.opacity(0.6 * effIntensity), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: isLong ? 3.0 : 1.8, height: flareLen)
                    .offset(y: -dist)
                    .rotationEffect(.degrees(angle))
                    .blendMode(.screen)
            }
        }
    }
}

// MARK: - 10. Дыхание космоса (Cosmic Breath & Galaxy)
struct CosmicBreathVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    
    var body: some View {
        let (c1, c2, c3) = colors
        let effIntensity = max(0.42, intensity)
        let breath = 0.95 + abs(sin(t * 0.7)) * 0.22 + (beatImpact * 0.14)
        
        ZStack {
            // 1. Глубокое пульсирующее облако галактической пыли (Nebula Halo 2.6x)
            RadialGradient(
                colors: [
                    c1.opacity(0.55 * effIntensity),
                    c2.opacity(0.35 * effIntensity),
                    c3.opacity(0.20 * effIntensity),
                    .clear
                ],
                center: .center,
                startRadius: 25,
                endRadius: size * 1.3
            )
            .frame(width: size * 2.6, height: size * 2.6)
            .scaleEffect(breath)
            .blur(radius: 32)
            .blendMode(.screen)
            
            // 2. Вращающийся диск галактики (наклонная плоскость звездного скопления)
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [c1.opacity(0.60 * effIntensity), c2.opacity(0.15 * effIntensity), c3.opacity(0.50 * effIntensity)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2.2
                )
                .frame(width: size * 2.45, height: size * 1.15)
                .rotationEffect(.degrees(-32 + t * 4.0))
                .shadow(color: c1.opacity(0.5 * effIntensity), radius: 8)
            
            // 3. Рукава спиральной галактики (4 рукава из звездной пыли)
            ForEach(0..<4, id: \.self) { arm in
                let armBaseAngle = Double(arm) * 90.0
                ForEach(0..<12, id: \.self) { step in
                    let norm = Double(step) / 11.0
                    let theta = armBaseAngle + norm * 140.0 + t * 12.0
                    let r = (size * 0.65) + norm * (size * 0.65)
                    let rad = theta * .pi / 180.0
                    let x = cos(rad) * r
                    let y = sin(rad) * (r * 0.72) // Сплюснутость галактики в перспективе
                    let dotSize = 2.0 + norm * 3.5
                    let alpha = (1.0 - norm * 0.4) * (0.4 + abs(sin(t * 2.0 + Double(step))) * 0.5) * effIntensity
                    
                    Circle()
                        .fill(step % 2 == 0 ? c1.opacity(alpha) : Color.white.opacity(alpha))
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: c1, radius: 4)
                        .offset(x: x, y: y)
                }
            }
            
            // 4. Поле мерцающих звезд разной звездной величины (24 звезды)
            ForEach(0..<24, id: \.self) { i in
                let seed = Double(i) * 137.5
                let dist = (size * 0.72) + CGFloat(seed.truncatingRemainder(dividingBy: Double(size * 0.62)))
                let angle = seed + t * 3.5
                let x = cos(angle * .pi / 180.0) * dist
                let y = sin(angle * .pi / 180.0) * dist
                let starPulse = abs(sin(t * 2.2 + Double(i)))
                let isBright = i % 4 == 0
                
                Circle()
                    .fill(Color.white.opacity(0.35 + starPulse * 0.60))
                    .frame(width: isBright ? 4.5 : 2.5, height: isBright ? 4.5 : 2.5)
                    .shadow(color: isBright ? c1 : .white, radius: isBright ? 5 : 2)
                    .offset(x: x, y: y)
            }
        }
    }
}

// MARK: - 11. Жидкая туманность (Fluid Bioluminescent Plasma)
struct FluidNebulaVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    
    var body: some View {
        let (c1, c2, c3) = colors
        let effIntensity = max(0.42, intensity)
        let orbs = [c1, c2, c3, c1, c2, c3]
        
        ZStack {
            // 1. Центральное биолюминесцентное плазменное кольцо (1.55x)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [c1, c2, c3, c1],
                        center: .center,
                        startAngle: .degrees(t * 30.0),
                        endAngle: .degrees(t * 30.0 + 360)
                    ),
                    lineWidth: 8 + CGFloat(beatImpact * 10)
                )
                .frame(width: size * 1.55, height: size * 1.55)
                .blur(radius: 16)
                .scaleEffect(1.0 + CGFloat(beatImpact * 0.16))
                .blendMode(.screen)
            
            // 2. 6 больших текучих капель плазмы (Metaballs) в широких орбитах Лиссажу (размах 2.5x)
            ForEach(0..<6, id: \.self) { i in
                let angle = t * (0.45 + Double(i) * 0.14) + Double(i) * (2.0 * .pi / 6.0)
                let dist = size * (0.82 + (i % 2 == 0 ? 0.32 : 0.18))
                let x = cos(angle) * dist
                let y = sin(angle * 1.3) * (dist * 0.85)
                let orbDim = size * (0.85 + Double(i % 3) * 0.20)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                orbs[i].opacity(0.70 * effIntensity),
                                orbs[(i + 1) % 6].opacity(0.25 * effIntensity),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: orbDim / 2.0
                        )
                    )
                    .frame(width: orbDim, height: orbDim)
                    .offset(x: x, y: y)
                    .blur(radius: 26)
                    .scaleEffect(1.0 + CGFloat(beatImpact * 0.24))
                    .blendMode(.screen)
            }
            
            // 3. Органические светящиеся завихрения дыма / плазменные волокна
            ForEach(0..<4, id: \.self) { w in
                let waveAngle = Double(w) * 90.0 + t * 15.0
                let waveDist = size * 1.05 + CGFloat(sin(t * 1.8 + Double(w)) * 18.0)
                Circle()
                    .trim(from: 0.1, to: 0.45)
                    .stroke(
                        LinearGradient(
                            colors: [c1.opacity(0.55 * effIntensity), c2.opacity(0.15 * effIntensity)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4.0 + CGFloat(beatImpact * 3.0), lineCap: .round)
                    )
                    .frame(width: waveDist * 1.6, height: waveDist * 1.6)
                    .rotationEffect(.degrees(waveAngle))
                    .blur(radius: 6)
            }
        }
    }
}

// MARK: - 12. Аура (Ethereal Radiant Bloom & Embers)
struct AuraVisualizerView: View {
    let t: Double
    let size: CGFloat
    let colors: (Color, Color, Color)
    let beatImpact: Double
    let intensity: Double
    let glowScale: Double
    
    var body: some View {
        let (c1, c2, c3) = colors
        let effIntensity = max(0.42, intensity)
        
        ZStack {
            // 1. Величественный световой купол и объемное свечение (2.6x)
            RadialGradient(
                colors: [
                    c1.opacity(0.75 * effIntensity),
                    c2.opacity(0.40 * effIntensity),
                    c3.opacity(0.15 * effIntensity),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: size * 1.35 * glowScale
            )
            .frame(width: size * 2.65, height: size * 2.65)
            .scaleEffect(1.0 + (beatImpact * 0.18))
            .blur(radius: 24)
            .blendMode(.screen)
            
            // 2. 12 объемных божественных лучей света (God-Rays, размах 2.8x)
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * 30.0 + sin(t * 0.5 + Double(i) * 0.3) * 8.0
                let isMajor = (i % 2 == 0)
                let rayLen = size * (isMajor ? 1.55 : 1.15) * (1.0 + beatImpact * 0.3)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                (isMajor ? c1 : c2).opacity((isMajor ? 0.45 : 0.25) * effIntensity),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: isMajor ? 38 : 22, height: rayLen)
                    .offset(y: -(size * 0.70 + rayLen / 2.0))
                    .rotationEffect(.degrees(angle))
                    .blur(radius: 14)
                    .blendMode(.screen)
            }
            
            // 3. Звездные 4-конечные искры и парящие кванты света (как на иконке «Аура»)
            ForEach(0..<16, id: \.self) { i in
                let seed = Double(i) * 51.5
                let drift = (t * 0.25 + Double(i) * 0.065).truncatingRemainder(dividingBy: 1.0)
                let p = drift < 0 ? drift + 1.0 : drift
                let yOffset = size * 0.85 - CGFloat(p) * size * 1.7
                let xOffset = sin(t * 1.1 + seed) * (size * 0.85)
                let alpha = sin(p * .pi) * 0.9 * effIntensity
                let isSparkle = (i % 3 == 0)
                
                ZStack {
                    if isSparkle {
                        // 4-конечная звезда-искра
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: -7))
                            path.addLine(to: CGPoint(x: 0, y: 7))
                            path.move(to: CGPoint(x: -7, y: 0))
                            path.addLine(to: CGPoint(x: 7, y: 0))
                        }
                        .stroke(Color.white.opacity(alpha), lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                        .shadow(color: c1, radius: 4)
                    } else {
                        Circle()
                            .fill(c3.opacity(alpha))
                            .frame(width: 4.5, height: 4.5)
                            .shadow(color: c3, radius: 4)
                    }
                }
                .offset(x: xOffset, y: yOffset)
            }
        }
    }
}

// MARK: - 13. Минимализм (Pure Studio Minimalism)
struct MinimalVisualizerView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Внутренняя студийная тонкая рамка
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.2)
                .frame(width: size + 28, height: size + 28)
            
            // Внешняя утонченная рамка с угловыми акцентами
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1.0)
                .frame(width: size + 58, height: size + 58)
                .shadow(color: .black.opacity(0.45), radius: 28, y: 14)
        }
    }
}

// MARK: - Виджет мини-превью в карточках библиотеки настроений (Screen 1)
struct EffectThumbnailPreview: View {
    let effect: Effect
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            switch effect {
            case .vinyl:
                // Мини-винил
                ZStack {
                    Color.black
                    Circle()
                        .fill(Color(white: 0.12))
                        .frame(width: 46, height: 46)
                    ForEach(1..<4, id: \.self) { r in
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                            .frame(width: 22 + CGFloat(r * 7))
                    }
                    Circle()
                        .fill(Theme.accentGradient)
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 5, height: 5)
                }
                
            case .cd:
                // Мини-CD
                ZStack {
                    Color(white: 0.15)
                    Circle()
                        .fill(RadialGradient(colors: [Color(white: 0.85), Color(white: 0.6)], center: .center, startRadius: 4, endRadius: 24))
                        .frame(width: 44, height: 44)
                    Circle()
                        .stroke(
                            AngularGradient(colors: [.cyan, .purple, .yellow, .cyan], center: .center),
                            lineWidth: 12
                        )
                        .frame(width: 32, height: 32)
                        .opacity(0.6)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 8, height: 8)
                }
                
            case .neonPulse:
                // Киберпанк неон HUD
                ZStack {
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                    HUDCornerBracketsShape()
                        .stroke(Color(red: 0.0, green: 0.95, blue: 1.0), lineWidth: 1.8)
                        .frame(width: 36, height: 36)
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.95, green: 0.15, blue: 0.65), lineWidth: 1.4)
                        .frame(width: 26, height: 26)
                        .shadow(color: Color(red: 0.95, green: 0.15, blue: 0.65), radius: 4)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.0, green: 0.95, blue: 1.0))
                }
                
            case .cyberGrid:
                // 3D ретро-сетка
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.02, blue: 0.28), Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // Солнце
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .pink], startPoint: .top, endPoint: .bottom))
                        .frame(width: 24, height: 24)
                        .offset(y: -8)
                    // Линия горизонта
                    Rectangle()
                        .fill(Color.cyan)
                        .frame(height: 1.5)
                        .offset(y: 4)
                    // Перспектива
                    Image(systemName: "grid")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.cyan.opacity(0.7))
                        .offset(y: 14)
                }
                
            case .orbit:
                // Орбиты и спутники
                ZStack {
                    LinearGradient(colors: [Color(red: 0.05, green: 0.04, blue: 0.20), Color.black], startPoint: .top, endPoint: .bottom)
                    Ellipse()
                        .stroke(Color.cyan.opacity(0.8), lineWidth: 1.2)
                        .frame(width: 44, height: 22)
                        .rotationEffect(.degrees(-25))
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                        .shadow(color: .cyan, radius: 4)
                        .offset(x: 16, y: -8)
                    Circle()
                        .fill(Color(red: 0.6, green: 0.2, blue: 0.9))
                        .frame(width: 14, height: 14)
                }
                
            case .waves:
                // Акустические круги
                ZStack {
                    LinearGradient(colors: [Color(red: 0.02, green: 0.2, blue: 0.4), Color.black], startPoint: .top, endPoint: .bottom)
                    ForEach(1..<4, id: \.self) { r in
                        Circle()
                            .stroke(Color.cyan.opacity(0.9 - Double(r) * 0.25), lineWidth: 1.2)
                            .frame(width: CGFloat(r * 14), height: CGFloat(r * 14))
                    }
                    Image(systemName: "water.waves")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                
            case .prism:
                // Радужная призма
                ZStack {
                    Color(white: 0.08)
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask {
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 26))
                    }
                    .shadow(color: .purple.opacity(0.8), radius: 6)
                }
                
            case .aurora:
                // Северное сияние
                ZStack {
                    Color(red: 0.02, green: 0.05, blue: 0.15)
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.mint, Color.purple.opacity(0.6), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blur(radius: 6)
                    Image(systemName: "wind")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                
            case .supernova:
                // Вспышка звезды
                ZStack {
                    Color(red: 0.12, green: 0.04, blue: 0.14)
                    RadialGradient(colors: [.white, .yellow, .pink, .clear], center: .center, startRadius: 2, endRadius: 22)
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 1.5, height: 38)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                    Circle()
                        .stroke(Color.orange, lineWidth: 1.2)
                        .frame(width: 24, height: 24)
                }
                
            case .cosmicBreath:
                // Галактика и звезды
                ZStack {
                    LinearGradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.28), Color.black], startPoint: .top, endPoint: .bottom)
                    Circle()
                        .fill(RadialGradient(colors: [Color.cyan.opacity(0.6), Color.purple.opacity(0.4), .clear], center: .center, startRadius: 2, endRadius: 20))
                        .blur(radius: 4)
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 2, height: 2)
                            .offset(x: CGFloat(i * 6 - 15), y: CGFloat((i * 7) % 20 - 10))
                    }
                    Image(systemName: "aqi.medium")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
            case .nebula:
                // Жидкая плазма
                ZStack {
                    Color(red: 0.06, green: 0.02, blue: 0.12)
                    Circle()
                        .fill(Color.purple.opacity(0.7))
                        .frame(width: 26, height: 26)
                        .blur(radius: 6)
                        .offset(x: -8, y: -6)
                    Circle()
                        .fill(Color.cyan.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .blur(radius: 6)
                        .offset(x: 8, y: 6)
                    Image(systemName: "smoke.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
                
            case .aura:
                // Эфирное сияние
                ZStack {
                    RadialGradient(
                        colors: [Theme.accent.opacity(0.85), Theme.accentSecondary.opacity(0.5), Color.black],
                        center: .center,
                        startRadius: 4,
                        endRadius: 26
                    )
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                
            case .minimal:
                // Минимализм
                ZStack {
                    Color(white: 0.10)
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black, radius: 4)
                    Image(systemName: "square.stack")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }
        }
        .frame(height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Theme.accent : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 0.8)
        )
    }
}
