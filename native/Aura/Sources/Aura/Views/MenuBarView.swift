import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @EnvironmentObject var music: MusicController
    @ObservedObject var lastfm = LastFMService.shared

    private let lastFMRed = Color(red: 0.88, green: 0.12, blue: 0.15)
    private let panelWidth: CGFloat = 315
    private var panelHeight: CGFloat {
        music.isScrobbleMode ? 200 : 355
    }

    var body: some View {
        Group {
            if music.isScrobbleMode {
                scrobbleModePanel
            } else {
                normalPanel
            }
        }
        .frame(width: panelWidth, height: panelHeight, alignment: .top)
        .background(
            WindowAccessor { window in
                guard window.frame.width > 50 && window.frame.height > 50 else { return }
                let targetSize = NSSize(width: panelWidth, height: panelHeight)
                if abs(window.frame.width - targetSize.width) > 1 || abs(window.frame.height - targetSize.height) > 1 {
                    let newOriginY = window.frame.maxY - targetSize.height
                    window.setFrame(
                        NSRect(x: window.frame.minX, y: newOriginY, width: targetSize.width, height: targetSize.height),
                        display: true,
                        animate: false
                    )
                }
            }
        )
    }

    // MARK: - Scrobble Mode Panel
    private var scrobbleModePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок: эко-режим
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.green)
                    Text(L10n.current == .ru ? "Режим скроблинга" : "Scrobble Mode")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.green.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.green.opacity(0.3), lineWidth: 1))

                Spacer()

                // Индикатор состояния Last.fm
                if lastfm.isConnected {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.green).frame(width: 5, height: 5)
                        Text(lastfm.username)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.yellow).frame(width: 5, height: 5)
                        Text(L10n.current == .ru ? "Не подключено" : "Not connected")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.yellow)
                    }
                }
            }

            Divider().opacity(0.4)

            // Текущий трек
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // Индикатор воспроизведения
                    Circle()
                        .fill(music.playing ? Theme.green : Theme.textTertiary)
                        .frame(width: 7, height: 7)
                        .shadow(color: music.playing ? Theme.green.opacity(0.6) : .clear, radius: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(music.title.isEmpty ? (L10n.current == .ru ? "Ожидание музыки..." : "Waiting for music...") : music.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        Text(music.artist.isEmpty ? "—" : music.artist)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Кнопка паузы/воспроизведения
                    Button { music.toggle() } label: {
                        Image(systemName: music.playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 11))
                            .frame(width: 26, height: 26)
                            .background(Theme.green, in: Circle())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }

                // Прогресс скробблинга
                if music.duration > 0 {
                    let duration = max(1.0, music.duration)
                    let position = min(duration, max(0.0, music.position))
                    let progress = min(1.0, position / duration)
                    let threshold = min(1.0, music.scrobbleThresholdSeconds / duration)
                    let isScrobbled = music.hasScrobbledCurrentTrack

                    VStack(spacing: 3) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isScrobbled ? Theme.green : Theme.accent)
                                    .frame(width: max(0, geo.size.width * progress), height: 4)

                                // Маркер порога скробблинга
                                Rectangle()
                                    .fill(isScrobbled ? Theme.green.opacity(0.5) : lastFMRed)
                                    .frame(width: 2, height: 7)
                                    .offset(x: max(0, min(geo.size.width - 2, geo.size.width * threshold)))
                            }
                        }
                        .frame(height: 7)

                        HStack {
                            Text(formatTime(position))
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.textTertiary)

                            Spacer()

                            if isScrobbled {
                                HStack(spacing: 3) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 8))
                                    Text(L10n.current == .ru ? "Отправлен" : "Scrobbled")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundStyle(Theme.green)
                            } else if music.playing && music.duration >= 30 {
                                let remaining = max(0, Int(music.scrobbleThresholdSeconds - music.position))
                                Text(L10n.current == .ru ? "Через \(remaining)с" : "In \(remaining)s")
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Theme.accent)
                            }

                            Spacer()

                            Text(formatTime(duration))
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }

            Divider().opacity(0.4)

            // Кнопки управления
            HStack(spacing: 8) {
                // Выйти из режима скроблинга
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        music.toggleScrobbleMode()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 10, weight: .semibold))
                        Text(L10n.current == .ru ? "Выйти из эко-режима" : "Exit Eco Mode")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Theme.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.green.opacity(0.4), lineWidth: 1))
                    .foregroundStyle(Theme.green)
                }
                .buttonStyle(.plain)

                // Закрыть
                Button(L10n.quitAura) {
                    WallpaperCoordinator.shared.restore()
                    NSApp.terminate(nil)
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    // MARK: - Normal Panel
    private var normalPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Верхняя строка
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accent)
                    Text("Λ U R Λ")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(Theme.accentGradient)
                }
                Spacer()
                HStack(spacing: 6) {
                    if music.playing && music.settings.audioReactive {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Theme.green)
                                .frame(width: 5, height: 5)
                            Text("\(Int(AudioAnalysisService.shared.currentBPM)) BPM")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.green.opacity(0.12), in: Capsule())
                    }
                    Text(music.source.localizedName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Divider().opacity(0.4)

            // Информация о текущем треке
            HStack(spacing: 12) {
                AlbumImage(image: music.artwork ?? music.fallback)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(music.title.isEmpty ? (L10n.current == .ru ? "Ожидание музыки..." : "Waiting for music...") : music.title)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                    Text(music.artist.isEmpty ? "—" : music.artist)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // Кнопка Лайка (Last.fm Loved Track)
                Button {
                    music.toggleLike()
                } label: {
                    Image(systemName: music.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(music.isLiked ? Theme.magenta : .secondary)
                        .shadow(color: music.isLiked ? Theme.magenta.opacity(0.7) : .clear, radius: 4)
                        .frame(width: 28, height: 28)
                        .background(music.isLiked ? Theme.magenta.opacity(0.18) : Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .help(music.isLiked ? L10n.inFavorites : L10n.addToFavorites)

                Button {
                    music.toggle()
                } label: {
                    Image(systemName: music.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Theme.green, in: Circle())
                        .foregroundStyle(.white)
                        .shadow(color: Theme.green.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }

            // Навигация по трекам
            HStack {
                Button {
                    music.skip(-1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 9))
                        Text(L10n.current == .ru ? "Предыдущий" : "Previous")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    music.skip(1)
                } label: {
                    HStack(spacing: 4) {
                        Text(L10n.current == .ru ? "Следующий" : "Next")
                            .font(.system(size: 10, weight: .medium))
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.secondary)

            Divider().opacity(0.4)

            // Быстрое переключение источников
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.menuBarSources)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 4), spacing: 5) {
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
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, minHeight: 24)
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

            Divider().opacity(0.4)

            // Быстрый режим скроблинга (Эко)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    music.toggleScrobbleMode()
                }
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(music.isScrobbleMode ? Theme.green.opacity(0.2) : Color.white.opacity(0.08))
                            .frame(width: 24, height: 24)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(music.isScrobbleMode ? Theme.green : Theme.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(music.isScrobbleMode ? L10n.scrobbleModeActive : L10n.scrobbleMode)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(music.isScrobbleMode ? Theme.green : Theme.textPrimary)
                        Text(L10n.current == .ru ? "Экономичный режим Last.fm" : "Eco Last.fm scrobbler")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if music.isScrobbleMode {
                        Text(L10n.current == .ru ? "Эко" : "Eco")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.green.opacity(0.2), in: Capsule())
                            .foregroundStyle(Theme.green)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    music.isScrobbleMode ? Theme.green.opacity(0.12) : Color.white.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(music.isScrobbleMode ? Theme.green.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help(L10n.scrobbleModeSubtitle)

            Divider().opacity(0.4)

            // Действия
            HStack {
                Button {
                    if WindowCloseHandler.shared.isWindowVisible {
                        WindowCloseHandler.shared.hideMainWindow()
                    } else {
                        WindowCloseHandler.shared.showMainWindow()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: WindowCloseHandler.shared.isWindowVisible ? "eye.slash" : "macwindow")
                            .font(.system(size: 10))
                        Text(WindowCloseHandler.shared.isWindowVisible ? L10n.hideWindow : L10n.openWindow)
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textSecondary)

                Spacer()

                Button {
                    WallpaperCoordinator.shared.restore()
                    NSApp.terminate(nil)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 9))
                        Text(L10n.quitAura)
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = seconds.isFinite ? max(0, Int(seconds)) : 0
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
}
