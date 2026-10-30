import SwiftUI
import AppKit
import Combine

/// Энергоэффективный режим скроблинга.
/// В этом режиме полностью отключены обложки, свечения, оверлеи и тяжелые шейдеры.
/// Приложение работает исключительно как ультралегкий фоновый скроблер для Last.fm,
/// не нагружая процессор, GPU и не разряжая аккумулятор MacBook.
struct ScrobbleModeView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @EnvironmentObject var music: MusicController
    @ObservedObject var lastfm = LastFMService.shared
    @ObservedObject var performance = PerformanceManager.shared

    @State private var tickDate = Date()
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let lastFMRed = Color(red: 0.88, green: 0.12, blue: 0.15)

    var body: some View {
        ZStack {
            // Сплошной минималистичный темный фон без свечений и размытия
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                // MARK: - Верхняя панель управления
                headerBar

                // MARK: - Центральная карточка трека и скробблинга (БЕЗ обложки и свечений)
                scrobbleCard

                // MARK: - Нижняя информационная карточка Last.fm и энергопотребления
                lastFMStatusCard
            }
            .padding(20)
        }
        .frame(minWidth: 440, maxWidth: 620, minHeight: 320, maxHeight: 480)
        .onReceive(timer) { date in
            tickDate = date
        }
    }

    // MARK: - Верхняя панель
    private var headerBar: some View {
        HStack(spacing: 10) {
            // Эко-бейдж режима
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.green)

                Text(L10n.scrobbleModeEcoBadge)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.green)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Theme.green.opacity(0.12), in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.green.opacity(0.3), lineWidth: 1))

            // Индикатор источника питания
            HStack(spacing: 4) {
                Image(systemName: performance.isOnBattery ? "battery.100" : "powerplug.fill")
                    .font(.system(size: 9))
                Text(performance.powerSourceDescription)
                    .font(.system(size: 9.5, weight: .medium))
            }
            .foregroundStyle(Theme.textTertiary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.04), in: Capsule())

            // Метка 0% GPU
            Text(L10n.scrobbleEcoMetrics)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)

            Spacer()

            // Кнопка возврата в обычный режим
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    music.toggleScrobbleMode()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .semibold))
                    Text(L10n.scrobbleModeExit)
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Theme.cardBorder))
            }
            .buttonStyle(.plain)
            .help(L10n.scrobbleModeExit)
        }
    }

    // MARK: - Карточка трека и скроблинга
    private var scrobbleCard: some View {
        VStack(spacing: 16) {
            // Верхняя строка: источник и статус вещания
            HStack {
                // Источник музыки
                HStack(spacing: 6) {
                    SourceIconView(source: music.source, size: 12)
                    Text((music.activePlayerName ?? music.source.localizedName).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05), in: Capsule())

                Spacer()

                // Статус вещания в Last.fm
                HStack(spacing: 6) {
                    Circle()
                        .fill(music.playing ? Theme.green : Theme.yellow)
                        .frame(width: 6, height: 6)

                    Text(music.playing
                         ? (L10n.current == .ru ? "Now Playing в Last.fm" : "Now Playing on Last.fm")
                         : (L10n.current == .ru ? "Приостановлено" : "Paused"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(music.playing ? Theme.green : Theme.yellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((music.playing ? Theme.green : Theme.yellow).opacity(0.1), in: Capsule())
            }

            // Название трека и артист (без обложки)
            VStack(spacing: 4) {
                Text(music.title.isEmpty ? L10n.waitingForMusic : music.title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                Text(music.artist.isEmpty ? "—" : music.artist)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            // Прогресс воспроизведения и порог скроблинга Last.fm
            VStack(spacing: 6) {
                // Полоса прогресса с визуальной отметкой порога скроббла
                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    let duration = max(1.0, music.duration)
                    let currentPos = min(duration, max(0.0, music.currentPlaybackPosition(at: tickDate)))
                    let progressFraction = min(1.0, currentPos / duration)
                    let thresholdFraction = min(1.0, music.scrobbleThresholdSeconds / duration)
                    let isScrobbled = music.hasScrobbledCurrentTrack

                    ZStack(alignment: .leading) {
                        // Фоновая полоса
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)

                        // Заполненный прогресс
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isScrobbled ? Theme.green : Theme.accent)
                            .frame(width: max(0, totalWidth * progressFraction), height: 6)

                        // Маркер порога скробблинга (50% длины трека или 4 минуты)
                        Rectangle()
                            .fill(isScrobbled ? Theme.green.opacity(0.6) : lastFMRed)
                            .frame(width: 2, height: 10)
                            .offset(x: max(0, min(totalWidth - 2, totalWidth * thresholdFraction)))
                    }
                }
                .frame(height: 10)

                // Время и статус достижения порога
                HStack {
                    Text(timestamp(min(music.duration, max(0.0, music.currentPlaybackPosition(at: tickDate)))))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)

                    Spacer()

                    // Статус отправки скроббла
                    HStack(spacing: 4) {
                        if music.hasScrobbledCurrentTrack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.green)
                            Text(L10n.scrobbleStatusSent)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.green)
                        } else if music.playing && music.duration >= 30.0 {
                            let currentPos = min(music.duration, max(0.0, music.currentPlaybackPosition(at: tickDate)))
                            let remaining = max(0, Int(music.scrobbleThresholdSeconds - currentPos))
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.accent)
                            Text(L10n.current == .ru
                                 ? "Скроббл через \(remaining) с (\(Int(music.scrobbleThresholdSeconds)) с)"
                                 : "Scrobble in \(remaining)s (\(Int(music.scrobbleThresholdSeconds))s)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.accent)
                        } else {
                            Text(L10n.scrobbleStatusWaiting)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }

                    Spacer()

                    Text(timestamp(music.duration))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            // Кнопки управления воспроизведением
            HStack(spacing: 18) {
                // Лайк (Last.fm Loved Track)
                Button {
                    music.toggleLike()
                } label: {
                    Image(systemName: music.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(music.isLiked ? lastFMRed : Theme.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(music.isLiked ? lastFMRed.opacity(0.15) : Color.white.opacity(0.04), in: Circle())
                }
                .buttonStyle(.plain)
                .help(music.isLiked ? L10n.inFavorites : L10n.addToFavorites)

                // Предыдущий
                Button { music.skip(-1) } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textPrimary)
                }
                .buttonStyle(.plain)

                // Воспроизведение / Пауза
                Button { music.toggle() } label: {
                    Image(systemName: music.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Theme.accent, in: Circle())
                }
                .buttonStyle(.plain)

                // Следующий
                Button { music.skip(1) } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.cardBorder, lineWidth: 1))
    }

    // MARK: - Нижняя карточка Last.fm и статистики
    private var lastFMStatusCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Красный значок Last.fm
                ZStack {
                    Circle()
                        .fill(lastFMRed.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(lastFMRed)
                }

                if lastfm.isConnected {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(lastfm.username)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)

                            Circle().fill(Theme.green).frame(width: 5, height: 5)
                            Text(L10n.lastfmConnected)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Theme.green)
                        }

                        if let lastTrack = lastfm.lastScrobbledTrack {
                            Text("\(L10n.lastfmLastScrobble): \(lastTrack)")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                                .lineLimit(1)
                        } else {
                            Text(L10n.scrobbleModeSubtitle)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Общее число скробблов
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(lastfm.totalScrobbles)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text(L10n.lastfmTotalScrobbles)
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    // Индикатор офлайн-очереди если есть
                    if !lastfm.pendingScrobbles.isEmpty {
                        Button {
                            Task { await lastfm.flushPendingScrobbles() }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 11))
                                Text("\(lastfm.pendingScrobbles.count)")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Theme.yellow.opacity(0.15), in: Capsule())
                            .foregroundStyle(Theme.yellow)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.lastfmSendQueueNow)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.lastfmScrobblerStatus)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(L10n.current == .ru
                             ? "Подключите аккаунт Last.fm во вкладке Last.fm"
                             : "Connect your Last.fm account in the Last.fm tab")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer()
                }
            }

            Divider().opacity(0.3)

            // Переключатель чёлки в эко-режиме
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "macbook.gen2")
                        .font(.system(size: 11))
                        .foregroundStyle(music.scrobbleModeNotchEnabled ? Theme.accent : Theme.textTertiary)
                    Text(L10n.current == .ru ? "Чёлка (Dynamic Island) в эко-режиме" : "Dynamic Island Notch in Eco Mode")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Toggle("", isOn: $music.scrobbleModeNotchEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
                    .controlSize(.mini)
                    .labelsHidden()
            }

            Divider().opacity(0.3)

            // Сноска энергосбережения
            HStack(spacing: 6) {
                Image(systemName: "battery.100.bolt")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.green)
                Text(L10n.scrobbleModeEcoDescription)
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.cardBorder, lineWidth: 0.8))
    }

    private func timestamp(_ seconds: Double) -> String {
        let s = seconds.isFinite ? max(0, Int(seconds)) : 0
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
}
