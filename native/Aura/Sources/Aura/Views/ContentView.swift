import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @EnvironmentObject var music: MusicController
    @AppStorage("aura.hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @State private var section: NavigationSection = .overview
    @State private var saveSheet = false
    @State private var presetName = L10n.defaultPresetName
    @State private var showOnboarding = false
    @State private var showQueueSheet = false
    @State private var isDragTargeted = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .top) {
            if music.isMiniPlayer {
                MiniPlayerView()
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else if music.isCoverMode {
                CoverView()
                    .transition(.opacity)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    SidebarView(section: $section)
                    
                    VStack(spacing: 0) {
                        TopbarView(section: section)
                        Divider().opacity(0.3)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 28) {
                                SectionHeadingView(section: section)
                                
                                if let message = music.message {
                                    HStack(spacing: 12) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundStyle(Theme.accent)
                                        Text(message)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.textPrimary)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                }
                                
                                switch section {
                                case .overview:
                                    OverviewSectionView(
                                        section: $section,
                                        saveSheet: $saveSheet,
                                        showQueueSheet: $showQueueSheet
                                    )
                                case .sources:
                                    SourcesSectionView(
                                        section: $section,
                                        showQueueSheet: $showQueueSheet
                                    )
                                case .effects:
                                    EffectsSectionView()
                                case .presets:
                                    PresetsSectionView(
                                        section: $section,
                                        saveSheet: $saveSheet
                                    )
                                case .lastfm:
                                    LastFMView()
                                case .settings:
                                    SettingsSectionView(showOnboarding: $showOnboarding)
                                }
                                
                                footer
                            }
                            .padding(32)
                        }
                    }
                    .background(Theme.background)
                }
            }

            // Плавающий баннер уведомлений
            AppNotificationBannerView()
                .padding(.top, 10)
                .padding(.horizontal, 24)
                .zIndex(100)

            // Индикатор Drag & Drop локальных аудиофайлов
            if isDragTargeted {
                dragDropOverlay
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .onReceive(timer) { _ in music.poll() }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onDrop(of: ["public.file-url"], isTargeted: $isDragTargeted) { providers in
            handleFileDrop(providers: providers)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showQueueSheet) {
            LocalQueueView(isPresented: $showQueueSheet)
        }
        .sheet(isPresented: $saveSheet) {
            savePresetSheet
        }
    }

    // MARK: - Subviews & Sheets
    private var dragDropOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
            .background(Theme.accent.opacity(0.1))
            .overlay(
                VStack(spacing: 14) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.accent)
                    Text(L10n.dropFilesHere)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(L10n.dropFilesSub)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            )
            .allowsHitTesting(false)
            .padding(16)
            .transition(.opacity)
            .zIndex(99)
    }

    private var savePresetSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(L10n.savePresetTitle, systemImage: "sparkles")
                .font(.title2)
                .fontWeight(.semibold)
            
            TextField(L10n.presetNamePlaceholder, text: $presetName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button(L10n.cancel) { saveSheet = false }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(L10n.save) {
                    music.savePreset(presetName)
                    saveSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(28)
        .frame(width: 380)
    }

    private var footer: some View {
        HStack {
            Text(L10n.footerNote)
            Spacer()
            Text(L10n.footerCopyright)
        }
        .font(.system(size: 10))
        .foregroundStyle(Theme.textTertiary)
        .padding(.top, 10)
    }

    // MARK: - File Drop Handler
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    defer { group.leave() }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    } else if let url = item as? URL {
                        urls.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                music.addLocalFiles(urls)
            }
        }
        return true
    }
}
