import Foundation
import AppKit

/// Читает информацию о текущем треке из браузерного плеера (Brave/Chrome/Safari)
/// через AppleScript. Ищет вкладку по URL-домену (music.youtube.com, music.yandex.ru).
///
/// YouTube Music — заголовок вкладки: «Track Title - Artist Name - YouTube Music»
/// Яндекс Музыка  — заголовок вкладки: «Track Title — Artist Name — Яндекс Музыка»
actor BrowserPlayerService {
    static let shared = BrowserPlayerService()
    private init() {}

    // MARK: - Brave Browser AppleScript

    /// Возвращает снимок текущего состояния плеера для заданного домена
    func fetchSnapshot(source: Source) async -> PlayerSnapshot? {
        guard let domain = source.browserTabDomain else { return nil }
        guard !NSRunningApplication.runningApplications(withBundleIdentifier: "com.brave.Browser").isEmpty else {
            return nil
        }
        guard let tabTitle = await fetchBraveTabTitle(domain: domain) else { return nil }
        return parseTitle(tabTitle, source: source)
    }

    /// Управление воспроизведением: пробел (Play/Pause) через JS-клавишу в активной вкладке
    func playPause(source: Source) async {
        guard let domain = source.browserTabDomain else { return }
        let script = """
        tell application "Brave Browser"
            set targetTab to missing value
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "\(domain)" then
                        set targetTab to t
                        set current tab of w to t
                        exit repeat
                    end if
                end repeat
                if targetTab is not missing value then exit repeat
            end repeat
            if targetTab is not missing value then
                execute targetTab javascript "document.dispatchEvent(new KeyboardEvent('keydown', {keyCode: 32, which: 32, key: ' ', bubbles: true}))"
            end if
        end tell
        """
        _ = try? await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var err: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&err)
                cont.resume(returning: true)
            }
        }
    }

    /// Следующий трек
    func nextTrack(source: Source) async {
        await sendMediaKey(source: source, js: "document.querySelector('[aria-label=\"Next\"]')?.click() || document.querySelector('[aria-label=\"Следующий\"]')?.click()")
    }

    /// Предыдущий трек
    func prevTrack(source: Source) async {
        await sendMediaKey(source: source, js: "document.querySelector('[aria-label=\"Previous\"]')?.click() || document.querySelector('[aria-label=\"Предыдущий\"]')?.click()")
    }

    // MARK: - Приватные хелперы

    private func fetchBraveTabTitle(domain: String) async -> String? {
        let script = """
        tell application "Brave Browser"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "\(domain)" then
                        return title of t
                    end if
                end repeat
            end repeat
            return ""
        end tell
        """
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                var err: NSDictionary?
                let result = NSAppleScript(source: script)?.executeAndReturnError(&err)
                let title = result?.stringValue ?? ""
                cont.resume(returning: title.isEmpty ? nil : title)
            }
        }
    }

    private func sendMediaKey(source: Source, js: String) async {
        guard let domain = source.browserTabDomain else { return }
        let script = """
        tell application "Brave Browser"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "\(domain)" then
                        execute t javascript "\(js)"
                        exit repeat
                    end if
                end repeat
            end repeat
        end tell
        """
        _ = try? await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var err: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&err)
                cont.resume(returning: true)
            }
        }
    }

    // MARK: - Парсинг заголовка вкладки

    /// Разбирает заголовок вкладки браузера в PlayerSnapshot
    /// YouTube Music:  «Track - Artist - YouTube Music»
    /// Яндекс Музыка:  «Track — Artist — Яндекс Музыка» или «Track - Artist - Яндекс Музыка»
    private func parseTitle(_ rawTitle: String, source: Source) -> PlayerSnapshot? {
        // Удаляем суффикс сервиса
        let suffixes = [" - YouTube Music", " — YouTube Music",
                        " - Яндекс Музыка", " — Яндекс Музыка",
                        " - Yandex Music", " — Yandex Music"]
        var title = rawTitle
        for suffix in suffixes {
            if title.hasSuffix(suffix) {
                title = String(title.dropLast(suffix.count))
                break
            }
        }

        // Разбиваем по первому разделителю (» или - или —)
        let separators = [" – ", " — ", " - "]
        var trackName = title
        var artistName = ""

        for sep in separators {
            let parts = title.components(separatedBy: sep)
            if parts.count >= 2 {
                trackName = parts[0].trimmingCharacters(in: .whitespaces)
                artistName = parts[1...].joined(separator: sep).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // Если не смогли разобрать — возвращаем nil (страница не с музыкой)
        guard !trackName.isEmpty, !artistName.isEmpty else { return nil }

        // Яндекс Музыка показывает «Пауза» в заголовке когда пауза: игнорируем такие страницы
        // (заголовок без разделителя - просто «Слушать музыку онлайн — Яндекс Музыка»)
        let appDisplayName = source == .youtubeMusic ? "YouTube Music" : "Яндекс Музыка"

        return PlayerSnapshot(
            title: trackName,
            artist: artistName,
            duration: 0,        // браузер не отдаёт длительность через AppleScript
            position: 0,        // позиция тоже недоступна
            isPlaying: true,    // если вкладка активна с музыкой — считаем что играет
            artworkURL: nil,
            trackId: nil,
            appName: appDisplayName
        )
    }
}
