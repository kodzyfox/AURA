import Foundation
import AVFoundation

/// Сервис воспроизведения локальных аудиофайлов на базе AVAudioEngine с tap-шиной для спектрального анализа
@MainActor final class LocalAudioService {
    static let shared = LocalAudioService()
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var currentFile: AVAudioFile?
    
    private var tapInstalled = false
    private var seekOffset: Double = 0
    private var sampleRate: Double = 44100
    private var totalFrames: AVAudioFramePosition = 0
    
    var duration: Double = 0
    private(set) var isPlaying: Bool = false
    
    var onTrackDidFinish: (@MainActor () -> Void)?
    
    private init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        setupTap()
    }
    
    private func setupTap() {
        guard !tapInstalled else { return }
        // Устанавливаем шину захвата PCM-семплов на главном микшере (1024 семпла на блок)
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
            AudioAnalysisService.shared.processAudioBuffer(buffer)
        }
        tapInstalled = true
    }
    
    private func ensureEngineRunning() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }
    
    /// Загрузка аудиофайла и подготовка к воспроизведению
    func load(url: URL) throws {
        stop()
        
        let file = try AVAudioFile(forReading: url)
        self.currentFile = file
        self.sampleRate = file.processingFormat.sampleRate
        self.totalFrames = file.length
        self.duration = sampleRate > 0 ? (Double(totalFrames) / sampleRate) : 0
        self.seekOffset = 0
        
        try ensureEngineRunning()
        schedulePlayback(fromFrame: 0)
    }
    
    private func schedulePlayback(fromFrame frame: AVAudioFramePosition) {
        guard let file = currentFile else { return }
        
        let remainingFrames = max(0, totalFrames - frame)
        guard remainingFrames > 0 else { return }
        
        playerNode.scheduleSegment(
            file,
            startingFrame: frame,
            frameCount: AVAudioFrameCount(remainingFrames),
            at: nil,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isPlaying else { return }
                // Проверяем, действительно ли трек доиграл до конца
                if self.currentTime >= self.duration - 0.5 {
                    self.isPlaying = false
                    self.onTrackDidFinish?()
                }
            }
        }
    }
    
    /// Текущее время воспроизведения в секундах
    var currentTime: Double {
        guard isPlaying,
              let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
              playerTime.sampleRate > 0 else {
            return seekOffset
        }
        let elapsed = Double(playerTime.sampleTime) / playerTime.sampleRate
        return min(duration, max(0, seekOffset + elapsed))
    }
    
    func play() -> Bool {
        guard currentFile != nil else { return false }
        do {
            try ensureEngineRunning()
            playerNode.play()
            isPlaying = true
            return true
        } catch {
            print("Failed to start audio engine:", error)
            return false
        }
    }
    
    func pause() {
        guard isPlaying else { return }
        seekOffset = currentTime
        playerNode.pause()
        isPlaying = false
    }
    
    func stop() {
        isPlaying = false
        seekOffset = 0
        playerNode.stop()
    }
    
    func seek(to seconds: Double) {
        let clamped = max(0, min(duration, seconds))
        seekOffset = clamped
        
        guard currentFile != nil else { return }
        let targetFrame = AVAudioFramePosition(clamped * sampleRate)
        
        let wasPlaying = isPlaying
        playerNode.stop()
        schedulePlayback(fromFrame: targetFrame)
        
        if wasPlaying {
            playerNode.play()
            isPlaying = true
        }
    }
    
    func setVolume(_ volume: Double) {
        let clamped = max(0.0, min(1.0, Float(volume)))
        playerNode.volume = clamped
    }
}
