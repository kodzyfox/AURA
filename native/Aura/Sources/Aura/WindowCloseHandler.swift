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

final class WindowCloseHandler: NSObject, NSWindowDelegate {
    static let shared = WindowCloseHandler()

    // Удерживаем сильную ссылку на главное окно, чтобы AppKit/SwiftUI не удаляли его из памяти
    var mainWindow: NSWindow?

    var isWindowVisible: Bool {
        guard let window = mainWindow else { return false }
        return window.isVisible
    }

    func setup(window: NSWindow) {
        guard isCandidate(window) else { return }
        self.mainWindow = window
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
            updateDockVisibility()
            return false
        case .minimizeToDock:
            sender.miniaturize(nil)
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
            return
        }

        // Если окно ещё не было захвачено, ищем его среди окон приложения
        if let window = NSApp.windows.first(where: { isCandidate($0) }) {
            self.setup(window: window)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
    }

    func hideMainWindow() {
        mainWindow?.orderOut(nil)
        updateDockVisibility()
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
