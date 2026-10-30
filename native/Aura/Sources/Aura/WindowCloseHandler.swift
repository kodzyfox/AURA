import SwiftUI
import AppKit

public enum WindowCloseBehavior: String, CaseIterable, Identifiable, Codable {
    case hideToMenuBar = "hideToMenuBar"
    case minimizeToDock = "minimizeToDock"
    case quitApp = "quitApp"

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch (self, L10n.current) {
        case (.hideToMenuBar, .ru): return "Работать в строке меню"
        case (.hideToMenuBar, .en): return "Keep in Menu Bar"
        case (.minimizeToDock, .ru): return "Сворачивать в Dock"
        case (.minimizeToDock, .en): return "Minimize to Dock"
        case (.quitApp, .ru): return "Завершать приложение"
        case (.quitApp, .en): return "Quit Application"
        }
    }

    public var localizedName: String {
        localizedTitle
    }
}

final class WindowCloseHandler: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = WindowCloseHandler()

    // Удерживаем сильную ссылку на главное окно, чтобы AppKit/SwiftUI не удаляли его из памяти
    var mainWindow: NSWindow?

    @Published var isWindowVisible: Bool = true
    @Published var isWindowOccluded: Bool = false

    /// Окно реально видно пользователю на текущем экране (не свернуто, не скрыто и не перекрыто другими окнами на 100%)
    var isWindowEffectivelyVisible: Bool {
        isWindowVisible && !isWindowOccluded
    }

    func setup(window: NSWindow) {
        guard isCandidate(window) else { return }
        self.mainWindow = window
        self.isWindowVisible = window.isVisible && !window.isMiniaturized
        self.isWindowOccluded = !window.occlusionState.contains(.visible)
        window.isReleasedWhenClosed = false
        window.delegate = self

        // При наличии видимого окна гарантируем стандартный режим в Dock
        NSApp.setActivationPolicy(.regular)
    }

    private func isCandidate(_ window: NSWindow) -> Bool {
        return window.level == .normal &&
               window.styleMask.contains(.titled) &&
               !(window is NSPanel)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let raw = UserDefaults.standard.string(forKey: "aura.windowCloseBehavior") ?? WindowCloseBehavior.hideToMenuBar.rawValue
        let behavior = WindowCloseBehavior(rawValue: raw) ?? .hideToMenuBar

        switch behavior {
        case .hideToMenuBar:
            sender.orderOut(nil)
            isWindowVisible = false
            updateDockVisibility()
            return false
        case .minimizeToDock:
            sender.miniaturize(nil)
            isWindowVisible = false
            return false
        case .quitApp:
            WallpaperCoordinator.shared.restore()
            NSApp.terminate(nil)
            return true
        }
    }

    func showMainWindow() {
        // Возвращаем приложение в стандартный режим с иконкой в Dock
        NSApp.setActivationPolicy(.regular)

        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            isWindowVisible = true
            isWindowOccluded = !window.occlusionState.contains(.visible)
            return
        }

        // Если окно ещё не было захвачено, ищем его среди окон приложения
        if let window = NSApp.windows.first(where: { isCandidate($0) }) {
            self.setup(window: window)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            isWindowVisible = true
            isWindowOccluded = !window.occlusionState.contains(.visible)
            return
        }
    }

    func hideMainWindow() {
        mainWindow?.orderOut(nil)
        isWindowVisible = false
        isWindowOccluded = true
        updateDockVisibility()
    }

    func windowDidMiniaturize(_ notification: Notification) {
        isWindowVisible = false
        isWindowOccluded = true
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        isWindowVisible = true
        if let win = mainWindow {
            isWindowOccluded = !win.occlusionState.contains(.visible)
        }
    }

    func windowDidChangeOcclusionState(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, isCandidate(window) else { return }
        let occluded = !window.occlusionState.contains(.visible)
        if self.isWindowOccluded != occluded {
            self.isWindowOccluded = occluded
        }
    }

    func updateDockVisibility() {
        let raw = UserDefaults.standard.string(forKey: "aura.windowCloseBehavior") ?? WindowCloseBehavior.hideToMenuBar.rawValue
        let behavior = WindowCloseBehavior(rawValue: raw) ?? .hideToMenuBar

        let hideFromDock = UserDefaults.standard.bool(forKey: "aura.hideFromDock")
        if behavior == .hideToMenuBar && hideFromDock && !isWindowVisible {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
    }
}

// Гарантированный захват окна через viewDidMoveToWindow без задержек и гонок таймеров
final class WindowObservingView: NSView {
    var onWindowAttached: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            onWindowAttached?(window)
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> WindowObservingView {
        let view = WindowObservingView()
        view.onWindowAttached = callback
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: WindowObservingView, context: Context) {
        nsView.onWindowAttached = callback
        if let window = nsView.window {
            callback(window)
        }
    }
}
