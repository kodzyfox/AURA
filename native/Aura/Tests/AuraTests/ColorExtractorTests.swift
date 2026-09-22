import XCTest
import AppKit
import SwiftUI
@testable import Aura

final class ColorExtractorTests: XCTestCase {
    
    private func createSolidColorImage(color: NSColor, size: NSSize = NSSize(width: 40, height: 40)) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }
    
    func testExtractDominantColorFromRedImage() {
        let redImage = createSolidColorImage(color: .red)
        let extractedColor = ColorExtractor.extractDominantColor(from: redImage)
        
        XCTAssertNotNil(extractedColor)
    }
    
    func testExtractPaletteFromMultiColorImage() {
        let size = NSSize(width: 60, height: 60)
        let multiImage = NSImage(size: size)
        multiImage.lockFocus()
        
        NSColor.blue.drawSwatch(in: NSRect(x: 0, y: 0, width: 30, height: 60))
        NSColor.green.drawSwatch(in: NSRect(x: 30, y: 0, width: 30, height: 60))
        multiImage.unlockFocus()
        
        let palette = ColorExtractor.extractPalette(from: multiImage, count: 3)
        XCTAssertFalse(palette.isEmpty)
        XCTAssertEqual(palette.count, 3)
    }
    
    func testFallbackOnEmptyImage() {
        let emptyImage = NSImage(size: NSSize(width: 10, height: 10))
        let palette = ColorExtractor.extractPalette(from: emptyImage, count: 2)
        
        // Должен безопасно вернуть дефолтный цвет вместо падения
        XCTAssertFalse(palette.isEmpty)
    }
}
