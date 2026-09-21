import SwiftUI
import ServiceManagement

@MainActor
public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()
    
    private static let userDefaultsKey = "aura.launchAtLogin"
    
    @Published public var isEnabled: Bool = false
    
    private init() {
        refresh()
    }
    
    public func refresh() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            if status == .enabled {
                self.isEnabled = true
            } else if status == .notRegistered {
                self.isEnabled = false
            } else {
                // Fallback to saved preference if unbundled / development build
                self.isEnabled = UserDefaults.standard.bool(forKey: Self.userDefaultsKey)
            }
        } else {
            self.isEnabled = UserDefaults.standard.bool(forKey: Self.userDefaultsKey)
        }
    }
    
    public func toggle(enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.userDefaultsKey)
        
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("[LaunchAtLogin] Error updating SMAppService: \(error.localizedDescription)")
            }
            refresh()
        }
    }
}
