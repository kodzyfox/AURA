import SwiftUI

// MARK: - Хелпер тонкой настройки HSB для насыщенного свечения без белесых вымываний
fileprivate extension Color {
    func adjusted(
        hueOffset: Double = 0,
        satMultiplier: Double = 1.0,
        minSat: Double = 0.0,
        briOffset: Double = 0,
        minBri: Double = 0.0
    ) -> Color {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        let isMonochrome = Double(s) < 0.06
        let effectiveMinSat = isMonochrome ? 0.0 : minSat
        let newH = fmod(Double(h) + hueOffset + 1.0, 1.0)
        let newS = min(1.0, max(effectiveMinSat, Double(s) * satMultiplier))
        let newB = min(1.0, max(minBri, Double(b) + briOffset))
        return Color(hue: newH, saturation: newS, brightness: newB, opacity: Double(a))
    }
}

// MARK: - Пульсирующее и переливающееся неоновое свечение по периметру экрана (Ambilight)
struct EdgeGlowView: View {
    let baseColor: Color
    var palette: [Color] = []
    let opacity: Double
    let thickness: Double
    let speed: Double
    let time: Double
    var trackPosition: Double = 0.0
    let isPlaying: Bool
    var audioReactive: Bool = true
    var sensitivity: Double = 1.0
    let colorIndex: Int
    let reduceMotion: Bool
    
    // Вычисление динамических переливающихся оттенков с честной синхронизацией с музыкой
    private var shiftingColors: (Color, Color, Color, Color) {
        let isAudioActive = !reduceMotion && isPlaying && audioReactive
        let beatImpact = isAudioActive ? AudioAnalysisService.shared.beatImpact(at: trackPosition, sensitivity: sensitivity) : 0.0
        
        let t = time * speed
        let bpm = AudioAnalysisService.shared.currentBPM
        let bps = max(0.5, bpm / 60.0)
        // flowProgress: строго привязан к позиции трека без дрейфа — один оборот каждые ~5 тактов
        let flowProgress = isAudioActive ? (trackPosition * bps * 0.12 * speed) : (t * 0.16)
        let kickBoost = beatImpact * 0.14  // сдвиг оттенка в момент удара бочки
        let bBoost = min(1.0, 0.88 + beatImpact * 0.12)  // вспышка яркости при ударе
        
        switch colorIndex {
        case 1:
            // 1. Радужный спектр (Iridescent Rainbow Spectrum)
            let progress = flowProgress
            let h1 = (progress + kickBoost).truncatingRemainder(dividingBy: 1.0)
            let h2 = (progress + 0.25 + kickBoost).truncatingRemainder(dividingBy: 1.0)
            let h3 = (progress + 0.50 + kickBoost).truncatingRemainder(dividingBy: 1.0)
            let h4 = (progress + 0.75 + kickBoost).truncatingRemainder(dividingBy: 1.0)
            return (
                Color(hue: max(0, h1), saturation: 0.94, brightness: bBoost),
                Color(hue: max(0, h2), saturation: 0.94, brightness: bBoost),
                Color(hue: max(0, h3), saturation: 0.94, brightness: bBoost),
                Color(hue: max(0, h4), saturation: 0.94, brightness: bBoost)
            )
            
        case 2:
            // 2. «Северное сияние» / Aurora Borealis (Тиал, Неоновый изумруд, Электрический циан, Индиго)
            let p = flowProgress * 2.0 * .pi
            let kick = kickBoost * 0.08
            let h1 = fmod(0.44 + sin(p) * 0.13 + kick + 1.0, 1.0)
            let h2 = fmod(0.35 + cos(p * 0.85) * 0.11 + kick + 1.0, 1.0)
            let h3 = fmod(0.55 + sin(p * 0.90 + 1.3) * 0.15 + kick + 1.0, 1.0)
            let h4 = fmod(0.72 + cos(p + 2.1) * 0.12 + kick + 1.0, 1.0)
            return (
                Color(hue: max(0, h1), saturation: 0.90, brightness: bBoost),
                Color(hue: max(0, h2), saturation: 0.94, brightness: bBoost),
                Color(hue: max(0, h3), saturation: 0.92, brightness: bBoost),
                Color(hue: max(0, h4), saturation: 0.88, brightness: bBoost)
            )
            
        case 3:
            // 3. «Неоновый закат» / Neon Sunset (Фуксия, Пурпур, Закатный янтарь, Неоновый коралл)
            let p = flowProgress * 2.0 * .pi
            let kick = kickBoost * 0.08
            let h1 = fmod(0.92 + sin(p) * 0.09 + kick + 1.0, 1.0)
            let h2 = fmod(0.06 + cos(p * 0.85) * 0.06 + kick + 1.0, 1.0)
            let h3 = fmod(0.82 + sin(p * 0.90 + 1.4) * 0.10 + kick + 1.0, 1.0)
            let h4 = fmod(0.98 + cos(p + 2.2) * 0.08 + kick + 1.0, 1.0)
            return (
                Color(hue: max(0, h1), saturation: 0.94, brightness: bBoost),
                Color(hue: max(0, h2), saturation: 0.96, brightness: bBoost),
                Color(hue: max(0, h3), saturation: 0.90, brightness: bBoost),
                Color(hue: max(0, h4), saturation: 0.95, brightness: bBoost)
            )
            
        case 8:
            // 8. «Белый» (единственный режим, где свечение должно быть белым)
            let b1 = min(1.0, 0.88 + beatImpact * 0.12)
            let b2 = min(1.0, 0.72 + beatImpact * 0.10)
            return (
                Color.white.opacity(b1),
                Color.white.opacity(b2),
                Color.white.opacity(b1 * 0.92),
                Color.white.opacity(b2 * 0.88)
            )
            
        default:
            // Режим 0: «Обложка» или фиксированные палитры (4: Янтарь, 5: Неон циан, 6: Пурпур, 7: Изумруд)
            // Исключаем белый цвет полностью: свечение строго передает сочные оттенки обложки
            if colorIndex == 0 && palette.count >= 2 {
                let p0 = palette[0].adjusted(minSat: 0.65, briOffset: beatImpact * 0.10, minBri: 0.82)
                let p1 = palette[1].adjusted(minSat: 0.65, briOffset: beatImpact * 0.08, minBri: 0.80)
                let p2 = (palette.count > 2 ? palette[2] : palette[0]).adjusted(minSat: 0.65, briOffset: beatImpact * 0.10, minBri: 0.82)
                let p3 = (palette.count > 3 ? palette[3] : palette[1]).adjusted(minSat: 0.65, briOffset: beatImpact * 0.08, minBri: 0.80)
                return (p0, p1, p2, p3)
            } else {
                let c1 = baseColor.adjusted(minSat: 0.65, briOffset: beatImpact * 0.12, minBri: 0.82)
                let c2 = baseColor.adjusted(hueOffset: 0.05 + kickBoost * 0.05, satMultiplier: 0.95, minSat: 0.60, briOffset: beatImpact * 0.08, minBri: 0.78)
                let c3 = baseColor.adjusted(hueOffset: -0.04 - kickBoost * 0.04, satMultiplier: 1.05, minSat: 0.68, briOffset: beatImpact * 0.10, minBri: 0.80)
                let c4 = baseColor.adjusted(hueOffset: 0.09, satMultiplier: 0.90, minSat: 0.55, briOffset: beatImpact * 0.06, minBri: 0.74)
                return (c1, c2, c3, c4)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let t = time * speed
            
            // Заметное и ритмичное дыхание в такт музыке с честной реакцией на биты трека
            let isAudioActive = !reduceMotion && isPlaying && audioReactive
            let beatImpact = isAudioActive ? AudioAnalysisService.shared.beatImpact(at: trackPosition, sensitivity: sensitivity) : 0.0
            let beatPhase = isAudioActive ? AudioAnalysisService.shared.beatPhase(at: trackPosition) : 0.0
            
            // Ритмичное дыхание: пик СТРОГО в момент удара (beatPhase=0), экспоненциальный спад к следующему
            // Формула: 1 - phase даёт max=1 при phase=0 и min=0 при phase=1
            // Возводим в степень для более острого импульса (как пульс сердца)
            let beatDecay = isAudioActive
                ? pow(max(0.0, 1.0 - beatPhase), 1.6)       // Острый спад от удара к следующему
                : (sin(t * 3.2 + .pi) * 0.5 + 0.5)          // Плавная синусоида в режиме без аудио
            let breath = beatDecay
            
            let pulse = reduceMotion || !isPlaying
                ? 0.85
                : min(1.0, 0.28 + breath * 0.30 + beatImpact * 0.52)
            
            // Перцептивная кривая яркости
            let perceptualAlpha = max(0.18, pow(opacity, 0.75))
            let currentAlpha = min(1.0, perceptualAlpha * pulse)
            
            // Размер свечения: гарантируем, что свет выходит за пределы системного MenuBar (32pt) и Dock (~80pt),
            // а также расширяется при ударах бочки
            let userSize = CGFloat(thickness)
            let reactiveExpand = isAudioActive ? CGFloat(beatImpact * 50.0 + breath * 12.0) : 0.0
            let glowSize = max(95, min((userSize + reactiveExpand) * 1.40, min(w, h) * 0.42))
            
            // Фаза перемещения световых волн (переливов) по периметру экрана.
            // Когда аудио активно — волна идёт строго в такт BPM трека (привязка к trackPosition).
            // Без аудио — плавная анимация по реальному времени.
            let bpm = AudioAnalysisService.shared.currentBPM
            let bps = max(0.5, bpm / 60.0)
            // Каждые 4 доли (такт) волна делает полный оборот — согласованно с ощущением ритма
            let waveSpeed = isAudioActive ? (trackPosition * bps * (0.20 * speed)) : (t * 0.22 * speed)
            let waveOffset = fmod(abs(waveSpeed), 1.0)
            
            let (col1, col2, col3, col4) = shiftingColors
            
            ZStack {
                // 1. Верхняя граница с бегущим переливом (слева направо)
                LinearGradient(
                    colors: [col1, col2, col3, col4, col1],
                    startPoint: UnitPoint(x: waveOffset - 1.0, y: 0),
                    endPoint: UnitPoint(x: waveOffset + 1.0, y: 0)
                )
                .opacity(currentAlpha)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white.opacity(0.65), location: 0.30),
                            .init(color: .white.opacity(0.15), location: 0.70),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: glowSize)
                .frame(maxHeight: .infinity, alignment: .top)
                
                // 2. Нижняя граница с бегущим переливом (справа налево, с учетом высоты Dock)
                LinearGradient(
                    colors: [col3, col2, col1, col4, col3],
                    startPoint: UnitPoint(x: (1.0 - waveOffset) + 1.0, y: 0),
                    endPoint: UnitPoint(x: (1.0 - waveOffset) - 1.0, y: 0)
                )
                .opacity(currentAlpha)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white.opacity(0.65), location: 0.30),
                            .init(color: .white.opacity(0.15), location: 0.70),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: glowSize + 25)
                .frame(maxHeight: .infinity, alignment: .bottom)
                
                // 3. Левая граница с бегущим переливом (снизу вверх)
                LinearGradient(
                    colors: [col4, col1, col2, col3, col4],
                    startPoint: UnitPoint(x: 0, y: (1.0 - waveOffset) + 1.0),
                    endPoint: UnitPoint(x: 0, y: (1.0 - waveOffset) - 1.0)
                )
                .opacity(currentAlpha)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white.opacity(0.65), location: 0.30),
                            .init(color: .white.opacity(0.15), location: 0.70),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: glowSize)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 4. Правая граница с бегущим переливом (сверху вниз)
                LinearGradient(
                    colors: [col2, col3, col4, col1, col2],
                    startPoint: UnitPoint(x: 0, y: waveOffset - 1.0),
                    endPoint: UnitPoint(x: 0, y: waveOffset + 1.0)
                )
                .opacity(currentAlpha)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white.opacity(0.65), location: 0.30),
                            .init(color: .white.opacity(0.15), location: 0.70),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(width: glowSize)
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                // 5. Угловые глубокие ореолы для бесшовного соединения периметра
                RadialGradient(colors: [col1.opacity(currentAlpha * 0.90), .clear], center: .topLeading, startRadius: 0, endRadius: glowSize * 1.6)
                RadialGradient(colors: [col2.opacity(currentAlpha * 0.90), .clear], center: .topTrailing, startRadius: 0, endRadius: glowSize * 1.6)
                RadialGradient(colors: [col3.opacity(currentAlpha * 0.90), .clear], center: .bottomLeading, startRadius: 0, endRadius: glowSize * 1.6)
                RadialGradient(colors: [col4.opacity(currentAlpha * 0.90), .clear], center: .bottomTrailing, startRadius: 0, endRadius: glowSize * 1.6)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
