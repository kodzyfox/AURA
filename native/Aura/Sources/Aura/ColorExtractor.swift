import SwiftUI
import AppKit
import CoreImage

enum ColorExtractor {
    
    // MARK: - Один доминантный цвет (сочный и характерный)
    static func extractDominantColor(from image: NSImage) -> Color? {
        // Используем наиболее яркий и характерный цвет из палитры k-means
        let palette = extractPalette(from: image, count: 3)
        return palette.first
    }
    
    // MARK: - Несколько доминантных цветов через k-means (для режима "Обложка")
    /// Возвращает `k` наиболее ярких и насыщенных цветов обложки.
    /// Используется для многоцветного свечения в стиле Ambilight.
    static func extractPalette(from image: NSImage, count k: Int = 3) -> [Color] {
        guard let pixels = samplePixels(from: image, count: 256) else {
            return [Color(red: 0.0, green: 0.95, blue: 1.0)]
        }
        
        // Фильтруем: убираем слишком тёмные и почти серые пиксели
        let vivid = pixels.filter { r, g, b in
            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))
            let saturation = maxC > 0 ? (maxC - minC) / maxC : 0
            return maxC > 0.12 && saturation > 0.14
        }
        
        let source = vivid.isEmpty ? pixels : vivid
        guard !source.isEmpty else {
            return [Color(red: 0.0, green: 0.95, blue: 1.0)]
        }
        
        // Простой k-means (4 итерации для точности)
        var centers: [(Double, Double, Double)] = Array(source.shuffled().prefix(k))
        if centers.count < k {
            while centers.count < k { centers.append(centers[0]) }
        }
        
        for _ in 0..<4 {
            var clusters: [[(Double, Double, Double)]] = Array(repeating: [], count: k)
            for px in source {
                var bestIdx = 0
                var bestDist = Double.infinity
                for (idx, c) in centers.enumerated() {
                    let d = dist(px, c)
                    if d < bestDist { bestDist = d; bestIdx = idx }
                }
                clusters[bestIdx].append(px)
            }
            for i in 0..<k {
                guard !clusters[i].isEmpty else { continue }
                let n = Double(clusters[i].count)
                centers[i] = (
                    clusters[i].map { $0.0 }.reduce(0, +) / n,
                    clusters[i].map { $0.1 }.reduce(0, +) / n,
                    clusters[i].map { $0.2 }.reduce(0, +) / n
                )
            }
        }
        
        // Сортируем по сочности и яркости (наиболее выразительные цвета первыми)
        let sorted = centers.sorted { a, b in
            let sa = saturation(a); let sb = saturation(b)
            let ba = max(a.0, max(a.1, a.2)); let bb = max(b.0, max(b.1, b.2))
            return (sa * 0.70 + ba * 0.30) > (sb * 0.70 + bb * 0.30)
        }
        
        let result = sorted.compactMap { boosted(r: $0.0, g: $0.1, b: $0.2) }
        return result.isEmpty ? [Color(red: 0.0, green: 0.95, blue: 1.0)] : result
    }
    
    // MARK: - Private helpers
    
    /// Сэмплирует равномерную сетку пикселей из NSImage через быстрый аппаратно-ускоренный рендеринг
    private static func samplePixels(from image: NSImage, count: Int) -> [(Double, Double, Double)]? {
        let side = max(8, Int(ceil(Double(count).squareRoot())))
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: side,
            pixelsHigh: side,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: side * 4,
            bitsPerPixel: 32
        ) else { return nil }
        
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        NSGraphicsContext.current = context
        image.draw(
            in: NSRect(x: 0, y: 0, width: side, height: side),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()
        
        guard let data = rep.bitmapData else { return nil }
        var pixels: [(Double, Double, Double)] = []
        pixels.reserveCapacity(side * side)
        for i in 0..<(side * side) {
            let offset = i * 4
            pixels.append((
                Double(data[offset]) / 255.0,
                Double(data[offset + 1]) / 255.0,
                Double(data[offset + 2]) / 255.0
            ))
        }
        return pixels.isEmpty ? nil : pixels
    }
    
    private static func dist(_ a: (Double,Double,Double), _ b: (Double,Double,Double)) -> Double {
        let dr = a.0 - b.0; let dg = a.1 - b.1; let db = a.2 - b.2
        return dr*dr + dg*dg + db*db
    }
    
    private static func saturation(_ c: (Double,Double,Double)) -> Double {
        let maxC = max(c.0, max(c.1, c.2))
        let minC = min(c.0, min(c.1, c.2))
        return maxC > 0 ? (maxC - minC) / maxC : 0
    }
    
    /// Повышает насыщенность в цветовом пространстве HSB, устраняя серые и белесые оттенки
    private static func boosted(r: Double, g: Double, b: Double) -> Color? {
        let maxVal = max(r, max(g, b))
        let minVal = min(r, min(g, b))
        guard maxVal > 0.04 else { return nil }
        
        let delta = maxVal - minVal
        let sat = maxVal > 0 ? (delta / maxVal) : 0.0
        
        var hue: Double = 0.0
        if delta > 0.0001 {
            if maxVal == r {
                hue = (g - b) / delta + (g < b ? 6.0 : 0.0)
            } else if maxVal == g {
                hue = (b - r) / delta + 2.0
            } else {
                hue = (r - g) / delta + 4.0
            }
            hue /= 6.0
        }
        
        // Для цветных пикселей гарантируем насыщенность не менее 70%, чтобы свечение не вымывалось в белый цвет
        let boostedSat = sat > 0.08 ? min(1.0, max(0.72, sat * 1.45)) : sat
        let boostedBri = min(1.0, max(0.85, maxVal * 1.20))
        
        return Color(hue: hue, saturation: boostedSat, brightness: boostedBri)
    }
}
