import AppKit
import Combine
import Foundation
import IOKit.ps

enum VisualQuality: String, CaseIterable, Identifiable, Codable {
    case automatic
    case high
    case balanced
    case low

    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .automatic: return L10n.current == .ru ? "Автоматически" : "Automatic"
        case .high: return L10n.current == .ru ? "Высокое (60 FPS)" : "High (60 FPS)"
        case .balanced: return L10n.current == .ru ? "Сбалансированное (30 FPS)" : "Balanced (30 FPS)"
        case .low: return L10n.current == .ru ? "Энергосбережение (15 FPS)" : "Power saving (15 FPS)"
        }
    }
}

@MainActor final class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()

    @Published private(set) var isLowPowerMode: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled
    @Published private(set) var thermalState: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    @Published private(set) var screenCount: Int = NSScreen.screens.count
    @Published private(set) var lastScreenChange: Date = Date()
    @Published private(set) var isOnBattery: Bool = false
    @Published private(set) var batteryPercent: Int? = nil
    @Published private(set) var isCharging: Bool = false

    @Published var quality: VisualQuality = {
        guard let raw = UserDefaults.standard.string(forKey: "aura.visualQuality") else { return .automatic }
        return VisualQuality(rawValue: raw) ?? .automatic
    }() {
        didSet { UserDefaults.standard.set(quality.rawValue, forKey: "aura.visualQuality") }
    }

    @Published var disableExpensiveEffectsOnBattery: Bool = {
        if UserDefaults.standard.object(forKey: "aura.disableExpensiveOnBattery") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "aura.disableExpensiveOnBattery")
    }() {
        didSet { UserDefaults.standard.set(disableExpensiveEffectsOnBattery, forKey: "aura.disableExpensiveOnBattery") }
    }

    private var pollTimer: Timer?

    private init() {
        NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()

        // Опрос статуса питания каждые 15 сек
        pollTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    var effectiveQuality: VisualQuality {
        if quality != .automatic { return quality }
        if isLowPowerMode || thermalState == .serious || thermalState == .critical { return .low }
        if isOnBattery && disableExpensiveEffectsOnBattery {
            if let pct = batteryPercent, pct <= 20 {
                return .low
            }
            return .balanced
        }
        if screenCount > 1 { return .balanced }
        return .high
    }

    var overlayFrameInterval: Double {
        switch effectiveQuality {
        case .high: return 1.0 / 60.0
        case .balanced: return 1.0 / 30.0
        case .low: return 1.0 / 15.0
        case .automatic: return 1.0 / 30.0
        }
    }

    var targetFPS: Int {
        Int(round(1.0 / overlayFrameInterval))
    }

    var wallpaperPixelScale: CGFloat {
        switch effectiveQuality {
        case .high: return 1.0
        case .balanced: return 0.82
        case .low: return 0.62
        case .automatic: return 0.82
        }
    }

    var shouldUseExpensiveEffects: Bool {
        if isOnBattery && disableExpensiveEffectsOnBattery {
            return false
        }
        return effectiveQuality == .high
    }

    var powerSourceDescription: String {
        if isOnBattery {
            let pctStr = batteryPercent.map { "\($0)%" } ?? ""
            let prefix = L10n.current == .ru ? "Батарея" : "Battery"
            return pctStr.isEmpty ? prefix : "\(prefix) (\(pctStr))"
        } else {
            let chgStr = isCharging ? (L10n.current == .ru ? " · Зарядка" : " · Charging") : ""
            let prefix = L10n.current == .ru ? "Сеть (AC)" : "Power Adapter"
            return "\(prefix)\(chgStr)"
        }
    }

    var thermalStateDescription: String {
        switch thermalState {
        case .nominal: return L10n.current == .ru ? "В норме" : "Nominal"
        case .fair: return L10n.current == .ru ? "Умеренный нагрев" : "Fair"
        case .serious: return L10n.current == .ru ? "Высокий нагрев" : "Serious"
        case .critical: return L10n.current == .ru ? "Критический перегрев" : "Critical"
        @unknown default: return "Unknown"
        }
    }

    var screensDescription: String {
        let suffix = L10n.current == .ru ? (screenCount == 1 ? "экран" : (screenCount < 5 ? "экрана" : "экранов")) : (screenCount == 1 ? "display" : "displays")
        return "\(screenCount) \(suffix)"
    }

    var diagnosticSummary: String {
        "\(effectiveQuality.localizedName) · \(targetFPS) FPS · \(screensDescription) · \(powerSourceDescription) · \(thermalStateDescription)"
    }

    func refresh() {
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        thermalState = ProcessInfo.processInfo.thermalState
        screenCount = NSScreen.screens.count
        lastScreenChange = Date()

        let battery = PerformanceManager.readBatteryInfo()
        isOnBattery = battery.isOnBattery
        batteryPercent = battery.percent
        isCharging = battery.isCharging
    }

    private static func readBatteryInfo() -> (isOnBattery: Bool, percent: Int?, isCharging: Bool) {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return (false, nil, false)
        }
        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] {
                let state = desc[kIOPSPowerSourceStateKey] as? String
                let isOnBattery = (state == kIOPSBatteryPowerValue)
                let current = desc[kIOPSCurrentCapacityKey] as? Int
                let maxCap = desc[kIOPSMaxCapacityKey] as? Int
                let isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
                var percent: Int? = nil
                if let current = current, let maxCap = maxCap, maxCap > 0 {
                    percent = Int((Double(current) / Double(maxCap)) * 100.0)
                }
                return (isOnBattery, percent, isCharging)
            }
        }
        return (false, nil, false)
    }
}
