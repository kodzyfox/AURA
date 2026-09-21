import SwiftUI

// MARK: - Экран интеграции и управления Last.fm
struct LastFMView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @ObservedObject var lastfm = LastFMService.shared
    @EnvironmentObject var music: MusicController
    
    private let lastFMRed = Color(red: 0.88, green: 0.12, blue: 0.15)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Заголовочный баннер Last.fm
            headerBanner
            
            if lastfm.isConnected {
                connectedContent
            } else {
                disconnectedContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            if lastfm.isConnected {
                await lastfm.fetchUserInfo()
            }
        }
    }
    
    // MARK: - Баннер
    private var headerBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(lastFMRed.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(lastFMRed)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Last.fm")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    if lastfm.isConnected {
                        HStack(spacing: 5) {
                            Circle().fill(Theme.green).frame(width: 6, height: 6)
                            Text(L10n.lastfmConnected)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.green.opacity(0.12), in: Capsule())
                    }
                }
                
                Text(L10n.lastfmHeaderDesc)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(20)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Fallback-аватарка (буква, если нет URL или загрузка упала)
    private var fallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(lastFMRed.gradient)
                .frame(width: 64, height: 64)
            Text(String(lastfm.username.prefix(1)).uppercased())
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Состояние: Подключено
    private var connectedContent: some View {
        VStack(spacing: 20) {

            // Карточка профиля
            HStack(spacing: 20) {
                // Аватарка из Last.fm API
                if let avatarImage = lastfm.avatarImage {
                    Image(nsImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(lastFMRed.opacity(0.5), lineWidth: 2))
                } else if let urlStr = lastfm.avatarURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(lastFMRed.opacity(0.5), lineWidth: 2))
                        case .failure:
                            fallbackAvatar
                        case .empty:
                            ZStack {
                                fallbackAvatar
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                        @unknown default:
                            fallbackAvatar
                        }
                    }
                } else {
                    fallbackAvatar
                }

                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lastfm.username)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text(L10n.lastfmProfile)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                
                Spacer()
                
                // Счетчик скробблов
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(lastfm.totalScrobbles)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(L10n.lastfmTotalScrobbles)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                
                // Ссылка на профиль
                Button {
                    if let url = URL(string: "https://www.last.fm/user/\(lastfm.username)") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label(L10n.lastfmOpenProfile, systemImage: "arrow.up.right")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
            }
            .padding(20)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.cardBorder, lineWidth: 1))
            
            // Настройки синхронизации
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.lastfmSyncParams)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                
                Toggle(isOn: $lastfm.scrobblingEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.lastfmAutoScrobble)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text(L10n.lastfmAutoScrobbleDesc)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(lastFMRed)
                
                Divider()
                
                Toggle(isOn: $lastfm.nowPlayingEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.lastfmNowPlaying)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text(L10n.lastfmNowPlayingDesc)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(lastFMRed)
            }
            .padding(20)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.cardBorder, lineWidth: 1))
            
            // Статус скробблинга
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.lastfmScrobblerStatus)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                
                HStack(spacing: 14) {
                    Image(systemName: music.playing ? "waveform" : "pause.circle")
                        .font(.title2)
                        .foregroundStyle(music.playing ? Theme.green : Theme.textTertiary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(music.playing ? L10n.lastfmNowBroadcasting : L10n.lastfmPlaybackPaused)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                        
                        Text("\(music.title) — \(music.artist)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if !lastfm.pendingScrobbles.isEmpty {
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(L10n.lastfmPendingQueue)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.yellow)
                                Text("\(lastfm.pendingScrobbles.count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Button {
                                Task {
                                    await lastfm.flushPendingScrobbles()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.yellow)
                            }
                            .buttonStyle(.plain)
                            .help(L10n.lastfmSendQueueNow)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    } else if let lastScrobble = lastfm.lastScrobbledTrack {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(L10n.lastfmLastScrobble)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                            Text(lastScrobble)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(20)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.cardBorder, lineWidth: 1))
            
            // Музыкальная аналитика вкусов (Топ артистов и жанров)
            analyticsSection
            
            // Кнопки управления аккаунтом
            HStack {
                Button {
                    Task {
                        await LastFMService.shared.fetchUserInfo()
                    }
                } label: {
                    Label(L10n.lastfmRefreshStats, systemImage: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(role: .destructive) {
                    LastFMService.shared.disconnect()
                } label: {
                    Label(L10n.lastfmDisconnect, systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.red.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Музыкальная аналитика (Топ артистов и жанров)
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(lastFMRed)
                        Text(L10n.lastfmAnalyticsTitle)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Text(L10n.lastfmAnalyticsSub)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                // Переключатель периода
                HStack(spacing: 4) {
                    periodButton(key: "7day", title: L10n.lastfm7Days)
                    periodButton(key: "1month", title: L10n.lastfm1Month)
                    periodButton(key: "overall", title: L10n.lastfmOverall)
                }
                
                Button {
                    Task {
                        await LastFMService.shared.loadAnalytics(period: lastfm.analyticsPeriod)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .help(L10n.current == .ru ? "Обновить аналитику" : "Refresh Analytics")
            }
            
            if lastfm.isLoadingAnalytics && lastfm.topArtists.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(L10n.lastfmLoadingAnalytics)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if lastfm.topArtists.isEmpty && lastfm.topTags.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        Task { await LastFMService.shared.loadAnalytics() }
                    } label: {
                        Label(L10n.lastfmLoadAnalytics, systemImage: "chart.bar.xaxis")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(lastFMRed.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(lastFMRed)
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 20) {
                    // Топ артистов
                    if !lastfm.topArtists.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "music.mic")
                                    .font(.system(size: 11))
                                    .foregroundStyle(lastFMRed)
                                Text(L10n.lastfmTopArtists)
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Text(L10n.lastfmScrobbles)
                                    .font(.system(size: 9))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            
                            let maxPlays = Double(lastfm.topArtists.first?.playcount ?? 1)
                            VStack(spacing: 5) {
                                ForEach(lastfm.topArtists.prefix(7)) { artist in
                                    HStack(spacing: 12) {
                                        Text("#\(artist.rank)")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundStyle(artist.rank <= 3 ? Theme.accent : Theme.textTertiary)
                                            .frame(width: 22, alignment: .leading)
                                        
                                        Text(artist.name)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Theme.textPrimary)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        // Полоса относительной популярности
                                        GeometryReader { barGeo in
                                            let pct = max(0.06, Double(artist.playcount) / max(1.0, maxPlays))
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.white.opacity(0.06))
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Theme.accent, lastFMRed],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: barGeo.size.width * pct)
                                            }
                                        }
                                        .frame(width: 90, height: 6)
                                        
                                        Text("\(artist.playcount)")
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(Theme.textSecondary)
                                            .frame(width: 44, alignment: .trailing)
                                        
                                        if let urlStr = artist.url, let url = URL(string: urlStr) {
                                            Button {
                                                NSWorkspace.shared.open(url)
                                            } label: {
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(Theme.textTertiary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 7))
                                }
                            }
                        }
                    }
                    
                    // Любимые жанры и теги
                    if !lastfm.topTags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.accent)
                                Text(L10n.lastfmTopTags)
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundStyle(Theme.textSecondary)
                                Spacer()
                            }
                            
                            FlowLayout(spacing: 8) {
                                ForEach(lastfm.topTags.prefix(12)) { tag in
                                    HStack(spacing: 6) {
                                        Text(tag.name.capitalized)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(Theme.textPrimary)
                                        
                                        if tag.count > 0 {
                                            Text("\(tag.count)")
                                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                                .foregroundStyle(Theme.accent)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Theme.accent.opacity(0.15), in: Capsule())
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - Состояние: Не подключено (Мастер настройки из 3 шагов)
    private var disconnectedContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Карточка возможностей
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.lastfmFeaturesTitle)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                
                VStack(spacing: 12) {
                    featureRow(
                        icon: "antenna.radiowaves.left.and.right",
                        title: L10n.current == .ru ? "Мгновенный статус «Now Playing»" : "Instant Now Playing Status",
                        desc: L10n.current == .ru ? "Друзья увидят в вашем профиле, что вы слушаете прямо сейчас в Spotify или Apple Music." : "Friends can see what you're currently playing in Spotify or Apple Music."
                    )
                    featureRow(
                        icon: "clock.arrow.circlepath",
                        title: L10n.current == .ru ? "Безупречный авто-скробблинг" : "Seamless Auto-Scrobbling",
                        desc: L10n.current == .ru ? "Каждый прослушанный трек засчитывается в вашу музыкальную историю с точным временем." : "Every played track is counted towards your listening history with exact timestamp."
                    )
                    featureRow(
                        icon: "heart.fill",
                        title: L10n.current == .ru ? "Синхронизация любимых треков" : "Loved Tracks Synchronization",
                        desc: L10n.current == .ru ? "Лайкайте треки в Aura — они автоматически добавятся в Loved Tracks на Last.fm." : "Favorite tracks in Aura — they are automatically saved to Loved Tracks on Last.fm."
                    )
                }
            }
            .padding(20)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.cardBorder, lineWidth: 1))
            
            // Пошаговое подключение (3 простых шага)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(L10n.lastfmConnectTitle)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textTertiary)
                    
                    Spacer()
                    
                    if lastfm.hasValidCredentials {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.green)
                            Text(L10n.lastfmKeysReady)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.green)
                        }
                    }
                }
                
                // ШАГ 1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        stepBadge(1)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.current == .ru ? "Создайте ключ приложения на Last.fm (занимает 20 секунд)" : "Create an API account on Last.fm (takes 20 seconds)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.current == .ru ? "Нажмите кнопку справа. В поле Application name введите «Aura», а остальные поля можно оставить пустыми. Нажмите Submit." : "Click the button to open Last.fm. Enter 'Aura' as Application name, and leave optional fields blank. Click Submit.")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            if let url = URL(string: "https://www.last.fm/api/account/create") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Label(L10n.current == .ru ? "Открыть страницу Last.fm ↗" : "Open Last.fm API page ↗", systemImage: "link")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.accent)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
                
                // ШАГ 2
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        stepBadge(2)
                        Text(L10n.current == .ru ? "Вставьте полученные API Key и Shared Secret:" : "Paste your API Key and Shared Secret:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text("API Key:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 95, alignment: .leading)
                            
                            TextField("32-значный API Key", text: $lastfm.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11).monospaced())
                            
                            Button(L10n.current == .ru ? "Вставить" : "Paste") {
                                if let str = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                                    lastfm.apiKey = str
                                }
                            }
                            .controlSize(.small)
                        }
                        
                        HStack(spacing: 8) {
                            Text("Shared Secret:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 95, alignment: .leading)
                            
                            SecureField("32-значный Shared Secret", text: $lastfm.apiSecret)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11).monospaced())
                            
                            Button(L10n.current == .ru ? "Вставить" : "Paste") {
                                if let str = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                                    lastfm.apiSecret = str
                                }
                            }
                            .controlSize(.small)
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
                
                // ШАГ 3
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        stepBadge(3)
                        Text(L10n.current == .ru ? "Авторизуйте Aura в своем аккаунте Last.fm" : "Authorize Aura with your Last.fm account")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    
                    if lastfm.isAuthenticating {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                ProgressView().controlSize(.small)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L10n.current == .ru ? "Страница авторизации Aura открыта в браузере." : "Aura authorization page is open in your browser.")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(L10n.current == .ru ? "Нажмите «YES, ALLOW ACCESS» на сайте Last.fm, затем подтвердите в приложении:" : "Click 'YES, ALLOW ACCESS' on Last.fm, then confirm in Aura:")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .padding(12)
                            .background(lastFMRed.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            
                            HStack(spacing: 12) {
                                Button {
                                    Task { await LastFMService.shared.completeAuthorization() }
                                } label: {
                                    Label(L10n.current == .ru ? "Завершить подключение" : "Complete Authorization", systemImage: "checkmark.circle.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 9)
                                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                
                                Button(L10n.current == .ru ? "Попробовать снова" : "Try Again") {
                                    Task { await LastFMService.shared.startAuthorization() }
                                }
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    } else {
                        Button {
                            Task { await LastFMService.shared.startAuthorization() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right.circle.fill")
                                Text(L10n.current == .ru ? "Войти через Last.fm" : "Log in with Last.fm")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(lastfm.hasValidCredentials ? lastFMRed : Color.gray.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                            .shadow(color: lastfm.hasValidCredentials ? lastFMRed.opacity(0.35) : Color.clear, radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                        .disabled(!lastfm.hasValidCredentials)
                        
                        if !lastfm.hasValidCredentials {
                            Text(L10n.current == .ru ? "Сначала укажите API Key и Shared Secret (Шаг 1 и 2), чтобы активировать вход." : "Enter your API Key and Shared Secret (Steps 1 & 2) first to enable login.")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    
                    if let err = lastfm.authError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.red)
                            Text(err)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.red)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(20)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.cardBorder, lineWidth: 1))
        }
    }
    
    private func periodButton(key: String, title: String) -> some View {
        let isSelected = lastfm.analyticsPeriod == key
        return Button {
            Task {
                await LastFMService.shared.loadAnalytics(period: key)
            }
        } label: {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    isSelected ? lastFMRed.opacity(0.2) : Color.white.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .foregroundStyle(isSelected ? lastFMRed : Theme.textSecondary)
        }
        .buttonStyle(.plain)
    }
    
    private func stepBadge(_ num: Int) -> some View {
        ZStack {
            Circle()
                .fill(lastFMRed.opacity(0.2))
                .frame(width: 22, height: 22)
            Text("\(num)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(lastFMRed)
        }
    }
    
    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(lastFMRed)
                .frame(width: 22, alignment: .center)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - FlowLayout для адаптивных тегов
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 500
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + lineHeight
        return CGSize(width: width, height: max(20, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
