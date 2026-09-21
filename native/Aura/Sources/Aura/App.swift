import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var didFinishInitialLaunch = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconUrl = Bundle.main.url(forResource: "AppIcon", withExtension: "png") ?? Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let img = NSImage(contentsOf: iconUrl) {
            NSApp.applicationIconImage = img
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.didFinishInitialLaunch = true
            LaunchAtLoginManager.shared.refresh()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let backgroundMode = UserDefaults.standard.object(forKey: "aura.backgroundMode") as? Bool ?? true
        return !backgroundMode
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WindowCloseHandler.shared.showMainWindow()
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        guard didFinishInitialLaunch else { return }
        if !WindowCloseHandler.shared.isWindowVisible {
            WindowCloseHandler.shared.showMainWindow()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Мгновенный возврат исходных обоев и закрытие оверлеев
        DesktopOverlayManager.shared.closeAll()
        WallpaperCoordinator.shared.restore()
    }
}

@main struct AuraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var music = MusicController()
    @ObservedObject private var l10n = LocalizationManager.shared
    @AppStorage("aura.appearance") private var appearance: Appearance = .system
    
    var body: some Scene {
        WindowGroup("aura") {
            ContentView()
                .environmentObject(music)
                .frame(
                    minWidth: music.isMiniPlayer ? 280 : 1020,
                    maxWidth: music.isMiniPlayer ? 320 : .infinity,
                    minHeight: music.isMiniPlayer ? 320 : 740,
                    maxHeight: music.isMiniPlayer ? 360 : .infinity
                )
                .tint(Theme.accent)
                .preferredColorScheme(appearance.colorScheme)
                .background(
                    WindowAccessor { window in
                        WindowCloseHandler.shared.setup(window: window)
                    }
                )
                .onAppear {
                    DesktopOverlayManager.shared.start(with: music)
                }
                .onOpenURL { url in
                    music.handleURL(url)
                }
        }
        .defaultSize(width: 1280, height: 860)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(L10n.aboutAura) {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "by Kodzy"
                        ]
                    )
                }
            }
            
            CommandGroup(replacing: .newItem) {
                Button(L10n.openAudioFiles) {
                    music.openFiles()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
            CommandMenu(L10n.menuPlayback) {
                Button(music.playing ? L10n.menuPause : L10n.menuPlay) {
                    music.toggle()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button(L10n.menuNext) {
                    music.skip(1)
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
                
                Button(L10n.menuPrevious) {
                    music.skip(-1)
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)
                
                Divider()
                
                ForEach(Source.allCases) { source in
                    Button(source.localizedName) {
                        music.select(source)
                    }
                }
            }
            
            CommandMenu(L10n.menuView) {
                Button(music.isMiniPlayer ? L10n.menuNormalMode : L10n.menuMiniPlayerAlwaysOnTop) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        music.toggleMiniPlayer()
                    }
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                Button(music.isCoverMode ? L10n.menuNormalMode : L10n.menuFullscreenCover) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        music.toggleCoverMode()
                    }
                }
                .keyboardShortcut("f", modifiers: [.control, .command])
                
                Divider()
                
                Picker(L10n.menuTheme, selection: $appearance) {
                    ForEach(Appearance.allCases) { app in
                        Text(app.localizedName).tag(app)
                    }
                }
                
                Picker(L10n.menuLanguage, selection: Binding(
                    get: { l10n.language },
                    set: { l10n.setLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.title).tag(lang)
                    }
                }
            }
        }
        
        // Интеграция со строкой меню macOS
        MenuBarExtra("Aura", systemImage: "waveform") {
            MenuBarView()
                .environmentObject(music)
        }
        .menuBarExtraStyle(.window)
    }
}
