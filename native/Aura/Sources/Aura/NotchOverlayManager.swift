import AppKit
import SwiftUI
import Combine

// MARK: - Пользовательский NSHostingView с избирательным hitTest
// Пропускает клики мыши сквозь окно в менюбар, если они не приходятся на область челки/HUD
final class NotchInteractiveHostingView<Content: View>: NSHostingView<Content> {
    var interactiveBoundsProvider: (() -> CGRect)?
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let bounds = interactiveBoundsProvider?() else {
            return nil
        }
        if bounds.contains(point) {
            return super.hitTest(point)
        }
        return nil
    }
}

// MARK: - Менеджер оверлея Notch Glow & Dynamic Island
@MainActor final class NotchOverlayManager: ObservableObject {
    static let shared = NotchOverlayManager()
    
    private var window: NSWindow?
    private weak var musicController: MusicController?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isHovered: Bool = false
    @Published var isTemporarilyExpanded: Bool = false
    
    private var trackChangeTimer: Timer?
    private var currentTrackId: String = ""
    
    private init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.reconfigureWindow()
            }
        }
    }
    
    func start(with music: MusicController) {
        self.musicController = music
        
        // Отслеживаем смену трека для временного раскрытия Dynamic Island
        music.$title
            .combineLatest(music.$artist)
            .sink { [weak self] newTitle, newArtist in
                let newId = "\(newTitle):\(newArtist)"
                guard let self = self, newId != self.currentTrackId else { return }
                self.currentTrackId = newId
                self.handleTrackChanged()
            }
            .store(in: &cancellables)
        
        updateOverlayState()
    }
    
    func handleTrackChanged() {
        guard let music = musicController,
              music.playing,
              music.settings.notchGlow,
              music.settings.notchHUDOnTrackChange else { return }
        
        trackChangeTimer?.invalidate()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.isTemporarilyExpanded = true
        }
        
        trackChangeTimer = Timer.scheduledTimer(withTimeInterval: 3.8, repeats: false) { [weak self] _ in
            Task { @MainActor in
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    self?.isTemporarilyExpanded = false
                }
            }
        }
    }
    
    func updateOverlayState() {
        guard let music = musicController else {
            closeAll()
            return
        }
        
        let needsNotch = music.playing && music.activePlayerName != nil && music.settings.notchGlow
        if needsNotch {
            if window == nil {
                reconfigureWindow()
            }
        } else {
            closeAll()
        }
    }
    
    func reconfigureWindow() {
        closeAll()
        guard let music = musicController else { return }
        guard music.playing && music.activePlayerName != nil && music.settings.notchGlow else { return }
        guard let screen = NotchGeometryHelper.activeNotchScreen() else { return }
        
        let notch = NotchGeometryHelper.notchInfo(for: screen)
        let windowHeight: CGFloat = 160.0
        
        let windowRect = CGRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - windowHeight,
            width: screen.frame.width,
            height: windowHeight
        )
        
        let newWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        // Размещаем окно над системной строкой меню
        newWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.hasShadow = false
        newWindow.isExcludedFromWindowsMenu = true
        newWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        
        let contentView = NotchGlowViewWrapper(
            music: music,
            notch: notch,
            manager: self
        )
        
        let hostingView = NotchInteractiveHostingView(rootView: contentView)
        hostingView.frame = CGRect(origin: .zero, size: windowRect.size)
        hostingView.autoresizingMask = [.width, .height]
        
        // Определение интерактивной зоны (область челки и Dynamic Island)
        hostingView.interactiveBoundsProvider = { [weak self, weak hostingView] in
            guard let self = self, let view = hostingView else { return .zero }
            let centerX = notch.centerX
            let isExp = self.isHovered || self.isTemporarilyExpanded
            let width: CGFloat = isExp ? 420.0 : (notch.width + 40.0)
            let height: CGFloat = isExp ? 84.0 : (notch.height + 20.0)
            
            // В AppKit (0,0) внизу вью, поэтому верхний край равен view.bounds.height
            let y = view.bounds.height - height
            let x = centerX - (width / 2.0)
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        newWindow.contentView = hostingView
        newWindow.orderFrontRegardless()
        self.window = newWindow
    }
    
    func closeAll() {
        trackChangeTimer?.invalidate()
        trackChangeTimer = nil
        isTemporarilyExpanded = false
        isHovered = false
        window?.orderOut(nil)
        window = nil
    }
}

// MARK: - SwiftUI Обертка для передачи состояния из менеджера
private struct NotchGlowViewWrapper: View {
    @ObservedObject var music: MusicController
    let notch: NotchInfo
    @ObservedObject var manager: NotchOverlayManager
    
    var body: some View {
        NotchGlowView(
            music: music,
            notch: notch,
            isHovered: manager.isHovered,
            isTemporarilyExpanded: manager.isTemporarilyExpanded,
            onHoverChanged: { hovering in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    manager.isHovered = hovering
                }
            }
        )
    }
}
