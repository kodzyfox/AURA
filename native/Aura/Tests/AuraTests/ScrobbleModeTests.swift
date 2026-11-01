import XCTest
@testable import Aura

@MainActor
final class ScrobbleModeTests: XCTestCase {
    
    func testScrobblingCoordinatorThresholds() {
        let coordinator = ScrobblingCoordinator.shared
        
        // Порог для трека <= 0 сек
        XCTAssertEqual(coordinator.threshold(for: 0), 30.0)
        XCTAssertEqual(coordinator.threshold(for: -10), 30.0)
        
        // Порог для короткого трека 40 сек: 50% = 20 сек, но минимум 30 сек
        XCTAssertEqual(coordinator.threshold(for: 40.0), 30.0)
        
        // Порог для трека 120 сек: 50% = 60 сек
        XCTAssertEqual(coordinator.threshold(for: 120.0), 60.0)
        
        // Порог для трека 300 сек (5 минут): 50% = 150 сек
        XCTAssertEqual(coordinator.threshold(for: 300.0), 150.0)
        
        // Порог для длинного трека 600 сек (10 минут): максимум 240 сек (4 мин)
        XCTAssertEqual(coordinator.threshold(for: 600.0), 240.0)
    }
    
    func testMusicControllerScrobbleModeCoordination() {
        let music = MusicController()
        
        // Включение режима скроблинга
        music.isScrobbleMode = true
        XCTAssertTrue(music.isScrobbleMode)
        XCTAssertFalse(music.isCoverMode)
        XCTAssertFalse(music.isMiniPlayer)
        
        // Включение мини-плеера выключает режим скроблинга
        music.toggleMiniPlayer()
        XCTAssertTrue(music.isMiniPlayer)
        XCTAssertFalse(music.isScrobbleMode)
        
        // Переключение обратно в режим скроблинга выключает мини-плеер
        music.toggleScrobbleMode()
        XCTAssertTrue(music.isScrobbleMode)
        XCTAssertFalse(music.isMiniPlayer)
        
        // Включение режима обложки выключает режим скроблинга
        music.toggleCoverMode()
        XCTAssertTrue(music.isCoverMode)
        XCTAssertFalse(music.isScrobbleMode)
        
        // Возврат в режим скроблинга
        music.toggleScrobbleMode()
        XCTAssertTrue(music.isScrobbleMode)
        XCTAssertFalse(music.isCoverMode)
        
        // Выключение режима скроблинга
        music.toggleScrobbleMode()
        XCTAssertFalse(music.isScrobbleMode)
    }
    
    func testScrobbleThresholdComputedProperties() {
        let music = MusicController()
        music.duration = 200.0
        XCTAssertEqual(music.scrobbleThresholdSeconds, 100.0)
        
        music.duration = 600.0
        XCTAssertEqual(music.scrobbleThresholdSeconds, 240.0)
    }

    func testScrobbleModeNotchToggle() {
        let music = MusicController()
        let initialNotch = music.scrobbleModeNotchEnabled
        music.scrobbleModeNotchEnabled.toggle()
        XCTAssertEqual(music.scrobbleModeNotchEnabled, !initialNotch)
        // Reset to initial
        music.scrobbleModeNotchEnabled = initialNotch
    }

    func testAutomaticTerminationDisabledInInfoPlist() {
        // Проверяем, что в Info.plist отключено автоматическое и внезапное завершение macOS (TAL)
        let infoPlistURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // AuraTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // native/Aura
            .appendingPathComponent("Info.plist")
        
        guard let data = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            XCTFail("Failed to load or parse native/Aura/Info.plist at \(infoPlistURL.path)")
            return
        }

        XCTAssertEqual(plist["NSSupportsAutomaticTermination"] as? Bool, false, "NSSupportsAutomaticTermination must be false to prevent macOS from terminating background scrobbler")
        XCTAssertEqual(plist["NSSupportsSuddenTermination"] as? Bool, false, "NSSupportsSuddenTermination must be false to protect background state")
        XCTAssertEqual(plist["NSAppSleepDisabled"] as? Bool, true, "NSAppSleepDisabled must be true to prevent App Nap from suspending timers")
    }

    func testAppDelegateBackgroundModePreserved() {
        let delegate = AppDelegate()
        UserDefaults.standard.set(true, forKey: "aura.backgroundMode")
        UserDefaults.standard.set(WindowCloseBehavior.hideToMenuBar.rawValue, forKey: "aura.windowCloseBehavior")
        XCTAssertFalse(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
    }
}
