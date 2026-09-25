import SwiftUI

struct EffectsSectionView: View {
    @EnvironmentObject var music: MusicController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.nineMoodsTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Effect.allCases) { effect in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            music.settings.effect = effect
                        }
                    } label: {
                        HStack(spacing: 16) {
                            EffectThumbnailPreview(effect: effect, isSelected: music.settings.effect == effect)
                                .frame(width: 72, height: 72)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(effect.localizedName)
                                    .font(.headline)
                                Text(effect.localizedDescription)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if music.settings.effect == effect {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accent)
                                    .font(.title3)
                            }
                        }
                        .padding(14)
                        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(music.settings.effect == effect ? Theme.accent : Theme.cardBorder)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
