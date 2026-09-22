import SwiftUI
import AppKit

struct SidebarView: View {
    @EnvironmentObject var music: MusicController
    @ObservedObject private var l10n = LocalizationManager.shared
    @ObservedObject private var updater = UpdateManager.shared
    @Binding var section: NavigationSection
    
    private var appIconImage: NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let img = NSImage(named: "AppIcon") {
            return img
        }
        let fallbackPath = "Resources/AppIcon.png"
        if FileManager.default.fileExists(atPath: fallbackPath) {
            return NSImage(contentsOfFile: fallbackPath)
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Фиксированная шапка сайдбара: чистый отступ под кнопки окна macOS + логотип Aura
            VStack(alignment: .leading, spacing: 8) {
                // Выделенная зона под кнопки окна macOS (Traffic lights)
                Color.clear
                    .frame(height: 28)
                
                // Логотип приложения в точности по стилю фирменной иконки
                HStack(spacing: 12) {
                    if let icon = appIconImage {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: Theme.accent.opacity(0.4), radius: 6, x: 0, y: 0)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.accentGradient)
                    }
                    
                    Text("Λ U R Λ")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .tracking(4.5)
                        .foregroundStyle(Theme.accentGradient)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.yourSpace)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 2)
                    
                    ForEach(NavigationSection.allCases) { item in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { section = item }
                        } label: {
                            HStack(spacing: 8) {
                                Label(item.localizedTitle, systemImage: item.symbol)
                                    .font(.system(size: 12, weight: section == item ? .semibold : .regular))
                                Spacer()
                                if item == .settings && updater.updateAvailable {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 7, height: 7)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                section == item ? Theme.accent.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(section == item ? Theme.accent : Theme.textSecondary)
                        .padding(.horizontal, 6)
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    Text(L10n.nowInAura)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 14)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(music.playing ? Theme.green : Theme.textTertiary)
                            .frame(width: 7, height: 7)
                        Text(music.playing ? L10n.playback : L10n.paused)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    
                    Divider().padding(.vertical, 6)
                    
                    Toggle(isOn: $music.dynamicWallpaperEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.wallpaperFromMusic)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.wallpaperSub)
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .padding(.horizontal, 14)
                    .help(L10n.current == .ru ? "Автоматически ставить обложку текущего трека на обои и экран блокировки Mac" : "Automatically set current track artwork as desktop and lock screen wallpaper")
                    
                    if music.dynamicWallpaperEnabled {
                        Picker(L10n.wallpaperStyle, selection: $music.wallpaperStyle) {
                            ForEach(WallpaperStyle.allCases) { style in
                                Label(style.localizedName, systemImage: style.symbol).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .controlSize(.small)
                        .padding(.horizontal, 14)
                        .padding(.top, 2)
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    // Заставка на весь экран
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            music.toggleCoverMode()
                        }
                    } label: {
                        Label(L10n.screensaverMode, systemImage: "sparkles.tv")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.top, 2)
                    .help(L10n.current == .ru ? "Полноэкранный плеер в стиле Lock Screen (Control+Command+F)" : "Fullscreen Lock Screen style player (Control+Command+F)")
                    
                    // Переход в мини-плеер из сайдбара
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            music.toggleMiniPlayer()
                        }
                    } label: {
                        Label(L10n.miniPlayer, systemImage: "pip")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
                    .help(L10n.current == .ru ? "Компактный режим Always on Top (Cmd+Shift+M)" : "Compact Always on Top mode (Cmd+Shift+M)")
                    
                    Divider().padding(.vertical, 8)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.green)
                        Text(L10n.current == .ru ? "Aura для macOS" : "Aura for macOS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 260)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.sidebarBackground)
    }
}
