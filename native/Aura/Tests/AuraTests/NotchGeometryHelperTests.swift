import XCTest
import AppKit
import SwiftUI
@testable import Aura

final class NotchGeometryHelperTests: XCTestCase {
    
    func testNotchInfoLocalRectCalculation() {
        let notch = NotchInfo(
            hasPhysicalNotch: true,
            screenFrame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
            notchRectInScreen: CGRect(x: 774, y: 1083, width: 180, height: 34),
            centerX: 864,
            width: 180,
            height: 34,
            cornerRadius: 10.0
        )
        
        let local = notch.localRect
        XCTAssertEqual(local.origin.x, 864 - (180 / 2.0))
        XCTAssertEqual(local.origin.y, 0)
        XCTAssertEqual(local.size.width, 180)
        XCTAssertEqual(local.size.height, 34)
    }
    
    func testNotchInfoSimulatedVirtualCapsule() {
        let virtualNotch = NotchInfo(
            hasPhysicalNotch: false,
            screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            notchRectInScreen: CGRect(x: 872.5, y: 1050, width: 175, height: 30),
            centerX: 960,
            width: 175,
            height: 30,
            cornerRadius: 15.0
        )
        
        XCTAssertFalse(virtualNotch.hasPhysicalNotch)
        XCTAssertEqual(virtualNotch.cornerRadius, 15.0)
        XCTAssertEqual(virtualNotch.width, 175.0)
        XCTAssertEqual(virtualNotch.height, 30.0)
        XCTAssertEqual(virtualNotch.localRect.origin.x, 960 - 87.5)
    }
    
    func testActiveNotchScreenReturnsScreenIfAvailable() {
        if !NSScreen.screens.isEmpty {
            let active = NotchGeometryHelper.activeNotchScreen()
            XCTAssertNotNil(active)
            
            if let screen = active {
                let info = NotchGeometryHelper.notchInfo(for: screen)
                XCTAssertGreaterThan(info.width, 0)
                XCTAssertGreaterThan(info.height, 0)
                XCTAssertGreaterThan(info.screenFrame.width, 0)
            }
        }
    }
    
    func testPhysicalNotchContourPathBounds() {
        let shape = PhysicalNotchContour(
            centerX: 756,
            width: 185,
            height: 32,
            cornerRadius: 10,
            earRadius: 6
        )
        
        let path = shape.path(in: CGRect(x: 0, y: 0, width: 1512, height: 160))
        let bounds = path.boundingRect
        
        // Должно начинаться на y = 0 (верхний край экрана)
        XCTAssertEqual(bounds.minY, 0, accuracy: 0.5)
        // Должно доходить ровно до высоты челки y = 32
        XCTAssertEqual(bounds.maxY, 32, accuracy: 0.5)
        // Ширина с учетом ушек (185 + 6*2 = 197)
        XCTAssertEqual(bounds.width, 197, accuracy: 1.0)
        // Центр по x должен быть ровно 756
        XCTAssertEqual(bounds.midX, 756, accuracy: 0.5)
    }
    
    func testNotchHoverAreaDoesNotTriggerAtTopScreenEdges() {
        let notch = NotchInfo(
            hasPhysicalNotch: true,
            screenFrame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
            notchRectInScreen: CGRect(x: 774, y: 1083, width: 180, height: 34),
            centerX: 864,
            width: 180,
            height: 34,
            cornerRadius: 10.0
        )
        
        // 1. Точка у левого края экрана (Apple меню / меню приложений: x = 50, y = 1110)
        let leftEdgePoint = CGPoint(x: 50, y: 1110)
        XCTAssertFalse(notch.isPointInNotchOrHUD(screenPoint: leftEdgePoint, isExpanded: false))
        XCTAssertFalse(notch.isPointInNotchOrHUD(screenPoint: leftEdgePoint, isExpanded: true))
        
        // 2. Точка у правого края экрана (Часы / Менюбар Control Center: x = 1680, y = 1110)
        let rightEdgePoint = CGPoint(x: 1680, y: 1110)
        XCTAssertFalse(notch.isPointInNotchOrHUD(screenPoint: rightEdgePoint, isExpanded: false))
        XCTAssertFalse(notch.isPointInNotchOrHUD(screenPoint: rightEdgePoint, isExpanded: true))
        
        // 3. Точка прямо по центру челки (x = 864, y = 1100, т.е. 17pt от верха) -> должна активировать!
        let notchCenterPoint = CGPoint(x: 864, y: 1100)
        XCTAssertTrue(notch.isPointInNotchOrHUD(screenPoint: notchCenterPoint, isExpanded: false))
        XCTAssertTrue(notch.isPointInNotchOrHUD(screenPoint: notchCenterPoint, isExpanded: true))
        
        // 4. Точка ниже челки (x = 864, y = 1050, т.е. 67pt от верха)
        // В свернутом режиме НЕ должна активировать, а в развернутом карточка HUD доходит до 119pt -> должна!
        let belowNotchPoint = CGPoint(x: 864, y: 1050)
        XCTAssertFalse(notch.isPointInNotchOrHUD(screenPoint: belowNotchPoint, isExpanded: false))
        XCTAssertTrue(notch.isPointInNotchOrHUD(screenPoint: belowNotchPoint, isExpanded: true))
    }
}
