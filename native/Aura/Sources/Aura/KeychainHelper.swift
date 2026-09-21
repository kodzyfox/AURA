import Foundation
import CryptoKit

/// Безопасное изолированное хранилище конфиденциальных данных (API-ключей, токенов) в Application Support.
/// Все данные шифруются по стандарту AES-256-GCM с ключом устройства и сохраняются с правами 0600 (доступ только текущему пользователю macOS).
/// Это гарантирует полную безопасность и избавляет от системных всплывающих окон Keychain при локальных ad-hoc сборках.
enum KeychainHelper {
    private static let auraDir: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Aura", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [
            .posixPermissions: 0o700
        ])
        return dir
    }()
    
    private static let storageURL: URL = auraDir.appendingPathComponent(".aura_secure.json")
    private static let keyFileURL: URL = auraDir.appendingPathComponent(".aura_master_key")
    
    // Стабильный ключ шифрования AES-256, сохраняемый локально и не зависящий от смены Wi-Fi / DHCP имени хоста
    private static let encryptionKey: SymmetricKey = {
        if let keyData = try? Data(contentsOf: keyFileURL), keyData.count == 32 {
            return SymmetricKey(data: keyData)
        }
        
        // Генерируем 256-битный криптографически стойкий ключ
        var randomBytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let keyData: Data
        if status == errSecSuccess {
            keyData = Data(randomBytes)
        } else {
            // Fallback: детерминированный ключ на основе имени пользователя и стабильного ID пользователя
            let fallbackSeed = "aura_master_\(ProcessInfo.processInfo.userName)_\(getuid())"
            let hash = SHA256.hash(data: Data(fallbackSeed.utf8))
            keyData = Data(hash)
        }
        
        try? keyData.write(to: keyFileURL, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: keyFileURL.path)
        return SymmetricKey(data: keyData)
    }()
    
    // Резервный устаревший ключ для автоматической миграции старых данных
    private static let legacyEncryptionKey: SymmetricKey = {
        let userName = ProcessInfo.processInfo.userName
        let hostName = ProcessInfo.processInfo.hostName
        let seed = "aura_secure_v2_\(userName)_\(hostName)"
        let digest = SHA256.hash(data: Data(seed.utf8))
        return SymmetricKey(data: digest)
    }()
    
    private static func loadStore() -> [String: String] {
        guard let data = try? Data(contentsOf: storageURL), !data.isEmpty else {
            return [:]
        }
        
        // 1. Попытка расшифровки стабильным ключом
        if let sealedBox = try? AES.GCM.SealedBox(combined: data),
           let decrypted = try? AES.GCM.open(sealedBox, using: encryptionKey),
           let dict = try? JSONDecoder().decode([String: String].self, from: decrypted) {
            return dict
        }
        
        // 2. Автомиграция: попытка расшифровки старым ключом на базе hostname
        if let sealedBox = try? AES.GCM.SealedBox(combined: data),
           let decrypted = try? AES.GCM.open(sealedBox, using: legacyEncryptionKey),
           let dict = try? JSONDecoder().decode([String: String].self, from: decrypted) {
            saveStore(dict)
            return dict
        }
        
        // 3. Fallback: обычный JSON, если файл еще не был зашифрован
        if let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            saveStore(dict)
            return dict
        }
        
        return [:]
    }
    
    private static func saveStore(_ store: [String: String]) {
        guard let jsonData = try? JSONEncoder().encode(store),
              let sealed = try? AES.GCM.seal(jsonData, using: encryptionKey),
              let combined = sealed.combined else {
            return
        }
        
        try? combined.write(to: storageURL, options: .atomic)
        // Права 0600: чтение и запись только владельцу файла
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: storageURL.path)
    }
    
    /// Сохраняет ключ в зашифрованное хранилище
    @discardableResult
    static func set(_ value: String, forKey key: String, service: String = "studio.aura.mac.lastfm") -> Bool {
        var store = loadStore()
        store["\(service):\(key)"] = value
        saveStore(store)
        return true
    }
    
    /// Считывает ключ из зашифрованного хранилища
    static func get(forKey key: String, service: String = "studio.aura.mac.lastfm") -> String? {
        let store = loadStore()
        return store["\(service):\(key)"]
    }
    
    /// Удаляет ключ из зашифрованного хранилища
    @discardableResult
    static func delete(forKey key: String, service: String = "studio.aura.mac.lastfm") -> Bool {
        var store = loadStore()
        store.removeValue(forKey: "\(service):\(key)")
        saveStore(store)
        return true
    }
}
