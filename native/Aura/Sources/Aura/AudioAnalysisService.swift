import Foundation
import SwiftUI
import Accelerate
import AVFoundation

// MARK: - Режимы работы анализа аудио

public enum AudioAnalysisMode: String, CaseIterable, Identifiable, Sendable {
    case localFFT = "Local FFT (Аппаратный DSP)"
    case spotifyCloud = "Spotify Cloud Sync"
    case beatGrid = "Smart Beat-Grid"
    
    public var id: String { rawValue }
    
    public var localizedName: String {
        switch (self, L10n.current) {
        case (.localFFT, .ru): return "Local FFT (Аппаратный DSP)"
        case (.localFFT, .en): return "Local FFT (Hardware DSP)"
        case (.spotifyCloud, _): return "Spotify Cloud Sync"
        case (.beatGrid, _): return "Smart Beat-Grid"
        }
    }
    
    public var badgeTitle: String {
        switch self {
        case .localFFT: return "Local FFT"
        case .spotifyCloud: return "Spotify Sync"
        case .beatGrid: return "Smart Beat-Grid"
        }
    }
    
    public var icon: String {
        switch self {
        case .localFFT: return "waveform.badge.magnifyingglass"
        case .spotifyCloud: return "cloud.fill"
        case .beatGrid: return "metronome.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .localFFT: return Color(red: 0.15, green: 0.90, blue: 0.50) // Неоновый зеленый
        case .spotifyCloud: return Color(red: 0.12, green: 0.75, blue: 1.0) // Неоновый циан
        case .beatGrid: return Color(red: 0.75, green: 0.35, blue: 0.95) // Неоновый фиолетовый
        }
    }
}

// MARK: - Аппаратный анализатор спектра в реальном времени (vDSP FFT)

final class RealtimeFFTAnalyzer: @unchecked Sendable {
    private let fftSize = 1024
    private let halfSize = 512
    private var setup: vDSP_DFT_Setup?
    private var window: [Float]
    
    private var realp: [Float]
    private var imagp: [Float]
    private var magnitudes: [Float]
    private var windowed: [Float]
    
    private var currentBars: [Double]
    private var prevBass: Float = 0.0
    private var kickImpact: Double = 0.0
    private let lock = NSLock()
    
    init() {
        self.setup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(fftSize), vDSP_DFT_Direction.FORWARD)
        self.window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&self.window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        
        self.realp = [Float](repeating: 0, count: halfSize)
        self.imagp = [Float](repeating: 0, count: halfSize)
        self.magnitudes = [Float](repeating: 0, count: halfSize)
        self.windowed = [Float](repeating: 0, count: fftSize)
        self.currentBars = [Double](repeating: 0.12, count: 21)
    }
    
    deinit {
        if let s = setup {
            vDSP_DFT_DestroySetup(s)
        }
    }
    
    func process(channelData: UnsafePointer<Float>, frameLength: Int) {
        guard let setup = self.setup, frameLength >= fftSize else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        // 1. Окно Ханна для исключения спектрального растекания
        vDSP_vmul(channelData, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))
        
        // 2. Упаковка в split complex и выполнение быстрого преобразования Фурье
        realp.withUnsafeMutableBufferPointer { rPtr in
            imagp.withUnsafeMutableBufferPointer { iPtr in
                var split = DSPSplitComplex(realp: rPtr.baseAddress!, imagp: iPtr.baseAddress!)
                windowed.withUnsafeBufferPointer { wPtr in
                    wPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfSize) { cPtr in
                        vDSP_ctoz(cPtr, 2, &split, 1, vDSP_Length(halfSize))
                    }
                }
                vDSP_DFT_Execute(setup, split.realp, split.imagp, split.realp, split.imagp)
                vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(halfSize))
            }
        }
        
        // 3. Вычисление энергии баса (20-250 Гц, бины 1-14) для детекции удара бочки
        var bass: Float = 0
        for b in 1...14 {
            bass += sqrt(magnitudes[b])
        }
        bass /= Float(fftSize)
        
        let delta = bass - prevBass
        if delta > 0.035 && bass > 0.07 {
            kickImpact = min(1.0, Double(bass * 4.8))
        } else {
            kickImpact = max(0.0, kickImpact * 0.88)
        }
        prevBass = bass
        
        // Быстрый спад kickImpact — 0.70 даёт чёткий удар без тянущегося хвоста
        kickImpact = max(0.0, kickImpact * 0.70)

        let binRanges: [(Int, Int)] = [
            (1, 2), (2, 3), (3, 4), (4, 6), (6, 8), (8, 11), (11, 15),
            (15, 20), (20, 27), (27, 36), (36, 48), (48, 64), (64, 85),
            (85, 113), (113, 150), (150, 198), (198, 256), (256, 320),
            (320, 390), (390, 460), (460, 511)
        ]
        
        for i in 0..<min(21, binRanges.count) {
            let (start, end) = binRanges[i]
            var sum: Float = 0
            for b in start...end {
                sum += sqrt(magnitudes[b])
            }
            let avg = (sum / Float(end - start + 1)) / Float(fftSize)
            let boost = 1.0 + Float(i) * 0.12
            let normalized = min(1.0, max(0.0, avg * boost * 16.0))
            
            let oldVal = currentBars[i]
            if Double(normalized) > oldVal {
                currentBars[i] = oldVal * 0.30 + Double(normalized) * 0.70 // Быстрая атака
            } else {
                currentBars[i] = oldVal * 0.82 + Double(normalized) * 0.18 // Плавный спад
            }
        }
    }
    
    func getSpectrumBars(count: Int) -> [Double] {
        lock.lock()
        defer { lock.unlock() }
        if count == 21 {
            return currentBars.map { max(0.12, min(1.0, $0)) }
        }
        return (0..<count).map { i in
            let idx = min(20, (i * 21) / max(1, count))
            return max(0.12, min(1.0, currentBars[idx]))
        }
    }
    
    func getKickImpact() -> Double {
        lock.lock()
        defer { lock.unlock() }
        return kickImpact
    }
    
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        currentBars = [Double](repeating: 0.12, count: 21)
        kickImpact = 0.0
        prevBass = 0.0
    }
}

// MARK: - Аудио-анализ трека (Spotify Audio Features & Analysis)
struct TrackAudioFeatures: Codable {
    var id: String
    var tempo: Double       // Темп в BPM (например, 124.0)
    var energy: Double      // Энергия трека 0.0 - 1.0
    var danceability: Double // Танцевальность 0.0 - 1.0
    var valence: Double     // Настроение (позитивность) 0.0 - 1.0
    var loudness: Double    // Громкость в dB (-60 .. 0)
    var beats: [Double]     // Точные таймкоды долей в секундах
    var isVerified: Bool    // Получено напрямую от Spotify API
}

// MARK: - Сервис аудио-реактивности в такт музыке
@MainActor final class AudioAnalysisService: ObservableObject {
    static let shared = AudioAnalysisService()
    
    @Published var currentBPM: Double = 122.0
    @Published var currentEnergy: Double = 0.75
    @Published var isAnalysisReady: Bool = true
    @Published var isSpotifySynced: Bool = false
    @Published var analysisMode: AudioAnalysisMode = .beatGrid
    
    private let fftAnalyzer = RealtimeFFTAnalyzer()
    
    // Кэш анализа по ID трека
    private var cache: [String: TrackAudioFeatures] = [:]
    private var currentFeatures: TrackAudioFeatures?
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = urls[0].appendingPathComponent("Aura/audio_analysis", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private init() {
        setupFallbackFeatures(id: "default", duration: 180)
    }
    
    func setMode(_ mode: AudioAnalysisMode) {
        self.analysisMode = mode
        if mode != .localFFT {
            fftAnalyzer.reset()
        }
    }
    
    nonisolated func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        fftAnalyzer.process(channelData: channelData, frameLength: Int(buffer.frameLength))
    }
    
    // MARK: - Загрузка и привязка трека
    
    func loadTrack(spotifyTrackId: String?, title: String, artist: String, duration: Double, startOffset: Double = 0) {
        if analysisMode == .localFFT {
            // Для локального звука режим зафиксирован в аппаратном FFT
            return
        }
        
        let trackKey = spotifyTrackId ?? "\(artist)_\(title)".lowercased().filter { $0.isLetter || $0.isNumber }
        
        // 1. Проверяем память
        if let existing = cache[trackKey] {
            applyFeatures(existing)
            return
        }
        
        // 2. Проверяем файловый кэш на диске
        let fileURL = cacheDirectory.appendingPathComponent("\(trackKey).json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(TrackAudioFeatures.self, from: data) {
            cache[trackKey] = saved
            applyFeatures(saved)
            return
        }
        
        // 3. Если есть Spotify Track ID, пробуем получить анализ из Spotify Web API
        if let trackId = spotifyTrackId, !trackId.isEmpty {
            Task {
                if let fetched = await fetchSpotifyAudioFeatures(trackId: trackId, duration: duration) {
                    self.cache[trackKey] = fetched
                    self.saveToDisk(features: fetched, key: trackKey)
                    self.applyFeatures(fetched)
                    return
                }
            }
        }
        
        // 4. Интеллектуальный адаптивный генератор ритма (с учётом текущей позиции в треке)
        let generated = generateAdaptiveBeatGrid(id: trackKey, title: title, artist: artist, duration: duration, startOffset: startOffset)
        cache[trackKey] = generated
        applyFeatures(generated)
    }
    
    private func applyFeatures(_ features: TrackAudioFeatures) {
        self.currentFeatures = features
        self.currentBPM = features.tempo
        self.currentEnergy = features.energy
        self.isSpotifySynced = features.isVerified
        self.isAnalysisReady = true
        if analysisMode != .localFFT {
            self.analysisMode = features.isVerified ? .spotifyCloud : .beatGrid
        }
    }
    
    // MARK: - Вычисление реакции в такт музыке (Real-time Audio Reactive)
    
    /// Возвращает силу удара бита от 0.0 до 1.0 в заданный момент трека
    func beatImpact(at position: Double, sensitivity: Double = 1.0) -> Double {
        if analysisMode == .localFFT {
            return min(1.0, fftAnalyzer.getKickImpact() * sensitivity)
        }
        
        guard let features = currentFeatures, features.tempo > 30 else {
            return fallbackBeatImpact(at: position, sensitivity: sensitivity)
        }
        
        let bpm = features.tempo
        let beatInterval = 60.0 / bpm
        guard beatInterval > 0 else { return 0.0 }
        
        // Если есть точный список битов от Spotify
        if !features.beats.isEmpty {
            let beats = features.beats
            var low = 0
            var high = beats.count - 1
            var bestIdx = 0
            
            while low <= high {
                let mid = (low + high) / 2
                if beats[mid] <= position {
                    bestIdx = mid
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            
            let timeSinceBeat = position - beats[bestIdx]
            let nextBeat = (bestIdx + 1 < beats.count) ? beats[bestIdx + 1] : (beats[bestIdx] + beatInterval)
            let currentInterval = max(0.1, nextBeat - beats[bestIdx])
            
            if timeSinceBeat >= 0 && timeSinceBeat < currentInterval {
                let progress = timeSinceBeat / currentInterval
                let impact = pow(max(0.0, 1.0 - progress * 2.5), 2.0) * features.energy
                return min(1.0, impact * sensitivity)
            }
        }
        
        // Стабильный квантизированный темповый пульс
        let phase = fmod(position, beatInterval) / beatInterval
        let punch = pow(max(0.0, 1.0 - phase * 2.5), 2.0) * features.energy
        return min(1.0, punch * sensitivity)
    }
    
    /// Фаза текущей доли от 0.0 до 1.0 (строго выровнена по реальной ритмической сетке трека)
    func beatPhase(at position: Double) -> Double {
        guard let features = currentFeatures, features.tempo > 30 else {
            let bpm = currentBPM
            let beatInterval = 60.0 / max(40.0, bpm)
            return fmod(position, beatInterval) / beatInterval
        }
        
        let beatInterval = 60.0 / features.tempo
        if !features.beats.isEmpty {
            let beats = features.beats
            var low = 0
            var high = beats.count - 1
            var bestIdx = 0
            
            while low <= high {
                let mid = (low + high) / 2
                if beats[mid] <= position {
                    bestIdx = mid
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            
            let timeSinceBeat = position - beats[bestIdx]
            let nextBeat = (bestIdx + 1 < beats.count) ? beats[bestIdx + 1] : (beats[bestIdx] + beatInterval)
            let currentInterval = max(0.1, nextBeat - beats[bestIdx])
            if timeSinceBeat >= 0 {
                return min(1.0, max(0.0, timeSinceBeat / currentInterval))
            }
        }
        
        return fmod(position, beatInterval) / beatInterval
    }
    
    /// Вычисление динамических полос спектра для режима «Спектр волн»
    func spectrumBars(at position: Double, count: Int) -> [Double] {
        if analysisMode == .localFFT {
            return fftAnalyzer.getSpectrumBars(count: count)
        }
        
        let energy = currentFeatures?.energy ?? currentEnergy
        let bpm = currentFeatures?.tempo ?? currentBPM
        let t = position * (bpm / 60.0) * .pi
        
        return (0..<count).map { i in
            let freq = Double(i + 1) * 0.75
            let sin1 = sin(t * freq) * 0.5 + 0.5
            let sin2 = cos(t * (freq * 0.5)) * 0.3 + 0.3
            let val = (sin1 * 0.7 + sin2 * 0.3) * energy
            return max(0.12, min(1.0, val))
        }
    }
    
    private func fallbackBeatImpact(at position: Double, sensitivity: Double) -> Double {
        let interval = 60.0 / 122.0
        let phase = fmod(position, interval) / interval
        return pow(max(0.0, 1.0 - phase * 3.0), 2.2) * 0.75 * sensitivity
    }
    
    // MARK: - Адаптивный генератор ритмической сетки
    
    private func generateAdaptiveBeatGrid(id: String, title: String, artist: String, duration: Double, startOffset: Double = 0) -> TrackAudioFeatures {
        let hash = abs("\(artist)_\(title)".hashValue)
        let possibleBPMs = [118.0, 120.0, 124.0, 126.0, 128.0, 130.0, 105.0, 95.0, 140.0, 112.0]
        let bpm = possibleBPMs[hash % possibleBPMs.count]
        let energy = 0.65 + Double(hash % 30) / 100.0
        let danceability = 0.60 + Double(hash % 35) / 100.0
        
        let beatInterval = 60.0 / bpm
        var beats: [Double] = []
        
        // Генерируем сетку от 0 до конца трека, но смещаем начальный фазовый сдвиг так, 
        // чтобы ближайший бит совпадал с startOffset
        let phaseAtOffset = startOffset.truncatingRemainder(dividingBy: beatInterval)
        let firstBeat = startOffset - phaseAtOffset  // ближайший бит до startOffset
        
        var t = max(0, firstBeat - beatInterval * 2)  // чуть раньше для запаса
        let total = max(60.0, duration)
        while t < total {
            beats.append(t)
            t += beatInterval
        }
        
        return TrackAudioFeatures(
            id: id,
            tempo: bpm,
            energy: min(0.95, energy),
            danceability: danceability,
            valence: 0.55,
            loudness: -7.5,
            beats: beats,
            isVerified: false
        )
    }
    
    private func setupFallbackFeatures(id: String, duration: Double) {
        let features = generateAdaptiveBeatGrid(id: id, title: "Aura", artist: "Soundtrack", duration: duration)
        self.currentFeatures = features
        self.currentBPM = features.tempo
        self.currentEnergy = features.energy
    }
    
    // MARK: - Spotify Audio Features API Fetcher
    
    private func fetchSpotifyAudioFeatures(trackId: String, duration: Double) async -> TrackAudioFeatures? {
        guard let token = await fetchSpotifyWebToken() else { return nil }
        
        let urlString = "https://api.spotify.com/v1/audio-features/\(trackId)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let tempo = json["tempo"] as? Double ?? 120.0
                let energy = json["energy"] as? Double ?? 0.70
                let danceability = json["danceability"] as? Double ?? 0.60
                let valence = json["valence"] as? Double ?? 0.50
                let loudness = json["loudness"] as? Double ?? -8.0
                
                let beats = await fetchSpotifyAnalysisBeats(trackId: trackId, token: token) ?? []
                
                return TrackAudioFeatures(
                    id: trackId,
                    tempo: tempo,
                    energy: energy,
                    danceability: danceability,
                    valence: valence,
                    loudness: loudness,
                    beats: beats,
                    isVerified: true
                )
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func fetchSpotifyAnalysisBeats(trackId: String, token: String) async -> [Double]? {
        let urlString = "https://api.spotify.com/v1/audio-analysis/\(trackId)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let beatsArray = json["beats"] as? [[String: Any]] {
                return beatsArray.compactMap { $0["start"] as? Double }
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func fetchSpotifyWebToken() async -> String? {
        if let stored = UserDefaults.standard.string(forKey: "aura.spotify.webToken"), !stored.isEmpty {
            return stored
        }
        return nil
    }
    
    private func saveToDisk(features: TrackAudioFeatures, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        if let data = try? JSONEncoder().encode(features) {
            try? data.write(to: fileURL)
        }
    }
}
