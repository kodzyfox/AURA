import SwiftUI

struct SourcesSectionView: View {
    @EnvironmentObject var music: MusicController
    @Binding var section: NavigationSection
    @Binding var showQueueSheet: Bool
    
    @State private var spotifyTestResult: ConnectionTestResult?
    @State private var musicTestResult: ConnectionTestResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.sourcesSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(4)
            
            ForEach(Source.allCases) { source in
                sourceCard(for: source)
            }
        }
    }

    @ViewBuilder
    private func sourceCard(for source: Source) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 20) {
                SourceIconView(source: source, size: 24, color: Theme.accent)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(source.localizedName)
                            .font(.headline)
                        if music.source == source {
                            Text(L10n.current == .ru ? "Активен" : "Active")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent.opacity(0.15), in: Capsule())
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    Text(sourceDescription(source))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                Button(music.source == source ? (L10n.current == .ru ? "Выбрано" : "Selected") : (L10n.current == .ru ? "Выбрать" : "Select")) {
                    music.select(source)
                    section = .overview
                }
                .controlSize(.large)
            }

            sourceExtras(for: source)
        }
        .padding(20)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(music.source == source ? Theme.accent.opacity(0.4) : Theme.cardBorder)
        )
    }

    @ViewBuilder
    private func sourceExtras(for source: Source) -> some View {
        if source == .spotify || source == .music {
            Divider().opacity(0.2)
            HStack(spacing: 12) {
                Button {
                    testSourceConnection(for: source)
                } label: {
                    Label(L10n.checkConnection, systemImage: "bolt.horizontal.circle")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(Theme.accent)

                let testResult = (source == .spotify ? spotifyTestResult : musicTestResult)
                if let res = testResult {
                    HStack(spacing: 5) {
                        Image(systemName: res.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        Text(res.message)
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(res.isSuccess ? Theme.green : Theme.orange)
                }
            }
        } else if source == .local {
            Divider().opacity(0.2)
            HStack(spacing: 12) {
                Button {
                    showQueueSheet = true
                } label: {
                    Label(
                        music.localQueue.isEmpty
                            ? L10n.localQueueTitle
                            : "\(L10n.localQueueTitle) (\(music.localQueue.count))",
                        systemImage: "list.bullet"
                    )
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(Theme.accent)

                Button {
                    music.openFiles()
                } label: {
                    Label(L10n.addFiles, systemImage: "plus")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.cardBorder.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(Theme.textPrimary)

                Text(L10n.dragDropFilesHint)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
        } else if source == .youtubeMusic || source == .yandexMusic || source == .nowPlaying {
            Divider().opacity(0.2)
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.system(size: 11))
                Text(L10n.current == .ru
                    ? "Нативная интеграция через системный Now Playing (MediaRemote)"
                    : "Native integration via system Now Playing (MediaRemote)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func testSourceConnection(for source: Source) {
        let bundleID = source == .spotify ? "com.spotify.client" : "com.apple.Music"
        Task { @MainActor in
            let result = await AutomationPermissionManager.shared.testConnection(bundleID: bundleID)
            if source == .spotify {
                spotifyTestResult = result
            } else {
                musicTestResult = result
            }
            AppNotificationManager.shared.show(
                type: result.isSuccess ? .success : .warning,
                title: result.isSuccess ? L10n.connectionSuccess : L10n.connectionFailed,
                message: result.message,
                actionTitle: result.permissionStatus == .denied ? L10n.openSettingsAction : nil,
                action: result.permissionStatus == .denied ? {
                    AutomationPermissionManager.shared.openAutomationSettings()
                } : nil
            )
        }
    }
    
    private func sourceDescription(_ source: Source) -> String {
        switch source {
        case .auto: return L10n.autoDetectDesc
        case .demo: return L10n.demoDesc
        case .spotify: return L10n.spotifyDesc
        case .music: return L10n.appleMusicDesc
        case .local: return L10n.localFilesDesc
        case .youtubeMusic: return L10n.current == .ru
            ? "Нативное подключение к YouTube Music через систему (браузеры, PWA, десктоп)"
            : "Native connection to YouTube Music via system (browsers, PWA, desktop)"
        case .yandexMusic: return L10n.current == .ru
            ? "Нативное подключение к Яндекс Музыке через систему (приложение или браузер)"
            : "Native connection to Yandex Music via system (app or browser)"
        case .nowPlaying: return L10n.current == .ru
            ? "Универсальный перехват любого активного медиаплеера macOS (Now Playing)"
            : "Universal capture of any active macOS media player (Now Playing)"
        }
    }
}
