import SwiftUI
import AppKit

struct MiniPlayerView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @EnvironmentObject var music: MusicController
    @State private var isHovering = false

    var body: some View {
        ZStack {
            // Фон с кинематографичным размытием обложки
            Theme.background.ignoresSafeArea()

            if let artwork = music.artwork ?? music.fallback {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 40)
                    .opacity(0.38)
                    .scaleEffect(1.25)
                    .ignoresSafeArea()
            }

            VStack(spacing: 10) {
                // Верхняя плашка: Источник + Режим анализа + Кнопка разворота
                HStack(spacing: 8) {
                    // Бейдж источника
                    HStack(spacing: 5) {
                        SourceIconView(source: music.source, size: 10)
                        Text((music.activePlayerName ?? music.source.localizedName).uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.cardBackground, in: Capsule())
                    .overlay(Capsule().strokeBorder(Theme.cardBorder))

                    // Индикатор анализа
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AudioAnalysisService.shared.analysisMode.color)
                            .frame(width: 5, height: 5)
                        Text(AudioAnalysisService.shared.analysisMode.badgeTitle)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            music.toggleMiniPlayer()
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(6)
                            .background(Theme.cardBackground.opacity(0.6), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help(L10n.current == .ru ? "Развернуть главное окно" : "Expand Window")
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                // Центральная обложка с мягким свечением
                ZStack {
                    let glow = music.artworkColor ?? Theme.accent
                    Circle()
                        .fill(glow.opacity(0.45 * music.settings.intensity))
                        .frame(width: 145, height: 145)
                        .blur(radius: 22)
                        .scaleEffect(music.playing ? 1.06 : 0.95)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: music.playing)

                    AlbumImage(image: music.artwork ?? music.fallback)
                        .frame(width: 135, height: 135)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.4), radius: 14, y: 7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .padding(.vertical, 2)

                // Название трека и артист
                VStack(spacing: 2) {
                    Text(music.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    Text(music.artist)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)

                // Прогресс воспроизведения
                HStack(spacing: 6) {
                    Text(timestamp(music.position))
                    Slider(
                        value: Binding(
                            get: { min(music.position, max(1, music.duration)) },
                            set: { music.seek($0) }
                        ),
                        in: 0...max(1, music.duration)
                    )
                    .controlSize(.mini)
                    .tint(music.artworkColor ?? Theme.accent)
                    Text(timestamp(music.duration))
                }
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 14)

                // Кнопки управления и громкость
                HStack(spacing: 12) {
                    // Mute / Громкость
                    Button {
                        music.toggleMute()
                    } label: {
                        Image(systemName: music.isMuted || music.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(music.isMuted ? Theme.orange : Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help(music.isMuted ? (L10n.current == .ru ? "Включить звук" : "Unmute") : (L10n.current == .ru ? "Заглушить звук" : "Mute"))

                    Slider(value: $music.volume)
                        .frame(width: 48)
                        .controlSize(.mini)

                    Spacer()

                    // Управление плеером
                    HStack(spacing: 14) {
                        Button { music.skip(-1) } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)

                        Button { music.toggle() } label: {
                            Image(systemName: music.playing ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(Theme.green)
                        }
                        .buttonStyle(.plain)

                        Button { music.skip(1) } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)

                        Button { music.toggleLike() } label: {
                            Image(systemName: music.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundStyle(music.isLiked ? Theme.magenta : Theme.textTertiary)
                                .shadow(color: music.isLiked ? Theme.magenta.opacity(0.6) : .clear, radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .frame(minWidth: 270, minHeight: 310)
    }

    private func timestamp(_ seconds: Double) -> String {
        let s = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
