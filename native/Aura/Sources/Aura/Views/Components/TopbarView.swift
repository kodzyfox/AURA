import SwiftUI

struct TopbarView: View {
    @EnvironmentObject var music: MusicController
    let section: NavigationSection
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text(L10n.current == .ru ? "Ваше пространство" : "Your Space")
                    .foregroundStyle(Theme.textTertiary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
                Text(section.localizedTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .font(.system(size: 11))
            
            Spacer()
            
            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        music.toggleMiniPlayer()
                    }
                } label: {
                    Label(L10n.miniPlayer, systemImage: "pip")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder))
                }
                .buttonStyle(.plain)
                .help("Cmd+Shift+M")
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        music.toggleCoverMode()
                    }
                } label: {
                    Label(L10n.screensaverMode, systemImage: "sparkles.tv")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder))
                }
                .buttonStyle(.plain)
                .help("Control+Command+F")
            }
            
            Text(L10n.companionBadge)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 8)
        }
        .padding(.horizontal, 32)
        .frame(height: 58)
        .background(Theme.background)
        .zIndex(10)
    }
}

struct SectionHeadingView: View {
    let section: NavigationSection
    
    private var headingTitle: String {
        switch section {
        case .sources: return L10n.headingTitleSources
        case .presets: return L10n.headingTitlePresets
        case .effects: return L10n.headingTitleEffects
        case .lastfm: return L10n.headingTitleLastFM
        case .settings: return L10n.headingTitleSettings
        case .overview: return L10n.headingTitleOverview
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.headingKicker)
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.accent)
            
            Text(headingTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            
            Text(L10n.headingSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
