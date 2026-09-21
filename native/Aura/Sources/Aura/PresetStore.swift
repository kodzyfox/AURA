import AppKit
import Foundation
import UniformTypeIdentifiers

/// Persistence and file export/import boundary for locally stored atmosphere presets.
@MainActor final class PresetStore {
    static let shared = PresetStore()
    private let key = "aura.presets"
    private init() {}

    func load() -> [SavedPreset] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let presets = try? JSONDecoder().decode([SavedPreset].self, from: data) else { return [] }
        return presets
    }

    func save(_ presets: [SavedPreset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func addPreset(name: String, settings: Atmosphere, to presets: inout [SavedPreset]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newPreset = SavedPreset(name: trimmed, settings: settings)
        presets.insert(newPreset, at: 0)
        save(presets)
    }

    func deletePreset(id: UUID, from presets: inout [SavedPreset]) {
        presets.removeAll { $0.id == id }
        save(presets)
    }

    /// Экспорт пресетов в файл .json через системный диалог сохранения macOS
    func exportPresetsToFile(presets: [SavedPreset]) -> Bool {
        guard !presets.isEmpty else { return false }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(presets) else { return false }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        let dateStr = ISO8601DateFormatter().string(from: Date()).prefix(10)
        panel.nameFieldStringValue = "Aura_Presets_\(dateStr).json"
        panel.prompt = L10n.current == .ru ? "Экспортировать" : "Export"
        panel.message = L10n.current == .ru ? "Сохраните файл пресетов Aura на диск" : "Save Aura presets file to disk"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url, options: .atomic)
                return true
            } catch {
                print("Failed to export presets: \(error)")
                return false
            }
        }
        return false
    }

    /// Импорт пресетов из файла .json через диалог выбора файлов
    func importPresetsFromFile(into presets: inout [SavedPreset]) -> Int {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = L10n.current == .ru ? "Импортировать" : "Import"
        panel.message = L10n.current == .ru ? "Выберите файл пресетов Aura (.json)" : "Select an Aura presets file (.json)"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let imported = try JSONDecoder().decode([SavedPreset].self, from: data)
                var count = 0
                for item in imported {
                    if !presets.contains(where: { $0.id == item.id || $0.name == item.name }) {
                        presets.append(item)
                        count += 1
                    }
                }
                save(presets)
                return count
            } catch {
                print("Failed to import presets: \(error)")
                return -1
            }
        }
        return 0
    }
}
