import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @EnvironmentObject var music: MusicController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Верхняя строка
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.accent)
                    Text("Λ U R Λ")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(Theme.accentGradient)
                }
                Spacer()
                HStack(spacing: 5) {
                    if music.playing && music.settings.audioReactive {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Theme.green)
                                .frame(width: 5, height: 5)
                            Text("\(Int(AudioAnalysisService.shared.currentBPM)) BPM")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.green)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.green.opacity(0.12), in: Capsule())
                    }
                    Text(music.source.localizedName)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Информация о текущем треке
            HStack(spacing: 12) {
                AlbumImage(image: music.artwork ?? music.fallback)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(music.title)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                    Text(music.artist)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Кнопка Лайка (Last.fm Loved Track)
                Button {
                    music.toggleLike()
                } label: {
                    Image(systemName: music.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(music.isLiked ? Theme.magenta : .secondary)
                        .shadow(color: music.isLiked ? Theme.magenta.opacity(0.7) : .clear, radius: 4)
                        .frame(width: 28, height: 28)
                        .background(music.isLiked ? Theme.magenta.opacity(0.18) : Color.white.opacity(0.05), in: Circle())
                }
                .buttonStyle(.plain)
                .help(music.isLiked ? L10n.inFavorites : L10n.addToFavorites)
                
                Button {
                    music.toggle()
                } label: {
                    Image(systemName: music.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 13))
                        .frame(width: 30, height: 30)
                        .background(Theme.green, in: Circle())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            
            // Навигация по трекам
            HStack {
                Button {
                    music.skip(-1)
                } label: {
                    Label(L10n.current == .ru ? "Предыдущий" : "Previous", systemImage: "backward.fill")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    music.skip(1)
                } label: {
                    Label(L10n.current == .ru ? "Следующий" : "Next", systemImage: "forward.fill")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.secondary)
            
            Divider()
            
            // Быстрое переключение источников
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.menuBarSources)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(Source.allCases) { src in
                        let isSelected = (music.source == src)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                music.select(src)
                            }
                        } label: {
                            HStack(spacing: 3) {
                                SourceIconView(source: src, size: 10)
                                Text(src.shortLocalizedName)
                                    .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSelected ? Theme.accent.opacity(0.18) : Theme.cardBackground,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(isSelected ? Theme.accent.opacity(0.5) : Theme.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isSelected ? Theme.textPrimary : .secondary)
                        .help(src.localizedName)
                    }
                }
            }
            
            Divider()
            
            // Действия
            HStack {
                Button(WindowCloseHandler.shared.isWindowVisible ? L10n.hideWindow : L10n.openWindow) {
                    if WindowCloseHandler.shared.isWindowVisible {
                        WindowCloseHandler.shared.hideMainWindow()
                    } else {
                        WindowCloseHandler.shared.showMainWindow()
                    }
                }
                .font(.system(size: 11, weight: .medium))
                
                Spacer()
                
                Button(L10n.quitAura) {
                    WallpaperCoordinator.shared.restore()
                    NSApp.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 250)
    }
}
