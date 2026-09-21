import SwiftUI

public struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @ObservedObject private var permissions = AutomationPermissionManager.shared
    @ObservedObject private var l10n = LocalizationManager.shared

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // Фоновое сияние
            RadialGradient(
                colors: [Theme.accent.opacity(0.18), Theme.accentSecondary.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Верхняя панель: Переключатель языка + Индикаторы шагов + Пропустить
                HStack {
                    // Переключатель языка прямо на экране онбординга
                    HStack(spacing: 4) {
                        ForEach(AppLanguage.allCases) { lang in
                            Button {
                                l10n.setLanguage(lang)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(lang == .ru ? "🇷🇺" : "🇬🇧")
                                        .font(.system(size: 11))
                                    Text(lang.shortTitle)
                                        .font(.system(size: 10, weight: l10n.language == lang ? .bold : .medium))
                                }
                                .foregroundStyle(l10n.language == lang ? Theme.accent : Theme.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    l10n.language == lang ? Theme.accent.opacity(0.16) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.cardBorder))

                    Spacer()

                    // Точечные индикаторы шагов
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Capsule()
                                .fill(index == currentStep ? Theme.accent : Theme.textTertiary.opacity(0.3))
                                .frame(width: index == currentStep ? 26 : 7, height: 4)
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
                        }
                    }

                    Spacer()

                    // Кнопка быстрого пропуска
                    Button {
                        completeOnboarding()
                    } label: {
                        Text(L10n.onboardingSkip)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)

                // Контент текущего шага
                Group {
                    switch currentStep {
                    case 0:
                        stepWelcome
                    case 1:
                        stepIntegrations
                    case 2:
                        stepAudioVisuals
                    default:
                        stepReady
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

                // Нижняя панель навигации
                HStack {
                    if currentStep > 0 {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentStep -= 1
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                Text(L10n.onboardingBack)
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    if currentStep < 3 {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentStep += 1
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(L10n.onboardingNext)
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.black)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button {
                            completeOnboarding()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                Text(L10n.onboardingFinish)
                            }
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 26)
                            .padding(.vertical, 11)
                            .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.black)
                            .shadow(color: Theme.accent.opacity(0.4), radius: 10, y: 4)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 28)
            }
        }
        .frame(width: 600, height: 470)
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "aura.hasCompletedOnboarding")
        withAnimation {
            isPresented = false
        }
    }

    // MARK: - Шаг 1: Приветствие
    private var stepWelcome: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accentGradient)
                .padding(.bottom, 2)

            Text(L10n.onboardingWelcomeTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Text(L10n.onboardingWelcomeDesc)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 40)
                .lineSpacing(3)

            HStack(spacing: 16) {
                featureBadge(icon: "photo.on.rectangle.angled", title: L10n.onboardingBadgeLiveWallpapers)
                featureBadge(icon: "sparkle", title: L10n.onboardingBadgeAmbilight)
                featureBadge(icon: "chart.bar.fill", title: L10n.onboardingBadgeAudioSpectrum)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Шаг 2: Интеграция плееров
    private var stepIntegrations: some View {
        VStack(spacing: 16) {
            Image(systemName: "applescript.fill")
                .font(.system(size: 42))
                .foregroundStyle(Theme.green)

            Text(L10n.onboardingIntegrationsTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Text(L10n.onboardingIntegrationsDesc)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 40)
                .lineSpacing(3)

            VStack(spacing: 10) {
                playerPermissionRow(appName: "Spotify", bundleID: "com.spotify.client", icon: "music.note")
                playerPermissionRow(appName: "Apple Music", bundleID: "com.apple.Music", icon: "applelogo")
            }
            .padding(.horizontal, 48)
            .padding(.top, 6)
        }
    }

    // MARK: - Шаг 3: Аудиоанализ и локальный звук
    private var stepAudioVisuals: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.badge.magnifyingglass")
                .font(.system(size: 42))
                .foregroundStyle(Theme.accent)

            Text(L10n.onboardingAudioTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Text(L10n.onboardingAudioDesc)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 40)
                .lineSpacing(3)

            HStack(spacing: 14) {
                featureBadge(icon: "waveform", title: L10n.onboardingBadgeDSP)
                featureBadge(icon: "arrow.down.doc.fill", title: L10n.onboardingBadgeDragDrop)
                featureBadge(icon: "list.bullet", title: L10n.onboardingBadgeQueue)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Шаг 4: Готово
    private var stepReady: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accentGradient)

            Text(L10n.onboardingReadyTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Text(L10n.onboardingReadyDesc)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 40)
                .lineSpacing(3)

            HStack(spacing: 12) {
                featureBadge(icon: "menubar.rectangle", title: L10n.onboardingBadgeMenuBar)
                featureBadge(icon: "macwindow", title: L10n.onboardingBadgeMiniPlayer)
                featureBadge(icon: "chart.line.uptrend.xyaxis", title: L10n.onboardingBadgeLastFM)
            }
            .padding(.top, 8)
        }
    }

    private func featureBadge(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder))
    }

    private func playerPermissionRow(appName: String, bundleID: String, icon: String) -> some View {
        let status = permissions.checkPermission(bundleID: bundleID)
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 24)
                .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(status.localizedDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(status == .authorized ? Theme.green : (status == .denied ? Color.red : Theme.textTertiary))
            }

            Spacer()

            if status != .authorized && status != .notInstalled {
                Button {
                    permissions.requestPermission(bundleID: bundleID)
                } label: {
                    Text(L10n.onboardingAllowPermission)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Theme.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(Theme.accent)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.accent.opacity(0.5)))
                }
                .buttonStyle(.plain)
            } else if status == .authorized {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.green)
            }
        }
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder))
    }
}
