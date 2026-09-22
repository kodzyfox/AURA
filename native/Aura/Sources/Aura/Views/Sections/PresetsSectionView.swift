import SwiftUI

struct PresetsSectionView: View {
    @EnvironmentObject var music: MusicController
    @Binding var section: NavigationSection
    @Binding var saveSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Button {
                    saveSheet = true
                } label: {
                    Label(L10n.current == .ru ? "Новый пресет" : "New Preset", systemImage: "plus")
                }
                .controlSize(.large)
                
                Button {
                    music.exportPresets()
                } label: {
                    Label(L10n.exportPresets, systemImage: "square.and.arrow.up")
                }
                .controlSize(.large)
                .disabled(music.presets.isEmpty)
                
                Button {
                    music.importPresets()
                } label: {
                    Label(L10n.importPresets, systemImage: "square.and.arrow.down")
                }
                .controlSize(.large)
            }
            
            if music.presets.isEmpty {
                ContentUnavailableView(
                    L10n.noPresets,
                    systemImage: "square.stack",
                    description: Text(L10n.createFirstPreset)
                )
            } else {
                ForEach(music.presets) { preset in
                    HStack {
                        Image(systemName: preset.settings.effect.symbol)
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.headline)
                            Text("\(preset.settings.effect.localizedName) · \(L10n.current == .ru ? "Интенсивность" : "Intensity") \(Int(preset.settings.intensity * 100))%")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(L10n.applyPreset) {
                            music.settings = preset.settings
                            section = .overview
                        }
                        
                        Button(role: .destructive) {
                            music.presets.removeAll { $0.id == preset.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .help(L10n.deletePreset)
                    }
                    .padding(18)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder))
                }
            }
        }
    }
}
