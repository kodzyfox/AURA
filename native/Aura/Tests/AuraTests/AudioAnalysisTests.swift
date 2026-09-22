import XCTest
import Accelerate
@testable import Aura

final class AudioAnalysisTests: XCTestCase {
    
    func testRealtimeFFTAnalyzerInitialization() {
        let analyzer = RealtimeFFTAnalyzer()
        let bars = analyzer.getSpectrumBars(count: 21)
        
        XCTAssertEqual(bars.count, 21)
        for bar in bars {
            XCTAssertGreaterThanOrEqual(bar, 0.10)
            XCTAssertLessThanOrEqual(bar, 1.0)
        }
        
        let kick = analyzer.getKickImpact()
        XCTAssertEqual(kick, 0.0)
    }
    
    func testProcessingSilenceKeepsEnergyAtBaseline() {
        let analyzer = RealtimeFFTAnalyzer()
        let silence = [Float](repeating: 0.0, count: 1024)
        
        silence.withUnsafeBufferPointer { ptr in
            analyzer.process(channelData: ptr.baseAddress!, frameLength: 1024)
        }
        
        let bars = analyzer.getSpectrumBars(count: 21)
        XCTAssertEqual(bars.count, 21)
        for bar in bars {
            XCTAssertGreaterThanOrEqual(bar, 0.0)
            XCTAssertLessThanOrEqual(bar, 1.0)
        }
        
        let kick = analyzer.getKickImpact()
        XCTAssertEqual(kick, 0.0, accuracy: 0.01)
    }
    
    func testProcessingSyntheticSineWave() {
        let analyzer = RealtimeFFTAnalyzer()
        let sampleRate: Float = 44100.0
        let frequency: Float = 60.0 // 60 Hz sub-bass
        
        var samples = [Float](repeating: 0.0, count: 1024)
        for i in 0..<1024 {
            let phase = 2.0 * Float.pi * frequency * Float(i) / sampleRate
            samples[i] = sin(phase) * 0.95
        }
        
        samples.withUnsafeBufferPointer { ptr in
            analyzer.process(channelData: ptr.baseAddress!, frameLength: 1024)
        }
        
        let bars = analyzer.getSpectrumBars(count: 21)
        XCTAssertEqual(bars.count, 21)
        // Первый/второй бин (низкие частоты) должен иметь значение больше базового минимума
        XCTAssertGreaterThan(bars[0], 0.12)
    }
    
    func testFlexibleBarCountResampling() {
        let analyzer = RealtimeFFTAnalyzer()
        
        let bars8 = analyzer.getSpectrumBars(count: 8)
        XCTAssertEqual(bars8.count, 8)
        
        let bars32 = analyzer.getSpectrumBars(count: 32)
        XCTAssertEqual(bars32.count, 32)
    }
}
