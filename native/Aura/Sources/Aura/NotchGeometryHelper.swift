import AppKit
import Foundation

/// Информация о геометрии выреза (Notch) на дисплее
public struct NotchInfo: Sendable, Equatable {
    public let hasPhysicalNotch: Bool
    public let screenFrame: CGRect
    /// Координаты выреза в абсолютной системе координат экрана AppKit (0,0 - левый нижний угол)
    public let notchRectInScreen: CGRect
    /// Центр выреза по горизонтали относительно экрана
    public let centerX: CGFloat
    public let width: CGFloat
    public let height: CGFloat
    public let cornerRadius: CGFloat
    
    /// Локальный фрейм выреза для SwiftUI GeometryReader (0,0 - верхний левый угол окна, прижатого к верху экрана)
    public var localRect: CGRect {
        CGRect(
            x: centerX - width / 2.0,
            y: 0,
            width: width,
            height: height
        )
    }
}

public enum NotchGeometryHelper {
    /// Получить параметры выреза для экрана
    public static func notchInfo(for screen: NSScreen) -> NotchInfo {
        let insets = screen.safeAreaInsets
        let frame = screen.frame
        
        // В macOS 12+ на MacBook Pro / Air с челкой safeAreaInsets.top > 0
        // и заданы auxiliaryTopLeftArea / auxiliaryTopRightArea
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea,
           insets.top > 0 {
            
            let notchWidth = max(140.0, rightArea.minX - leftArea.maxX)
            let notchHeight = insets.top
            let notchX = leftArea.maxX
            let notchY = frame.maxY - notchHeight
            let centerX = (notchX + notchWidth / 2.0) - frame.minX
            
            return NotchInfo(
                hasPhysicalNotch: true,
                screenFrame: frame,
                notchRectInScreen: CGRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight),
                centerX: centerX,
                width: notchWidth,
                height: notchHeight,
                cornerRadius: 10.0
            )
        }
        
        // Для экранов без физической челки (Studio Display, внешние мониторы, iMac):
        // Формируем виртуальную капсулу Dynamic Island
        let capsuleWidth: CGFloat = 175.0
        let capsuleHeight: CGFloat = 30.0
        let centerX = frame.width / 2.0
        let notchX = frame.minX + centerX - (capsuleWidth / 2.0)
        let notchY = frame.maxY - capsuleHeight
        
        return NotchInfo(
            hasPhysicalNotch: false,
            screenFrame: frame,
            notchRectInScreen: CGRect(x: notchX, y: notchY, width: capsuleWidth, height: capsuleHeight),
            centerX: centerX,
            width: capsuleWidth,
            height: capsuleHeight,
            cornerRadius: 15.0
        )
    }
    
    /// Найти главный экран с физическим вырезом или текущий экран
    public static func activeNotchScreen() -> NSScreen? {
        // Сначала ищем встроенный экран с физической челкой
        if let notchScreen = NSScreen.screens.first(where: {
            $0.safeAreaInsets.top > 0 && $0.auxiliaryTopLeftArea != nil
        }) {
            return notchScreen
        }
        // Если физической челки нет, используем главный экран
        return NSScreen.main ?? NSScreen.screens.first
    }
}
