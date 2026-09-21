import AppKit
import SwiftUI

struct WallpaperTrackInfo: Sendable {
    let title: String
    let artist: String
    let progress: Double
    let position: Double
    let duration: Double
    let isPlaying: Bool
}

private struct ScreenTarget: Sendable {
    let screenId: String
    let pixelSize: CGSize
    let scale: CGFloat
}

extension NSScreen {
    var screenIdentifier: String {
        if let screenNumber = (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.stringValue {
            return screenNumber
        }
        return "\(Int(frame.origin.x))_\(Int(frame.origin.y))_\(Int(frame.width))_\(Int(frame.height))"
    }
}

@MainActor final class WallpaperManager {
    static let shared = WallpaperManager()
    
    private var isManagingWallpaper = false
    private var wallpaperCounter: UInt64 = 0
    private var renderGeneration: UInt64 = 0
    private var currentRenderTask: Task<Void, Never>?
    
    // ID монитора -> Текущий установленный временный файл обоев Aura
    private var currentWallpaperURLs: [String: URL] = [:]
    
    // ID монитора -> Исходный пользовательский файл обоев
    private var originalWallpaperURLs: [String: URL] = [:]
    
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates: false,
        .priorityRequestLow: true
    ])
    private let appSupportURL: URL
    
    // Обратная совместимость для исходных обоев главного экрана
    var originalWallpaperURL: URL? {
        get {
            resolveFallbackOriginalWallpaper()
        }
        set {
            if let val = newValue, let mainId = NSScreen.main?.screenIdentifier {
                originalWallpaperURLs[mainId] = val
                saveOriginalWallpaperPaths()
            }
        }
    }
    
    private init() {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = base.appendingPathComponent("Aura", isDirectory: true)
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        
        // Очищаем старые временные файлы обоев от предыдущих запусков
        if let files = try? fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.contains("current_wallpaper") {
                try? fileManager.removeItem(at: file)
            }
        }
        
        loadOriginalWallpaperPaths()
        recordOriginalWallpapers()
    }
    
    // MARK: - Сохранение и восстановление оригинальных обоев (Мультимониторность)
    
    private func loadOriginalWallpaperPaths() {
        let fileManager = FileManager.default
        if let dict = UserDefaults.standard.dictionary(forKey: "aura.originalWallpaperPaths") as? [String: String] {
            for (id, path) in dict where fileManager.fileExists(atPath: path) && !path.contains("current_wallpaper") {
                originalWallpaperURLs[id] = URL(fileURLWithPath: path)
            }
        }
        
        // Миграция старого единичного пути, если он есть
        if let oldPath = UserDefaults.standard.string(forKey: "aura.originalWallpaperPath"),
           fileManager.fileExists(atPath: oldPath),
           !oldPath.contains("current_wallpaper") {
            let oldURL = URL(fileURLWithPath: oldPath)
            if let mainId = NSScreen.main?.screenIdentifier, originalWallpaperURLs[mainId] == nil {
                originalWallpaperURLs[mainId] = oldURL
            }
        }
    }
    
    private func saveOriginalWallpaperPaths() {
        var dict: [String: String] = [:]
        for (id, url) in originalWallpaperURLs {
            dict[id] = url.path
        }
        UserDefaults.standard.set(dict, forKey: "aura.originalWallpaperPaths")
    }
    
    func recordOriginalWallpaper(screen: NSScreen? = nil) {
        recordOriginalWallpapers()
    }
    
    func recordOriginalWallpapers() {
        guard !isManagingWallpaper else { return }
        for screen in NSScreen.screens {
            let id = screen.screenIdentifier
            if let current = NSWorkspace.shared.desktopImageURL(for: screen),
               !current.path.contains("current_wallpaper"),
               !current.path.contains("/Application Support/Aura/"),
               FileManager.default.fileExists(atPath: current.path) {
                originalWallpaperURLs[id] = current
            }
        }
        saveOriginalWallpaperPaths()
    }
    
    func handleScreenParametersChanged() {
        recordOriginalWallpapers()
        let currentScreenIds = Set(NSScreen.screens.map { $0.screenIdentifier })
        originalWallpaperURLs = originalWallpaperURLs.filter { currentScreenIds.contains($0.key) }
        saveOriginalWallpaperPaths()
    }
    
    func resolveFallbackOriginalWallpaper() -> URL? {
        let fileManager = FileManager.default
        let isValid: (URL) -> Bool = { url in
            fileManager.fileExists(atPath: url.path) &&
            !url.path.contains("current_wallpaper") &&
            !url.path.contains("/Application Support/Aura/")
        }
        
        if let mainId = NSScreen.main?.screenIdentifier, let mainURL = originalWallpaperURLs[mainId], isValid(mainURL) {
            return mainURL
        }
        if let first = originalWallpaperURLs.values.first(where: isValid) {
            return first
        }
        if let screen = NSScreen.main, let current = NSWorkspace.shared.desktopImageURL(for: screen), isValid(current) {
            return current
        }
        
        // Системный фолбэк macOS
        let systemCandidates = [
            URL(fileURLWithPath: "/System/Library/CoreServices/DefaultDesktop.heic").resolvingSymlinksInPath(),
            URL(fileURLWithPath: "/System/Library/Desktop Pictures/Sonoma.heic"),
            URL(fileURLWithPath: "/System/Library/Desktop Pictures/Ventura Graphic.madesktop")
        ]
        for candidate in systemCandidates where fileManager.fileExists(atPath: candidate.path) {
            return candidate
        }
        return nil
    }
    
    func restoreOriginalWallpaper() {
        isManagingWallpaper = false
        currentRenderTask?.cancel()
        currentRenderTask = nil
        
        let systemFallback = URL(fileURLWithPath: "/System/Library/CoreServices/DefaultDesktop.heic").resolvingSymlinksInPath()
        
        // Восстанавливаем оригинальные обои индивидуально для каждого монитора
        for screen in NSScreen.screens {
            let id = screen.screenIdentifier
            var candidateURL = originalWallpaperURLs[id]
            if let cand = candidateURL, (!FileManager.default.fileExists(atPath: cand.path) || cand.path.contains("current_wallpaper") || cand.path.contains("/Application Support/Aura/")) {
                candidateURL = nil
            }
            let originalURL = candidateURL
                ?? resolveFallbackOriginalWallpaper() 
                ?? (FileManager.default.fileExists(atPath: systemFallback.path) ? systemFallback : nil)
            guard let original = originalURL else { continue }
            
            // 1. Установка через NSWorkspace API
            do {
                try NSWorkspace.shared.setDesktopImageURL(original, for: screen, options: [:])
            } catch {
                print("NSWorkspace setDesktopImageURL error:", error)
            }
            
            // 2. Гарантированное обновление через AppleScript System Events (обновляет кэш Finder на всех Spaces)
            let escapedPath = original.path
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            let script = "tell application \"System Events\" to set picture of every desktop to POSIX file \"\(escapedPath)\""
            _ = NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
        
        // Удаляем активные временные файлы обоев после применения оригинальных
        for (_, url) in currentWallpaperURLs {
            try? FileManager.default.removeItem(at: url)
        }
        currentWallpaperURLs.removeAll()
        ciContext.clearCaches()
    }
    
    // MARK: - Асинхронная установка динамических обоев
    
    func setDynamicWallpaper(
        from artwork: NSImage,
        tint: Color?,
        style: WallpaperStyle = .poster,
        settings: Atmosphere = Atmosphere(),
        trackInfo: WallpaperTrackInfo? = nil,
        isScreenLocked: Bool = false
    ) {
        guard !NSScreen.screens.isEmpty else { return }
        
        recordOriginalWallpapers()
        isManagingWallpaper = true
        
        // Отменяем предыдущую задачу рендеринга, если пользователь быстро переключил трек или подвинул слайдер
        currentRenderTask?.cancel()
        
        wallpaperCounter &+= 1
        renderGeneration &+= 1
        let targetGeneration = renderGeneration
        
        // Снимок экранов на главном потоке
        var targets: [ScreenTarget] = []
        for screen in NSScreen.screens {
            let scale = screen.backingScaleFactor
            let pixelScale = PerformanceManager.shared.wallpaperPixelScale
            let targetSize = CGSize(
                width: max(1280, screen.frame.width * scale * pixelScale),
                height: max(720, screen.frame.height * scale * pixelScale)
            )
            targets.append(ScreenTarget(
                screenId: screen.screenIdentifier,
                pixelSize: targetSize,
                scale: scale
            ))
        }
        
        let shouldShowPlayer = (isScreenLocked && settings.showPlayerOnLockScreen) || (!isScreenLocked && settings.showPlayerOnDesktop)
        let artworkCopy = artwork.copy() as? NSImage ?? artwork
        let tintCGColor: CGColor? = tint.flatMap {
            NSColor($0).usingColorSpace(.sRGB)?.cgColor ?? NSColor($0).cgColor
        }
        let appSupportURL = self.appSupportURL
        let ciContext = self.ciContext
        
        // Выполняем рендеринг в фоновом потоке, не блокируя UI
        currentRenderTask = Task.detached(priority: .userInitiated) { [weak self, appSupportURL, ciContext] in
            if Task.isCancelled { return }
            
            // Рендерим изображения с дедупликацией по размеру (для одинаковых дисплеев рендерим 1 раз)
            var renderedDataBySize: [String: Data] = [:]
            for target in targets {
                if Task.isCancelled { return }
                let sizeKey = "\(Int(target.pixelSize.width))x\(Int(target.pixelSize.height))"
                if renderedDataBySize[sizeKey] == nil {
                    if let jpegData = Self.renderWallpaperJPEG(
                        artwork: artworkCopy,
                        size: target.pixelSize,
                        scale: target.scale,
                        tint: tintCGColor,
                        style: style,
                        settings: settings,
                        trackInfo: trackInfo,
                        shouldShowPlayer: shouldShowPlayer,
                        isScreenLocked: isScreenLocked,
                        ciContext: ciContext
                    ) {
                        renderedDataBySize[sizeKey] = jpegData
                    }
                }
            }
            
            if Task.isCancelled { return }
            
            // Сохраняем готовые файлы на диск атомарно
            var renderedFiles: [String: URL] = [:]
            for target in targets {
                if Task.isCancelled { break }
                let sizeKey = "\(Int(target.pixelSize.width))x\(Int(target.pixelSize.height))"
                guard let data = renderedDataBySize[sizeKey] else { continue }
                
                let filename = "current_wallpaper_\(target.screenId)_\(targetGeneration).jpg"
                let fileURL = appSupportURL.appendingPathComponent(filename)
                
                do {
                    try data.write(to: fileURL, options: .atomic)
                    renderedFiles[target.screenId] = fileURL
                } catch {
                    print("Failed to write wallpaper for screen \(target.screenId):", error)
                }
            }
            
            let finalRenderedFiles = renderedFiles
            if Task.isCancelled {
                for (_, fileURL) in finalRenderedFiles {
                    try? FileManager.default.removeItem(at: fileURL)
                }
                return
            }
            
            // Возвращаемся на MainActor только для установки готовых обоев через NSWorkspace
            await self?.applyRenderedWallpapers(finalRenderedFiles, generation: targetGeneration)
        }
    }
    
    @MainActor private func applyRenderedWallpapers(_ renderedFiles: [String: URL], generation: UInt64) {
        guard self.renderGeneration == generation,
              self.isManagingWallpaper else {
            for (_, fileURL) in renderedFiles {
                try? FileManager.default.removeItem(at: fileURL)
            }
            return
        }
        
        var newCurrentURLs: [String: URL] = [:]
        for screen in NSScreen.screens {
            let id = screen.screenIdentifier
            if let fileURL = renderedFiles[id] {
                do {
                    try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
                    newCurrentURLs[id] = fileURL
                } catch {
                    print("Failed to set desktop wallpaper for screen \(id):", error)
                }
            }
        }
        
        // Удаляем предыдущие временные файлы, замененные новыми
        for (id, oldURL) in self.currentWallpaperURLs {
            if newCurrentURLs[id] != oldURL {
                try? FileManager.default.removeItem(at: oldURL)
            }
        }
        self.currentWallpaperURLs = newCurrentURLs
        ciContext.clearCaches()
    }
    
    // MARK: - Фоновый рендеринг CoreGraphics & CoreImage
    
    nonisolated private static func renderWallpaperJPEG(
        artwork: NSImage,
        size: CGSize,
        scale: CGFloat,
        tint: CGColor?,
        style: WallpaperStyle,
        settings: Atmosphere,
        trackInfo: WallpaperTrackInfo?,
        shouldShowPlayer: Bool,
        isScreenLocked: Bool,
        ciContext: CIContext
    ) -> Data? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        NSGraphicsContext.current = context
        let cgContext = context.cgContext
        
        drawWallpaperContent(
            context: cgContext,
            artwork: artwork,
            size: size,
            scale: scale,
            tint: tint,
            style: style,
            settings: settings,
            trackInfo: trackInfo,
            shouldShowPlayer: shouldShowPlayer,
            isScreenLocked: isScreenLocked,
            ciContext: ciContext
        )
        
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92])
    }
    
    nonisolated private static func drawWallpaperContent(
        context: CGContext,
        artwork: NSImage,
        size: CGSize,
        scale: CGFloat,
        tint: CGColor?,
        style: WallpaperStyle,
        settings: Atmosphere,
        trackInfo: WallpaperTrackInfo?,
        shouldShowPlayer: Bool,
        isScreenLocked: Bool,
        ciContext: CIContext
    ) {
        let rect = CGRect(origin: .zero, size: size)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let shouldDrawStaticCover = isScreenLocked || (!settings.animatedDesktopCover && settings.coverAnimation == .none)
        
        // Динамические параметры из настроек пользователя
        let effectiveBlur = CGFloat(settings.blurRadius) * scale
        let bgAlpha = CGFloat(max(0.12, min(1.0, settings.intensity * 1.25)))
        
        // 1. Глубокий темный базовый фон
        context.setFillColor(CGColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0))
        context.fill(rect)
        
        switch style {
        case .poster:
            // === РЕЖИМ «АТМОСФЕРНЫЙ ПОСТЕР» ===
            drawBlurredBackground(artwork: artwork, context: context, size: size, rect: rect, blurRadius: effectiveBlur, alpha: bgAlpha, palette: settings.palette, tint: tint, ciContext: ciContext)
            
            let maxDimension = min(size.width * 0.44, size.height * 0.48)
            let coverSize = max(240, maxDimension * CGFloat(settings.coverZoomLevel))
            let yOffset = shouldShowPlayer ? size.height * 0.10 : 0.0
            let coverRect = CGRect(
                x: (size.width - coverSize) / 2.0,
                y: (size.height - coverSize) / 2.0 + yOffset,
                width: coverSize,
                height: coverSize
            )
            
            // 2. Центральная сцена с выбранным визуальным эффектом (Винил, Неоновый пульс, Орбита и т.д.)
            if shouldDrawStaticCover {
                drawCenterVisualScene(
                    context: context,
                    artwork: artwork,
                    size: size,
                    scale: scale,
                    coverRect: coverRect,
                    settings: settings,
                    trackInfo: trackInfo,
                    shouldShowPlayer: shouldShowPlayer,
                    tint: tint,
                    colorSpace: colorSpace
                )
            }
            
            // 3. Плавающая стеклянная карточка плеера
            if shouldShowPlayer, let info = trackInfo {
                let cardWidth = max(640, min(size.width * 0.48, coverSize * 1.05))
                let cardHeight: CGFloat = 190
                let cardY = coverRect.minY - cardHeight - 24
                let dockSafeMargin = max(size.height * 0.14, 150)
                let cardRect = CGRect(x: (size.width - cardWidth) / 2.0, y: max(dockSafeMargin, cardY), width: cardWidth, height: cardHeight)
                drawLockscreenPlayerCard(context: context, rect: cardRect, trackInfo: info, tint: tint)
            }
            
            // 4. Градиенты читаемости под часы и системные панели
            drawReadabilityGradients(context: context, size: size, colorSpace: colorSpace)
            
            // 5. Свечение по краям экрана (Ambilight) на экране блокировки
            if settings.edgeGlow && isScreenLocked {
                drawEdgeGlow(context: context, size: size, scale: scale, settings: settings, tint: tint, colorSpace: colorSpace)
            }
            
        case .fill:
            // === РЕЖИМ «РАЗМЫТЫЙ ФОН И ЦЕНТРАЛЬНАЯ ОБЛОЖКА» ===
            drawBlurredBackground(artwork: artwork, context: context, size: size, rect: rect, blurRadius: effectiveBlur, alpha: bgAlpha, palette: settings.palette, tint: tint, ciContext: ciContext)
            
            let maxDimension = min(size.width * 0.36, size.height * 0.44)
            let coverSize = max(220, maxDimension * CGFloat(settings.coverZoomLevel))
            let yOffset = shouldShowPlayer ? size.height * 0.10 : 0.0
            let coverRect = CGRect(
                x: (size.width - coverSize) / 2.0,
                y: (size.height - coverSize) / 2.0 + yOffset,
                width: coverSize,
                height: coverSize
            )
            
            // 2. Центральная сцена с выбранным визуальным эффектом
            if shouldDrawStaticCover {
                drawCenterVisualScene(
                    context: context,
                    artwork: artwork,
                    size: size,
                    scale: scale,
                    coverRect: coverRect,
                    settings: settings,
                    trackInfo: trackInfo,
                    shouldShowPlayer: shouldShowPlayer,
                    tint: tint,
                    colorSpace: colorSpace
                )
            }
            
            // 3. Карточка плеера
            if shouldShowPlayer, let info = trackInfo {
                let cardWidth = max(640, min(size.width * 0.48, coverSize * 1.05))
                let cardHeight: CGFloat = 190
                let cardY = coverRect.minY - cardHeight - 24
                let dockSafeMargin = max(size.height * 0.14, 150)
                let cardRect = CGRect(x: (size.width - cardWidth) / 2.0, y: max(dockSafeMargin, cardY), width: cardWidth, height: cardHeight)
                drawLockscreenPlayerCard(context: context, rect: cardRect, trackInfo: info, tint: tint)
            }
            
            // 4. Градиенты читаемости под часы и системные панели
            drawReadabilityGradients(context: context, size: size, colorSpace: colorSpace)
            
            // 5. Свечение по краям экрана (Ambilight) на экране блокировки
            if settings.edgeGlow && isScreenLocked {
                drawEdgeGlow(context: context, size: size, scale: scale, settings: settings, tint: tint, colorSpace: colorSpace)
            }
            
        case .center:
            // === КЛАССИЧЕСКИЙ РЕЖИМ МИНИМАЛИЗМ ===
            drawBlurredBackground(artwork: artwork, context: context, size: size, rect: rect, blurRadius: effectiveBlur, alpha: bgAlpha * 0.85, palette: settings.palette, tint: tint, ciContext: ciContext)
            
            let coverSize = min(size.width * 0.40, size.height * 0.48) * CGFloat(settings.coverZoomLevel)
            let coverRect = CGRect(
                x: (size.width - coverSize) / 2.0,
                y: (size.height - coverSize) / 2.0 + (shouldShowPlayer ? size.height * 0.10 : 0.0),
                width: coverSize,
                height: coverSize
            )
            
            if shouldDrawStaticCover {
                drawCenterVisualScene(
                    context: context,
                    artwork: artwork,
                    size: size,
                    scale: scale,
                    coverRect: coverRect,
                    settings: settings,
                    trackInfo: trackInfo,
                    shouldShowPlayer: shouldShowPlayer,
                    tint: tint,
                    colorSpace: colorSpace
                )
            }
            
            if shouldShowPlayer, let info = trackInfo {
                let cardWidth = max(640, min(size.width * 0.48, coverSize * 1.05))
                let cardHeight: CGFloat = 190
                let cardY = coverRect.minY - cardHeight - 24
                let dockSafeMargin = max(size.height * 0.14, 150)
                let cardRect = CGRect(x: (size.width - cardWidth) / 2.0, y: max(dockSafeMargin, cardY), width: cardWidth, height: cardHeight)
                drawLockscreenPlayerCard(context: context, rect: cardRect, trackInfo: info, tint: tint)
            }
            
            // 4. Градиенты читаемости под часы и системные панели
            drawReadabilityGradients(context: context, size: size, colorSpace: colorSpace)
            
            // 5. Свечение по краям экрана (Ambilight) на экране блокировки
            if settings.edgeGlow && isScreenLocked {
                drawEdgeGlow(context: context, size: size, scale: scale, settings: settings, tint: tint, colorSpace: colorSpace)
            }
        }
    }
    
    // MARK: - Отрисовка центральной сцены с учетом выбранного эффекта
    
    nonisolated private static func drawCenterVisualScene(
        context: CGContext,
        artwork: NSImage,
        size: CGSize,
        scale: CGFloat,
        coverRect: CGRect,
        settings: Atmosphere,
        trackInfo: WallpaperTrackInfo?,
        shouldShowPlayer: Bool,
        tint: CGColor?,
        colorSpace: CGColorSpace
    ) {
        let centerX = coverRect.midX
        let centerY = coverRect.midY
        let coverSize = coverRect.width
        let intensity = CGFloat(settings.intensity)
        let glowScale = CGFloat(settings.glowScale)
        
        switch settings.effect {
        case .vinyl:
            drawVinylRecord(
                context: context,
                artwork: artwork,
                size: size,
                centerX: centerX,
                centerY: centerY,
                coverSize: coverSize,
                settings: settings,
                trackInfo: trackInfo,
                shouldShowPlayer: shouldShowPlayer,
                colorSpace: colorSpace
            )
            
        case .neonPulse:
            drawNeonPulseEffect(
                context: context,
                coverRect: coverRect,
                artwork: artwork,
                intensity: intensity,
                glowScale: glowScale,
                tint: tint,
                colorSpace: colorSpace
            )
            if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
                drawCenterTrackText(context: context, size: size, coverRect: coverRect, trackInfo: info)
            }
            
        case .orbit:
            drawOrbitEffect(
                context: context,
                centerX: centerX,
                centerY: centerY,
                coverRect: coverRect,
                artwork: artwork,
                intensity: intensity,
                colorSpace: colorSpace
            )
            if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
                drawCenterTrackText(context: context, size: size, coverRect: coverRect, trackInfo: info)
            }
            
        case .waves:
            drawWavesEffect(
                context: context,
                centerX: centerX,
                centerY: centerY,
                coverRect: coverRect,
                artwork: artwork,
                intensity: intensity,
                colorSpace: colorSpace
            )
            if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
                drawCenterTrackText(context: context, size: size, coverRect: coverRect, trackInfo: info)
            }
            
        case .prism:
            drawPrismEffect(
                context: context,
                centerX: centerX,
                centerY: centerY,
                coverRect: coverRect,
                artwork: artwork,
                intensity: intensity,
                colorSpace: colorSpace
            )
            if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
                drawCenterTrackText(context: context, size: size, coverRect: coverRect, trackInfo: info)
            }
            
        case .aurora:
            drawAuroraEffect(
                context: context,
                size: size,
                coverRect: coverRect,
                artwork: artwork,
                intensity: intensity,
                colorSpace: colorSpace
            )
            if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
                drawCenterTrackText(context: context, size: size, coverRect: coverRect, trackInfo: info)
            }
            
        case .cosmicBreath:
            drawCosmicBreathEffect(
                context: context,
                centerX: centerX,
                centerY: centerY,
                coverRect: coverRect,
                artwork: artwork,
                intensity: intensity,
                colorSpace: colorSpace
            )
            if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
                drawCenterTrackText(context: context, size: size, coverRect: coverRect, trackInfo: info)
            }
            
        case .aura:
            drawAuraEffect(
                context: context,
                centerX: centerX,
                centerY: centerY,
                coverRect: coverRect,
                artwork: artwork,
                intensity: intensity,
                glowScale: glowScale,
                tint: tint,
                colorSpace: colorSpace
            )
            if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
                drawCenterTrackText(context: context, size: size, coverRect: coverRect, trackInfo: info)
            }
            
        case .minimal:
            drawStandardSquareCover(context: context, coverRect: coverRect, artwork: artwork)
            if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
                drawCenterTrackText(context: context, size: size, coverRect: coverRect, trackInfo: info)
            }
        }
    }
    
    // 1. Эффект Виниловой пластинки на рабочем столе
    nonisolated private static func drawVinylRecord(
        context: CGContext,
        artwork: NSImage,
        size: CGSize,
        centerX: CGFloat,
        centerY: CGFloat,
        coverSize: CGFloat,
        settings: Atmosphere,
        trackInfo: WallpaperTrackInfo?,
        shouldShowPlayer: Bool,
        colorSpace: CGColorSpace
    ) {
        let vinylDiameter = coverSize * 1.16
        let vinylRadius = vinylDiameter / 2.0
        let vinylRect = CGRect(x: centerX - vinylRadius, y: centerY - vinylRadius, width: vinylDiameter, height: vinylDiameter)
        
        // 1. Глубокая объемная тень под пластинкой
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: -28),
            blur: 55,
            color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.78)
        )
        context.setFillColor(CGColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0))
        context.fillEllipse(in: vinylRect)
        context.restoreGState()
        
        // 2. Внешний обод диска
        context.saveGState()
        context.setStrokeColor(CGColor(red: 0.22, green: 0.22, blue: 0.26, alpha: 0.8))
        context.setLineWidth(2.2)
        context.strokeEllipse(in: vinylRect)
        context.restoreGState()
        
        // 3. Звуковые бороздки (14 концентрических кругов с переменным блеском)
        context.saveGState()
        for ring in 1...14 {
            let r = vinylRadius * (0.38 + CGFloat(ring) * 0.041)
            let ringRect = CGRect(x: centerX - r, y: centerY - r, width: r * 2, height: r * 2)
            let alpha = (ring % 3 == 0) ? 0.09 : 0.05
            context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha))
            context.setLineWidth(CGFloat((ring % 2 == 0) ? 1.2 : 0.8))
            context.strokeEllipse(in: ringRect)
        }
        context.restoreGState()
        
        // 4. Световые блики на виниле (двойной секторный блик света)
        context.saveGState()
        let sheenPath = CGMutablePath()
        sheenPath.move(to: CGPoint(x: centerX, y: centerY))
        sheenPath.addArc(center: CGPoint(x: centerX, y: centerY), radius: vinylRadius * 0.97, startAngle: -.pi * 0.28, endAngle: .pi * 0.06, clockwise: false)
        sheenPath.closeSubpath()
        sheenPath.move(to: CGPoint(x: centerX, y: centerY))
        sheenPath.addArc(center: CGPoint(x: centerX, y: centerY), radius: vinylRadius * 0.97, startAngle: .pi * 0.72, endAngle: .pi * 1.06, clockwise: false)
        sheenPath.closeSubpath()
        
        context.addPath(sheenPath)
        context.clip()
        
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: [
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.0) as Any,
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.12) as Any,
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.0) as Any
        ] as CFArray, locations: [0.0, 0.5, 1.0]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: centerX - vinylRadius, y: centerY - vinylRadius),
                end: CGPoint(x: centerX + vinylRadius, y: centerY + vinylRadius),
                options: []
            )
        }
        context.restoreGState()
        
        // 5. Центральное «яблоко» с оригинальной обложкой альбома
        let labelDiameter = vinylDiameter * 0.38
        let labelRadius = labelDiameter / 2.0
        let labelRect = CGRect(x: centerX - labelRadius, y: centerY - labelRadius, width: labelDiameter, height: labelDiameter)
        
        context.saveGState()
        let labelPath = CGPath(ellipseIn: labelRect, transform: nil)
        context.addPath(labelPath)
        context.clip()
        context.interpolationQuality = .high
        artwork.draw(in: labelRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        context.restoreGState()
        
        // Тонкий обод вокруг яблока
        context.saveGState()
        context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.35))
        context.setLineWidth(2.2)
        context.strokeEllipse(in: labelRect)
        context.restoreGState()
        
        // 6. Центральное отверстие (шпиндель)
        let holeDiameter: CGFloat = max(16, vinylDiameter * 0.045)
        let holeRadius = holeDiameter / 2.0
        let holeRect = CGRect(x: centerX - holeRadius, y: centerY - holeRadius, width: holeDiameter, height: holeDiameter)
        
        context.saveGState()
        context.setFillColor(CGColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0))
        context.fillEllipse(in: holeRect)
        context.setStrokeColor(CGColor(red: 0.80, green: 0.80, blue: 0.85, alpha: 0.7))
        context.setLineWidth(1.6)
        context.strokeEllipse(in: holeRect)
        context.restoreGState()
        
        // 7. Название трека и артист под винилом
        if let info = trackInfo, !shouldShowPlayer, settings.showInfo {
            let uiScale = max(1.0, size.height / 1080.0)
            let dockSafeMargin = max(size.height * 0.14, 150 * uiScale)
            let targetTextY = centerY - vinylRadius - 38 * uiScale
            let textTopY = max(dockSafeMargin + 32 * uiScale, targetTextY)
            
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 26 * uiScale, weight: .bold),
                .foregroundColor: NSColor.white,
                .shadow: {
                    let s = NSShadow()
                    s.shadowBlurRadius = 10 * uiScale
                    s.shadowOffset = NSSize(width: 0, height: -2 * uiScale)
                    s.shadowColor = NSColor.black.withAlphaComponent(0.85)
                    return s
                }()
            ]
            let artistAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16 * uiScale, weight: .medium),
                .foregroundColor: NSColor(white: 1.0, alpha: 0.85),
                .shadow: {
                    let s = NSShadow()
                    s.shadowBlurRadius = 8 * uiScale
                    s.shadowOffset = NSSize(width: 0, height: -1.5 * uiScale)
                    s.shadowColor = NSColor.black.withAlphaComponent(0.75)
                    return s
                }()
            ]
            let titleStr = NSAttributedString(string: String(info.title.prefix(40)), attributes: titleAttrs)
            let artistStr = NSAttributedString(string: String(info.artist.prefix(45)), attributes: artistAttrs)
            
            let titleSize = titleStr.size()
            let artistSize = artistStr.size()
            
            titleStr.draw(at: NSPoint(x: (size.width - titleSize.width) / 2.0, y: textTopY))
            artistStr.draw(at: NSPoint(x: (size.width - artistSize.width) / 2.0, y: textTopY - 28 * uiScale))
        }
    }
    
    // 2. Эффект Неонового пульса
    nonisolated private static func drawNeonPulseEffect(
        context: CGContext,
        coverRect: CGRect,
        artwork: NSImage,
        intensity: CGFloat,
        glowScale: CGFloat,
        tint: CGColor?,
        colorSpace: CGColorSpace
    ) {
        let cornerRadius = coverRect.width * 0.06
        let pulsePaddings: [CGFloat] = [16, 36, 62].map { $0 * glowScale }
        let pulseAlphas: [CGFloat] = [0.80, 0.48, 0.22].map { $0 * intensity }
        let pulseWidths: [CGFloat] = [3.0, 2.0, 1.4]
        
        for i in 0..<3 {
            let pad = pulsePaddings[i]
            let pulseRect = coverRect.insetBy(dx: -pad, dy: -pad)
            let pulseRadius = cornerRadius + pad * 0.5
            let path = CGPath(roundedRect: pulseRect, cornerWidth: pulseRadius, cornerHeight: pulseRadius, transform: nil)
            
            context.saveGState()
            context.setShadow(
                offset: .zero,
                blur: 24 * glowScale,
                color: CGColor(red: 0.0, green: 0.95, blue: 1.0, alpha: pulseAlphas[i] * 0.9)
            )
            context.addPath(path)
            context.setStrokeColor(CGColor(red: (i % 2 == 0 ? 0.0 : 0.85), green: (i % 2 == 0 ? 0.95 : 0.27), blue: (i % 2 == 0 ? 1.0 : 0.94), alpha: pulseAlphas[i]))
            context.setLineWidth(pulseWidths[i])
            context.strokePath()
            context.restoreGState()
        }
        
        drawStandardSquareCover(context: context, coverRect: coverRect, artwork: artwork)
    }
    
    // 3. Эффект Орбиты (наклонные 3D кольца со спутниками)
    nonisolated private static func drawOrbitEffect(
        context: CGContext,
        centerX: CGFloat,
        centerY: CGFloat,
        coverRect: CGRect,
        artwork: NSImage,
        intensity: CGFloat,
        colorSpace: CGColorSpace
    ) {
        let angles: [CGFloat] = [-18, 14, -5]
        let scales: [CGFloat] = [1.50, 1.82, 2.15]
        
        for i in 0..<3 {
            let w = coverRect.width * scales[i]
            let h = coverRect.height * (0.50 + CGFloat(i) * 0.12)
            let angle = angles[i] * .pi / 180.0
            
            context.saveGState()
            context.translateBy(x: centerX, y: centerY)
            context.rotate(by: angle)
            
            let orbitRect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
            context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.26 * intensity))
            context.setLineWidth(1.6)
            context.strokeEllipse(in: orbitRect)
            
            // Спутники на орбитах
            let satAngle = CGFloat(i) * 1.8 + 0.5
            let satX = (w / 2) * cos(satAngle)
            let satY = (h / 2) * sin(satAngle)
            let satRect = CGRect(x: satX - 5, y: satY - 5, width: 10, height: 10)
            
            context.setShadow(offset: .zero, blur: 8, color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
            context.fillEllipse(in: satRect)
            
            context.restoreGState()
        }
        
        drawStandardSquareCover(context: context, coverRect: coverRect, artwork: artwork)
    }
    
    // 4. Эффект Волн (световые кольца)
    nonisolated private static func drawWavesEffect(
        context: CGContext,
        centerX: CGFloat,
        centerY: CGFloat,
        coverRect: CGRect,
        artwork: NSImage,
        intensity: CGFloat,
        colorSpace: CGColorSpace
    ) {
        for i in 1...6 {
            let r = coverRect.width * (0.55 + CGFloat(i) * 0.18)
            let waveRect = CGRect(x: centerX - r, y: centerY - r, width: r * 2, height: r * 2)
            let alpha = max(0.04, (0.30 - CGFloat(i) * 0.045) * intensity)
            
            context.saveGState()
            context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha))
            context.setLineWidth(2.0 - CGFloat(i) * 0.15)
            context.strokeEllipse(in: waveRect)
            context.restoreGState()
        }
        
        drawStandardSquareCover(context: context, coverRect: coverRect, artwork: artwork)
    }
    
    // 5. Эффект Призмы (хроматическая дисперсия)
    nonisolated private static func drawPrismEffect(
        context: CGContext,
        centerX: CGFloat,
        centerY: CGFloat,
        coverRect: CGRect,
        artwork: NSImage,
        intensity: CGFloat,
        colorSpace: CGColorSpace
    ) {
        let rayLength = coverRect.width * 1.8
        let colors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.0, 0.95, 1.0),   // циан
            (0.85, 0.27, 0.94),  // маджента
            (1.0, 0.75, 0.20),   // янтарь
            (0.12, 0.92, 0.60),  // изумруд
            (0.35, 0.45, 1.0)    // индиго
        ]
        
        context.saveGState()
        context.setBlendMode(.screen)
        for i in 0..<10 {
            let angle = CGFloat(i) * (.pi * 2.0 / 10.0) + 0.2
            let path = CGMutablePath()
            path.move(to: CGPoint(x: centerX, y: centerY))
            let p1 = CGPoint(x: centerX + rayLength * cos(angle - 0.12), y: centerY + rayLength * sin(angle - 0.12))
            let p2 = CGPoint(x: centerX + rayLength * cos(angle + 0.12), y: centerY + rayLength * sin(angle + 0.12))
            path.addLine(to: p1)
            path.addLine(to: p2)
            path.closeSubpath()
            
            let c = colors[i % colors.count]
            context.setFillColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 0.18 * intensity))
            context.addPath(path)
            context.fillPath()
        }
        context.restoreGState()
        
        drawStandardSquareCover(context: context, coverRect: coverRect, artwork: artwork)
    }
    
    // 6. Эффект Северного сияния
    nonisolated private static func drawAuroraEffect(
        context: CGContext,
        size: CGSize,
        coverRect: CGRect,
        artwork: NSImage,
        intensity: CGFloat,
        colorSpace: CGColorSpace
    ) {
        context.saveGState()
        context.setBlendMode(.screen)
        
        let auroraColors: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.05, 0.90, 0.60, 0.24 * intensity), // мята
            (0.55, 0.20, 0.90, 0.20 * intensity), // фиолетовый
            (0.0, 0.80, 1.0, 0.18 * intensity)    // циан
        ]
        
        for (idx, col) in auroraColors.enumerated() {
            let path = CGMutablePath()
            let baseY = size.height * (0.60 + CGFloat(idx) * 0.08)
            path.move(to: CGPoint(x: 0, y: baseY))
            path.addCurve(
                to: CGPoint(x: size.width, y: baseY - 40),
                control1: CGPoint(x: size.width * 0.35, y: baseY + 80),
                control2: CGPoint(x: size.width * 0.70, y: baseY - 90)
            )
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
            
            context.setFillColor(CGColor(red: col.0, green: col.1, blue: col.2, alpha: col.3))
            context.addPath(path)
            context.fillPath()
        }
        context.restoreGState()
        
        drawStandardSquareCover(context: context, coverRect: coverRect, artwork: artwork)
    }
    
    // 7. Эффект Дыхания космоса
    nonisolated private static func drawCosmicBreathEffect(
        context: CGContext,
        centerX: CGFloat,
        centerY: CGFloat,
        coverRect: CGRect,
        artwork: NSImage,
        intensity: CGFloat,
        colorSpace: CGColorSpace
    ) {
        let nebulaRadius = coverRect.width * 1.35
        context.saveGState()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: [
            CGColor(red: 0.10, green: 0.85, blue: 1.0, alpha: 0.35 * intensity) as Any,
            CGColor(red: 0.60, green: 0.15, blue: 0.90, alpha: 0.25 * intensity) as Any,
            CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0) as Any
        ] as CFArray, locations: [0.0, 0.45, 1.0]) {
            context.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: centerX, y: centerY),
                startRadius: 20,
                endCenter: CGPoint(x: centerX, y: centerY),
                endRadius: nebulaRadius,
                options: []
            )
        }
        
        let starOffsets: [(CGFloat, CGFloat, CGFloat)] = [
            (-140, 110, 3.5), (160, 90, 4.0), (-120, -130, 2.5), (140, -110, 3.0),
            (-210, 20, 2.0), (220, -30, 2.5), (0, 180, 4.5), (-60, -190, 3.0),
            (80, 190, 2.5), (-170, 170, 2.0), (190, 160, 3.0), (180, -160, 2.0)
        ]
        for (dx, dy, r) in starOffsets {
            let starRect = CGRect(x: centerX + dx - r, y: centerY + dy - r, width: r * 2, height: r * 2)
            context.setShadow(offset: .zero, blur: 6, color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.8))
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9 * intensity))
            context.fillEllipse(in: starRect)
        }
        context.restoreGState()
        
        drawStandardSquareCover(context: context, coverRect: coverRect, artwork: artwork)
    }
    
    // 8. Эффект Ауры (сферическое сияние)
    nonisolated private static func drawAuraEffect(
        context: CGContext,
        centerX: CGFloat,
        centerY: CGFloat,
        coverRect: CGRect,
        artwork: NSImage,
        intensity: CGFloat,
        glowScale: CGFloat,
        tint: CGColor?,
        colorSpace: CGColorSpace
    ) {
        let auraRadius = coverRect.width * 1.15 * glowScale
        let glowColor = tint ?? CGColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
        
        context.saveGState()
        context.setBlendMode(.screen)
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: [
            glowColor.copy(alpha: 0.55 * intensity) as Any,
            glowColor.copy(alpha: 0.24 * intensity) as Any,
            glowColor.copy(alpha: 0.0) as Any
        ] as CFArray, locations: [0.0, 0.5, 1.0]) {
            context.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: centerX, y: centerY),
                startRadius: coverRect.width * 0.35,
                endCenter: CGPoint(x: centerX, y: centerY),
                endRadius: auraRadius,
                options: []
            )
        }
        context.restoreGState()
        
        drawStandardSquareCover(context: context, coverRect: coverRect, artwork: artwork)
    }
    
    // Стандартная квадратная обложка со стеклянным ободком и объемной тенью
    nonisolated private static func drawStandardSquareCover(
        context: CGContext,
        coverRect: CGRect,
        artwork: NSImage
    ) {
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: -28),
            blur: 55,
            color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.70)
        )
        let cornerRadius = coverRect.width * 0.055
        let path = CGPath(roundedRect: coverRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.addPath(path)
        context.clip()
        context.interpolationQuality = .high
        artwork.draw(in: coverRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        context.restoreGState()
        
        context.saveGState()
        context.addPath(path)
        context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.16))
        context.setLineWidth(1.8)
        context.strokePath()
        context.restoreGState()
    }
    
    // MARK: - Вспомогательные методы отрисовки текста и элементов UI
    
    nonisolated private static func drawCenterTrackText(context: CGContext, size: CGSize, coverRect: CGRect, trackInfo: WallpaperTrackInfo) {
        let uiScale = max(1.0, size.height / 1080.0)
        let dockSafeMargin = max(size.height * 0.14, 150 * uiScale)
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24 * uiScale, weight: .bold),
            .foregroundColor: NSColor.white,
            .shadow: {
                let s = NSShadow()
                s.shadowBlurRadius = 10 * uiScale
                s.shadowOffset = NSSize(width: 0, height: -2 * uiScale)
                s.shadowColor = NSColor.black.withAlphaComponent(0.85)
                return s
            }()
        ]
        let artistAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16 * uiScale, weight: .semibold),
            .foregroundColor: NSColor(white: 1.0, alpha: 0.85),
            .shadow: {
                let s = NSShadow()
                s.shadowBlurRadius = 8 * uiScale
                s.shadowOffset = NSSize(width: 0, height: -1.5 * uiScale)
                s.shadowColor = NSColor.black.withAlphaComponent(0.75)
                return s
            }()
        ]
        
        let titleStr = NSAttributedString(string: String(trackInfo.title.prefix(40)), attributes: titleAttrs)
        let artistStr = NSAttributedString(string: String(trackInfo.artist.prefix(45)), attributes: artistAttrs)
        
        let titleSize = titleStr.size()
        let artistSize = artistStr.size()
        
        // Гарантируем, что текст трека никогда не опускается в зону Dock и держит красивую дистанцию от обложки
        let targetTitleY = coverRect.minY - 52 * uiScale
        let titleY = max(dockSafeMargin + 32 * uiScale, targetTitleY)
        let artistY = titleY - 28 * uiScale
        
        titleStr.draw(at: NSPoint(x: (size.width - titleSize.width) / 2.0, y: titleY))
        artistStr.draw(at: NSPoint(x: (size.width - artistSize.width) / 2.0, y: artistY))
    }
    
    nonisolated private static func drawLockscreenPlayerCard(context: CGContext, rect: CGRect, trackInfo: WallpaperTrackInfo, tint: CGColor?) {
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -14), blur: 32, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.50))
        
        let cardRadius: CGFloat = 28.0
        let cardPath = CGPath(roundedRect: rect, cornerWidth: cardRadius, cornerHeight: cardRadius, transform: nil)
        
        context.setFillColor(CGColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 0.78))
        context.addPath(cardPath)
        context.fillPath()
        
        context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.20))
        context.setLineWidth(1.4)
        context.addPath(cardPath)
        context.strokePath()
        context.restoreGState()
        
        // 1. Заголовок трека
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let titleString = NSAttributedString(string: String(trackInfo.title.prefix(38)), attributes: titleAttrs)
        let titleSize = titleString.size()
        let titleX = rect.minX + (rect.width - titleSize.width) / 2.0
        let titleY = rect.minY + 142
        titleString.draw(at: NSPoint(x: titleX, y: titleY))
        
        // 2. Имя исполнителя
        let artistAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: NSColor(white: 1.0, alpha: 0.70)
        ]
        let artistString = NSAttributedString(string: String(trackInfo.artist.prefix(44)), attributes: artistAttrs)
        let artistSize = artistString.size()
        let artistX = rect.minX + (rect.width - artistSize.width) / 2.0
        let artistY = rect.minY + 116
        artistString.draw(at: NSPoint(x: artistX, y: artistY))
        
        // 3. Секция таймлайна с временем и ползунком
        let timeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor(white: 1.0, alpha: 0.65)
        ]
        
        let leftTimeString = NSAttributedString(string: formatTime(trackInfo.position), attributes: timeAttrs)
        let rightTime = max(0, trackInfo.duration - trackInfo.position)
        let rightTimeString = NSAttributedString(string: formatTime(trackInfo.duration > 0 ? trackInfo.duration : rightTime), attributes: timeAttrs)
        
        let leftTimeSize = leftTimeString.size()
        let rightTimeSize = rightTimeString.size()
        
        let timeMargin: CGFloat = 36
        let barY = rect.minY + 76
        
        leftTimeString.draw(at: NSPoint(x: rect.minX + timeMargin, y: barY - 6))
        rightTimeString.draw(at: NSPoint(x: rect.maxX - timeMargin - rightTimeSize.width, y: barY - 6))
        
        let barLeft = rect.minX + timeMargin + leftTimeSize.width + 14
        let barRight = rect.maxX - timeMargin - rightTimeSize.width - 14
        let barWidth = max(40, barRight - barLeft)
        let barHeight: CGFloat = 5.0
        
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.22))
        let bgBarRect = CGRect(x: barLeft, y: barY, width: barWidth, height: barHeight)
        let bgPath = CGPath(roundedRect: bgBarRect, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
        context.addPath(bgPath)
        context.fillPath()
        
        let progressClamped = CGFloat(max(0.0, min(1.0, trackInfo.progress)))
        let filledWidth = max(5, barWidth * progressClamped)
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
        let fillBarRect = CGRect(x: barLeft, y: barY, width: filledWidth, height: barHeight)
        let fillPath = CGPath(roundedRect: fillBarRect, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
        context.addPath(fillPath)
        context.fillPath()
        
        let pillWidth: CGFloat = 22.0
        let pillHeight: CGFloat = 11.0
        let thumbX = barLeft + filledWidth - pillWidth / 2.0
        let thumbY = barY + barHeight / 2.0 - pillHeight / 2.0
        let thumbRect = CGRect(x: thumbX, y: thumbY, width: pillWidth, height: pillHeight)
        context.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0))
        let thumbPath = CGPath(roundedRect: thumbRect, cornerWidth: 5.5, cornerHeight: 5.5, transform: nil)
        context.addPath(thumbPath)
        context.fillPath()
        
        // 4. Кнопки управления (<<, Play/Pause, >>)
        let controlsCenterY = rect.minY + 36
        let centerX = rect.midX
        
        let circleRadius: CGFloat = 24.0
        let buttonBgColor = tint ?? CGColor(red: 0.44, green: 0.54, blue: 0.46, alpha: 1.0)
        context.setFillColor(buttonBgColor)
        context.fillEllipse(in: CGRect(x: centerX - circleRadius, y: controlsCenterY - circleRadius, width: circleRadius * 2, height: circleRadius * 2))
        
        let iconColor = CGColor(red: 0.12, green: 0.16, blue: 0.12, alpha: 1.0)
        context.setFillColor(iconColor)
        
        if trackInfo.isPlaying {
            let barW: CGFloat = 4.0
            let barH: CGFloat = 15.0
            let pBar1 = CGRect(x: centerX - 7.0, y: controlsCenterY - barH / 2.0, width: barW, height: barH)
            let pBar2 = CGRect(x: centerX + 3.0, y: controlsCenterY - barH / 2.0, width: barW, height: barH)
            context.addPath(CGPath(roundedRect: pBar1, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
            context.addPath(CGPath(roundedRect: pBar2, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
            context.fillPath()
        } else {
            context.beginPath()
            context.move(to: CGPoint(x: centerX - 5, y: controlsCenterY + 8))
            context.addLine(to: CGPoint(x: centerX + 7, y: controlsCenterY))
            context.addLine(to: CGPoint(x: centerX - 5, y: controlsCenterY - 8))
            context.closePath()
            context.fillPath()
        }
        
        let skipColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.88)
        context.setFillColor(skipColor)
        let prevCenterX = centerX - 76
        drawSkipIcon(context: context, centerX: prevCenterX, centerY: controlsCenterY, isForward: false)
        
        let nextCenterX = centerX + 76
        drawSkipIcon(context: context, centerX: nextCenterX, centerY: controlsCenterY, isForward: true)
    }
    
    nonisolated private static func drawSkipIcon(context: CGContext, centerX: CGFloat, centerY: CGFloat, isForward: Bool) {
        let triH: CGFloat = 8.0
        let triW: CGFloat = 8.5
        let spacing: CGFloat = 3.0
        
        if isForward {
            context.beginPath()
            context.move(to: CGPoint(x: centerX - spacing / 2 - triW, y: centerY + triH))
            context.addLine(to: CGPoint(x: centerX - spacing / 2, y: centerY))
            context.addLine(to: CGPoint(x: centerX - spacing / 2 - triW, y: centerY - triH))
            context.closePath()
            context.fillPath()
            
            context.beginPath()
            context.move(to: CGPoint(x: centerX + spacing / 2, y: centerY + triH))
            context.addLine(to: CGPoint(x: centerX + spacing / 2 + triW, y: centerY))
            context.addLine(to: CGPoint(x: centerX + spacing / 2, y: centerY - triH))
            context.closePath()
            context.fillPath()
        } else {
            context.beginPath()
            context.move(to: CGPoint(x: centerX - spacing / 2, y: centerY + triH))
            context.addLine(to: CGPoint(x: centerX - spacing / 2 - triW, y: centerY))
            context.addLine(to: CGPoint(x: centerX - spacing / 2, y: centerY - triH))
            context.closePath()
            context.fillPath()
            
            context.beginPath()
            context.move(to: CGPoint(x: centerX + spacing / 2 + triW, y: centerY + triH))
            context.addLine(to: CGPoint(x: centerX + spacing / 2, y: centerY))
            context.addLine(to: CGPoint(x: centerX + spacing / 2 + triW, y: centerY - triH))
            context.closePath()
            context.fillPath()
        }
    }
    
    nonisolated private static func formatTime(_ seconds: Double) -> String {
        let s = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", s / 60, s % 60)
    }
    
    // MARK: - Вспомогательные методы фона
    
    nonisolated private static func drawBlurredBackground(
        artwork: NSImage,
        context: CGContext,
        size: CGSize,
        rect: CGRect,
        blurRadius: CGFloat,
        alpha: CGFloat,
        palette: Int,
        tint: CGColor?,
        ciContext: CIContext
    ) {
        if let tiff = artwork.tiffRepresentation, let ciImage = CIImage(data: tiff) {
            let originalExtent = ciImage.extent
            if originalExtent.width > 0 && originalExtent.height > 0 {
                let fillScale = max(size.width / originalExtent.width, size.height / originalExtent.height) * 1.05
                let scaledWidth = originalExtent.width * fillScale
                let scaledHeight = originalExtent.height * fillScale
                let originX = (size.width - scaledWidth) / 2.0
                let originY = (size.height - scaledHeight) / 2.0
                
                let centeredImage = ciImage
                    .transformed(by: CGAffineTransform(translationX: -originalExtent.origin.x, y: -originalExtent.origin.y))
                    .transformed(by: CGAffineTransform(scaleX: fillScale, y: fillScale))
                    .transformed(by: CGAffineTransform(translationX: originX, y: originY))
                
                let cropRect = CGRect(origin: .zero, size: size)
                
                if blurRadius < 0.5 {
                    if let cgImage = ciContext.createCGImage(centeredImage, from: cropRect) {
                        context.saveGState()
                        context.setAlpha(alpha)
                        context.draw(cgImage, in: rect)
                        context.restoreGState()
                    }
                } else {
                    let clampedImage = centeredImage.clampedToExtent()
                    let blurFilter = CIFilter(name: "CIGaussianBlur")
                    blurFilter?.setValue(clampedImage, forKey: kCIInputImageKey)
                    blurFilter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
                    
                    if let output = blurFilter?.outputImage {
                        if let cgImage = ciContext.createCGImage(output, from: cropRect) {
                            context.saveGState()
                            context.setAlpha(alpha)
                            context.draw(cgImage, in: rect)
                            context.restoreGState()
                        }
                    }
                }
            }
        }
        
        applyPaletteOverlay(context: context, rect: rect, palette: palette, tint: tint)
    }
    
    nonisolated private static func applyPaletteOverlay(context: CGContext, rect: CGRect, palette: Int, tint: CGColor?) {
        context.saveGState()
        switch palette {
        case 1: // Aura Неон
            context.setFillColor(CGColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 0.22))
            context.fill(rect)
        case 2: // Киберпанк
            context.setFillColor(CGColor(red: 0.70, green: 0.15, blue: 0.90, alpha: 0.25))
            context.fill(rect)
        case 3: // Северное сияние
            context.setFillColor(CGColor(red: 0.05, green: 0.85, blue: 0.60, alpha: 0.20))
            context.fill(rect)
        case 4: // Закат
            context.setFillColor(CGColor(red: 0.95, green: 0.40, blue: 0.30, alpha: 0.22))
            context.fill(rect)
        case 5: // Глубокий океан
            context.setFillColor(CGColor(red: 0.05, green: 0.35, blue: 0.85, alpha: 0.28))
            context.fill(rect)
        case 6: // Лаванда
            context.setFillColor(CGColor(red: 0.65, green: 0.40, blue: 0.90, alpha: 0.22))
            context.fill(rect)
        case 7: // Ночной космос
            context.setFillColor(CGColor(red: 0.04, green: 0.08, blue: 0.18, alpha: 0.45))
            context.fill(rect)
        default: // Тёплая (динамическая из обложки)
            if let tint = tint, let tintWithAlpha = tint.copy(alpha: 0.18) {
                context.setFillColor(tintWithAlpha)
                context.fill(rect)
            }
        }
        context.restoreGState()
    }
    
    nonisolated private static func drawEdgeGlow(context: CGContext, size: CGSize, scale: CGFloat, settings: Atmosphere, tint: CGColor?, colorSpace: CGColorSpace) {
        context.saveGState()
        context.setBlendMode(.normal)
        
        // При edgeGlowColorIndex == 0 («Обложка») используем tint из артворка — цвет реальной обложки
        let glowColor: CGColor
        if settings.edgeGlowColorIndex == 0, let artworkTint = tint {
            glowColor = artworkTint
        } else {
            glowColor = settings.edgeGlowCGColor(artworkColor: tint)
        }
        let alpha = CGFloat(settings.edgeGlowOpacity * 0.75)
        guard let colorWithAlpha = glowColor.copy(alpha: alpha),
              let clearColor = glowColor.copy(alpha: 0.0) else {
            context.restoreGState()
            return
        }
        
        let colors = [colorWithAlpha, clearColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) else {
            context.restoreGState()
            return
        }
        
        let glowThickness: CGFloat = CGFloat(settings.edgeGlowThickness) * scale
        // Top
        context.drawLinearGradient(gradient, start: CGPoint(x: size.width / 2, y: size.height), end: CGPoint(x: size.width / 2, y: size.height - glowThickness), options: [])
        // Bottom
        context.drawLinearGradient(gradient, start: CGPoint(x: size.width / 2, y: 0), end: CGPoint(x: size.width / 2, y: glowThickness), options: [])
        // Left
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height / 2), end: CGPoint(x: glowThickness, y: size.height / 2), options: [])
        // Right
        context.drawLinearGradient(gradient, start: CGPoint(x: size.width, y: size.height / 2), end: CGPoint(x: size.width - glowThickness, y: size.height / 2), options: [])
        
        context.restoreGState()
    }
    
    nonisolated private static func drawReadabilityGradients(context: CGContext, size: CGSize, colorSpace: CGColorSpace) {
        let topColors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.40),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.0)
        ] as CFArray
        if let topGradient = CGGradient(colorsSpace: colorSpace, colors: topColors, locations: [0.0, 1.0]) {
            context.drawLinearGradient(
                topGradient,
                start: CGPoint(x: size.width / 2, y: size.height),
                end: CGPoint(x: size.width / 2, y: size.height - size.height * 0.22),
                options: []
            )
        }
        
        let bottomColors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.42),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.0)
        ] as CFArray
        if let bottomGradient = CGGradient(colorsSpace: colorSpace, colors: bottomColors, locations: [0.0, 1.0]) {
            context.drawLinearGradient(
                bottomGradient,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: size.height * 0.18),
                options: []
            )
        }
    }
}
