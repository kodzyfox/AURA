import XCTest
import SwiftUI
@testable import Aura

final class AtmosphereCodableTests: XCTestCase {
    
    func testDefaultValues() {
        let atmosphere = Atmosphere()
        XCTAssertEqual(atmosphere.effect, .aura)
        XCTAssertEqual(atmosphere.intensity, 0.65)
        XCTAssertEqual(atmosphere.speed, 0.35)
        XCTAssertEqual(atmosphere.blurRadius, 18.0)
        XCTAssertEqual(atmosphere.glowScale, 1.0)
        XCTAssertTrue(atmosphere.showInfo)
        XCTAssertFalse(atmosphere.showClock)
        XCTAssertTrue(atmosphere.notchGlow)
        XCTAssertEqual(atmosphere.notchGlowMode, .dynamicIsland)
        XCTAssertEqual(atmosphere.coverAnimation, .beatPulse)
    }
    
    func testCodableRoundTrip() throws {
        var original = Atmosphere()
        original.effect = .cyberGrid
        original.intensity = 0.95
        original.speed = 0.8
        original.blurRadius = 30.0
        original.glowScale = 1.4
        original.showClock = true
        original.showInfo = false
        original.palette = 3
        original.edgeGlow = false
        original.notchGlow = true
        original.notchGlowMode = .audioWings
        original.notchGlowRadius = 38.0
        original.coverAnimation = .breathe
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Atmosphere.self, from: data)
        
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.effect, .cyberGrid)
        XCTAssertEqual(decoded.notchGlowMode, .audioWings)
        XCTAssertEqual(decoded.coverAnimation, .breathe)
        XCTAssertEqual(decoded.notchGlowRadius, 38.0)
    }
    
    func testBackwardCompatibilityFallbackDecoding() throws {
        // Симулируем старый JSON из ранних версий Aura, где не было параметров Notch, Dynamic Island и анимаций обложки
        let legacyJSON = """
        {
            "effect": "Аура",
            "intensity": 0.5,
            "speed": 0.25,
            "blurRadius": 12.0
        }
        """
        
        guard let data = legacyJSON.data(using: .utf8) else {
            XCTFail("Failed to convert legacy JSON to data")
            return
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Atmosphere.self, from: data)
        
        XCTAssertEqual(decoded.effect, .aura)
        XCTAssertEqual(decoded.intensity, 0.5)
        XCTAssertEqual(decoded.speed, 0.25)
        XCTAssertEqual(decoded.blurRadius, 12.0)
        
        // Поля с дефолтными фоллбэками
        XCTAssertTrue(decoded.notchGlow)
        XCTAssertEqual(decoded.notchGlowMode, .dynamicIsland)
        XCTAssertEqual(decoded.notchGlowRadius, 24.0)
        XCTAssertEqual(decoded.coverAnimation, .beatPulse)
        XCTAssertTrue(decoded.showPlayerOnLockScreen)
        XCTAssertFalse(decoded.showPlayerOnDesktop)
    }
    
    func testEdgeGlowColorIndices() {
        let atmosphere = Atmosphere()
        
        // Индекс 8 - белый цвет
        let whiteColor = atmosphere.edgeGlowColor(artworkColor: nil)
        XCTAssertNotNil(whiteColor)
        
        var custom = atmosphere
        custom.edgeGlowColorIndex = 8
        XCTAssertEqual(custom.edgeGlowColor(artworkColor: nil), Color.white)
        
        // Индекс 0 без обложки фоллбэчит на дефолтный циан
        custom.edgeGlowColorIndex = 0
        let defaultColor = custom.edgeGlowColor(artworkColor: nil)
        XCTAssertEqual(defaultColor, Color(red: 0.0, green: 0.95, blue: 1.0))
        
        // Индекс 0 с переданной обложкой возвращает цвет обложки
        let artColor = Color.purple
        XCTAssertEqual(custom.edgeGlowColor(artworkColor: artColor), artColor)
    }
    
    func testComputeCoverScale() {
        var atmosphere = Atmosphere()
        
        // При coverAnimation == .none масштаб всегда строго 1.0
        atmosphere.coverAnimation = .none
        let noneScale = atmosphere.computeCoverScale(t: 10.0, beatImpact: 0.9)
        XCTAssertEqual(noneScale, 1.0)
        
        // При beatPulse и высоком beatImpact масштаб должен увеличиваться мягко, не более 10%
        atmosphere.coverAnimation = .beatPulse
        atmosphere.audioReactive = true
        atmosphere.reactiveSensitivity = 1.0
        let pulseScale = atmosphere.computeCoverScale(t: 0.0, beatImpact: 0.8)
        XCTAssertGreaterThan(pulseScale, 1.0)
        XCTAssertLessThanOrEqual(pulseScale, 1.10)
        
        // При subtle масштаб деликатный (до +3%)
        atmosphere.coverAnimation = .subtle
        let subtleScale = atmosphere.computeCoverScale(t: 0.0, beatImpact: 0.8)
        XCTAssertGreaterThan(subtleScale, 1.0)
        XCTAssertLessThanOrEqual(subtleScale, 1.04)
        
        // При isPlaying == false масштаб ВСЕГДА строго 1.0 (никакой ложной пульсации на паузе)
        atmosphere.coverAnimation = .beatPulse
        let pausedScale = atmosphere.computeCoverScale(t: 10.0, beatImpact: 0.9, isPlaying: false)
        XCTAssertEqual(pausedScale, 1.0)
    }
    
    func testComputeCoverMotionUniqueCharacteristics() {
        var atmosphere = Atmosphere()
        atmosphere.audioReactive = true
        atmosphere.reactiveSensitivity = 1.0
        
        // 1. Плавное дыхание (breathe) должно иметь вертикальное парение (offsetY != 0)
        atmosphere.coverAnimation = .breathe
        let breatheMotion = atmosphere.computeCoverMotion(t: 1.05, beatImpact: 0.0)
        XCTAssertNotEqual(breatheMotion.offsetY, 0.0, "Breathe must have vertical floating offset")
        
        // 2. Упругий отскок (bounce) должен иметь прыжок вверх (offsetY < 0) и растяжение (scaleY > scaleX)
        atmosphere.coverAnimation = .bounce
        let bounceMotion = atmosphere.computeCoverMotion(t: 0.0, beatImpact: 0.8, beatPhase: 0.15)
        XCTAssertLessThan(bounceMotion.offsetY, 0.0, "Bounce must jump upward into the air")
        XCTAssertGreaterThan(bounceMotion.scaleY, bounceMotion.scaleX, "Bounce must stretch along Y during jump")
        
        // 3. Сердцебиение (heartbeat) в фазе покоя (диастола, например фаза 0.6) должно быть полностью в покое (scale == 1.0)
        atmosphere.coverAnimation = .heartbeat
        let restMotion = atmosphere.computeCoverMotion(t: 0.5, beatImpact: 0.8, beatPhase: 0.0, bpm: 60.0)
        XCTAssertEqual(restMotion.scale, 1.0, accuracy: 0.001, "Heartbeat must have a quiet resting pause (diastole)")
        
        // А в фазе систолы (t = 0.05 при 60 BPM) должен быть мощный удар
        let systoleMotion = atmosphere.computeCoverMotion(t: 0.05, beatImpact: 0.8, beatPhase: 0.0, bpm: 60.0)
        XCTAssertGreaterThan(systoleMotion.scale, 1.03, "Heartbeat must have an energetic systolic thump")
    }
}
