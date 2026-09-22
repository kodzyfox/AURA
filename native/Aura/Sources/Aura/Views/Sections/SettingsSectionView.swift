import SwiftUI
import AppKit

struct SettingsSectionView: View {
    @EnvironmentObject var music: MusicController
    @ObservedObject private var l10n = LocalizationManager.shared
    @ObservedObject private var launchAtLogin = LaunchAtLoginManager.shared
    @ObservedObject private var performance = PerformanceManager.shared
    @ObservedObject private var accentManager = AccentColorManager.shared
    @ObservedObject private var updater = UpdateManager.shared
    
    @AppStorage("aura.appearance") private var appearance: Appearance = .system
    @AppStorage("aura.backgroundMode") private var backgroundMode: Bool = true
    @AppStorage("aura.hideFromDock") private var hideFromDock: Bool = false
    @AppStorage("aura.windowCloseBehavior") private var windowCloseBehavior: WindowCloseBehavior = .hideToMenuBar
    
    @State private var customAccentColor: Color = AccentColorManager.shared.accent
    @Binding var showOnboarding: Bool
    
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
        VStack(alignment: .leading, spacing: 24) {
            // 1. Оформление (Тема интерфейса)
            appearanceCard
            
            // 2. Язык интерфейса
            languageCard
            
            // 3. Цвет акцента
            accentColorCard
            
            // 4. Фоновый режим и интеграция в macOS
            backgroundIntegrationCard
            
            // 5. Производительность и энергосбережение
            performanceCard
            
            // 6. Сброс настроек
            resetSettingsCard
            
            // 7. Обновление ПО (Software Update)
            softwareUpdateCard
            
            // 8. О программе Aura
            aboutAppCard
        }
    }
    
    // MARK: - Подкомпоненты настроек
    
    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.appearance)
                        .font(.system(size: 14, weight: .bold))
                    Text(L10n.appearanceSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            HStack(spacing: 12) {
                ForEach(Appearance.allCases) { app in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appearance = app
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: app.symbol)
                                .font(.system(size: 22))
                                .foregroundStyle(appearance == app ? Theme.accent : Theme.textSecondary)
                            
                            Text(app.localizedName)
                                .font(.system(size: 12, weight: appearance == app ? .semibold : .regular))
                                .foregroundStyle(appearance == app ? Theme.textPrimary : Theme.textSecondary)
                            
                            if appearance == app {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                    Text(L10n.current == .ru ? "Активна" : "Active")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundStyle(Theme.accent)
                            } else {
                                Text(" ")
                                    .font(.system(size: 10))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            appearance == app ? Theme.accent.opacity(0.12) : Theme.cardBackground,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(appearance == app ? Theme.accent.opacity(0.6) : Theme.cardBorder, lineWidth: appearance == app ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
    }
    
    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.language)
                        .font(.system(size: 14, weight: .bold))
                    Text(L10n.languageSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            HStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        l10n.setLanguage(lang)
                    } label: {
                        HStack(spacing: 12) {
                            Text(lang == .ru ? "🇷🇺" : "🇬🇧")
                                .font(.system(size: 22))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.title)
                                    .font(.system(size: 13, weight: l10n.language == lang ? .semibold : .regular))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(lang.shortTitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            
                            Spacer()
                            
                            if l10n.language == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            l10n.language == lang ? Theme.accent.opacity(0.12) : Theme.cardBackground,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(l10n.language == lang ? Theme.accent.opacity(0.6) : Theme.cardBorder, lineWidth: l10n.language == lang ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
    }
    
    private var accentColorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.language == .ru ? "Цвет акцента" : "Accent Color")
                        .font(.system(size: 14, weight: .bold))
                    Text(l10n.language == .ru ? "Цвет интерфейса, кнопок и эффектов" : "UI highlight, buttons, and effects color")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 8) {
                ForEach(AccentColorManager.palette, id: \.name) { preset in
                    let isSelected = accentManager.accent == preset.color
                    Button {
                        accentManager.select(preset.color)
                        customAccentColor = preset.color
                    } label: {
                        ZStack {
                            Circle()
                                .fill(preset.color)
                                .frame(width: 28, height: 28)
                            if isSelected {
                                Circle()
                                    .strokeBorder(.white.opacity(0.9), lineWidth: 2.5)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .help(preset.name)
                    .scaleEffect(isSelected ? 1.18 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }

                Spacer(minLength: 4)

                ColorPicker("", selection: $customAccentColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 28, height: 28)
                    .help(l10n.language == .ru ? "Свой цвет" : "Custom color")
                    .onChange(of: customAccentColor) { _, newColor in
                        accentManager.selectCustom(newColor)
                    }

                Button {
                    accentManager.resetToDefault()
                    customAccentColor = AccentColorManager.palette[0].color
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(Theme.cardBackground, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.cardBorder))
                }
                .buttonStyle(.plain)
                .help(l10n.language == .ru ? "Сбросить цвет" : "Reset to default")
            }
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
    }
    
    private var backgroundIntegrationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "macwindow.on.rectangle")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.backgroundModeSection)
                        .font(.system(size: 14, weight: .bold))
                    Text(L10n.backgroundSectionSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            VStack(spacing: 12) {
                Toggle(isOn: $backgroundMode) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.runInBackground)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.whenWindowClosed)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .padding(.vertical, 8)
                
                Divider().opacity(0.4)
                
                Toggle(isOn: $hideFromDock) {
                    HStack(spacing: 12) {
                        Image(systemName: "dock.rectangle")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.hideFromDock)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.menuBarOnly)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .padding(.vertical, 8)
                .onChange(of: hideFromDock) { _, _ in
                    WindowCloseHandler.shared.updateDockVisibility()
                }
                
                Divider().opacity(0.4)
                
                Toggle(isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.toggle(enabled: $0) }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.launchAtLogin)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.launchAtLoginSub)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .padding(.vertical, 8)
                
                Divider().opacity(0.4)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.onWindowClose)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(L10n.onWindowCloseSub)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    
                    Picker("", selection: $windowCloseBehavior) {
                        ForEach(WindowCloseBehavior.allCases) { behavior in
                            Text(behavior.localizedName).tag(behavior)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
                
                Divider().opacity(0.4)
                
                HStack(spacing: 12) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.onboardingWelcome)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text(L10n.onboardingSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Button {
                        showOnboarding = true
                    } label: {
                        Text(L10n.openOnboarding)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
    }
    
    private var performanceCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.performanceSectionTitle)
                        .font(.system(size: 14, weight: .bold))
                    Text(L10n.performanceSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.visualQualityTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                HStack(spacing: 10) {
                    ForEach(VisualQuality.allCases) { q in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                performance.quality = q
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(q == .automatic ? "⚡️" : (q == .high ? "💎" : (q == .balanced ? "⚖️" : "🔋")))
                                    Spacer()
                                    if performance.quality == q {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                                Text(q.localizedName)
                                    .font(.system(size: 11, weight: performance.quality == q ? .bold : .medium))
                                    .foregroundStyle(performance.quality == q ? Theme.textPrimary : Theme.textSecondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 65, alignment: .topLeading)
                            .padding(12)
                            .background(
                                performance.quality == q ? Theme.accent.opacity(0.12) : Theme.cardBackground,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(performance.quality == q ? Theme.accent.opacity(0.6) : Theme.cardBorder, lineWidth: performance.quality == q ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider().opacity(0.4)
            
            Toggle(isOn: $performance.disableExpensiveEffectsOnBattery) {
                HStack(spacing: 12) {
                    Image(systemName: "battery.100.bolt")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.disableOnBatteryTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text(L10n.disableOnBatterySubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(.vertical, 4)
            
            Divider().opacity(0.4)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.diagnosticsTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: performance.isOnBattery ? "battery.75" : "powerplug.fill")
                            .foregroundStyle(performance.isOnBattery ? Theme.orange : Theme.green)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.powerSourceTitle)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                            Text(performance.powerSourceDescription)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                    
                    HStack(spacing: 10) {
                        Image(systemName: "speedometer")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.currentFPSTitle)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                            Text("\(performance.targetFPS) FPS (\(performance.effectiveQuality.localizedName))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                    
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(performance.thermalState == .nominal ? Theme.green : (performance.thermalState == .fair ? Theme.orange : Color.red))
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.thermalsTitle)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                            Text(performance.thermalStateDescription)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                    
                    HStack(spacing: 10) {
                        Image(systemName: "display.2")
                            .foregroundStyle(Theme.accentSecondary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.monitorsTitle)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                            Text("\(performance.screensDescription) · \(Int(performance.wallpaperPixelScale * 100))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
    }
    
    private var resetSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.resetSettingsTitle)
                        .font(.system(size: 14, weight: .bold))
                    Text(L10n.resetSettingsSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button {
                    withAnimation { music.settings = Atmosphere() }
                } label: {
                    Label(L10n.resetToDefaults, systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.red.opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.red.opacity(0.3)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
    }
    
    private var softwareUpdateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(updater.updateAvailable ? Color.orange : Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(L10n.updatesSectionTitle)
                            .font(.system(size: 14, weight: .bold))
                        
                        if updater.updateAvailable {
                            Text(L10n.newVersionAvailable)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.18), in: Capsule())
                                .foregroundStyle(Color.orange)
                        }
                    }
                    Text(L10n.updatesSectionSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                Button {
                    updater.checkForUpdates(manual: true)
                } label: {
                    updateButtonLabel
                }
                .buttonStyle(.plain)
                .disabled(updater.isChecking)
            }
            
            Divider().opacity(0.4)
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.currentVersionLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                    Text("v\(updater.currentVersion)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                }
                
                if let release = updater.latestRelease {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.latestVersionLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                        Text("v\(release.versionString)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(updater.updateAvailable ? Color.orange : Theme.green)
                    }
                }
                
                Spacer()
                
                if let date = updater.lastCheckedDate {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(L10n.lastChecked)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textTertiary)
                        Text(date, style: .relative)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            
            if updater.isUpToDate && !updater.updateAvailable {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.green)
                        .font(.system(size: 14))
                    Text(L10n.upToDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.vertical, 2)
            }
            
            if let err = updater.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.red)
                        .font(.system(size: 13))
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.red.opacity(0.9))
                }
                .padding(10)
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            
            if updater.updateAvailable, let release = updater.latestRelease {
                VStack(alignment: .leading, spacing: 14) {
                    if let notes = release.body, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        releaseNotesView(notes)
                    }
                    
                    updateActionView(release: release)
                }
                .padding(16)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.accent.opacity(0.4)))
            }
            
            Divider().opacity(0.4)
            
            Toggle(isOn: $updater.autoCheckOnLaunch) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.autoCheckOnLaunch)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(L10n.autoCheckOnLaunchSub)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .toggleStyle(.switch)
            .padding(.horizontal, 2)
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(updater.updateAvailable ? Color.orange.opacity(0.4) : Theme.cardBorder))
    }
    
    @ViewBuilder
    private func releaseNotesView(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.releaseNotesTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            ScrollView {
                Text(notes)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .frame(maxHeight: 120)
            .background(Theme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder))
        }
    }
    
    @ViewBuilder
    private func updateActionView(release: GitHubRelease) -> some View {
        switch updater.downloadState {
        case .idle:
            HStack(spacing: 12) {
                Button {
                    updater.startDownload()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text(L10n.downloadAndInstall)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 7))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
                if let url = URL(string: release.htmlUrl) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Text(L10n.viewOnGitHub)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9))
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
            
        case .downloading(let progress, let bytesRead, let totalBytes):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.downloading)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if totalBytes > 0 {
                        let readMB = Double(bytesRead) / 1024.0 / 1024.0
                        let totalMB = Double(totalBytes) / 1024.0 / 1024.0
                        Text(String(format: "%.1f / %.1f MB (%.0f%%)", readMB, totalMB, progress * 100))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Theme.accent)
                
                Button(L10n.cancelDownload) {
                    updater.cancelDownload()
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.red.opacity(0.8))
            }
            
        case .readyToInstall(let dmgURL):
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.green)
                    Text(L10n.readyToInstallDesc)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
                
                HStack(spacing: 12) {
                    Button {
                        updater.installAndRelaunch()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(L10n.installAndRelaunch)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 7))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        NSWorkspace.shared.open(dmgURL)
                    } label: {
                        Text(L10n.openDMG)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 7))
                            .foregroundStyle(Theme.textSecondary)
                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Theme.cardBorder))
                    }
                    .buttonStyle(.plain)
                }
            }
            
        case .failed(let msg):
            VStack(alignment: .leading, spacing: 8) {
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.red)
                Button(L10n.checkUpdatesButton) {
                    updater.checkForUpdates(manual: true)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.accent)
            }
        }
    }
    
    @ViewBuilder
    private var updateButtonLabel: some View {
        HStack(spacing: 6) {
            if updater.isChecking {
                ProgressView()
                    .controlSize(.small)
                Text(L10n.checkingUpdates)
                    .font(.system(size: 12, weight: .medium))
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                Text(L10n.checkUpdatesButton)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        .foregroundStyle(Theme.accent)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.accent.opacity(0.3)))
    }
    
    private var aboutAppCard: some View {
        HStack(spacing: 16) {
            if let icon = appIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accentGradient)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Aura")
                        .font(.system(size: 15, weight: .bold))
                    Text("v\(updater.currentVersion)")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accent.opacity(0.15), in: Capsule())
                        .foregroundStyle(Theme.accent)
                }
                Text("\(L10n.nativeMacApp) • by Kodzy")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
            
            Button {
                NSApplication.shared.orderFrontStandardAboutPanel(
                    options: [
                        NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "by Kodzy"
                    ]
                )
            } label: {
                Label(L10n.openAboutDialog, systemImage: "info.circle")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder))
    }
}
