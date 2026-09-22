import XCTest
import CryptoKit
@testable import Aura

final class LastFMServiceTests: XCTestCase {
    
    @MainActor
    func testSignatureExcludesFormatAndCallback() {
        let service = LastFMService.shared
        
        let paramsWithFormat: [String: String] = [
            "method": "auth.getSession",
            "token": "testtoken123",
            "format": "json",
            "callback": "myCallback"
        ]
        
        let paramsWithoutFormat: [String: String] = [
            "method": "auth.getSession",
            "token": "testtoken123"
        ]
        
        let sig1 = service.createSignature(params: paramsWithFormat)
        let sig2 = service.createSignature(params: paramsWithoutFormat)
        
        // Сигнатура должна быть идентичной, так как format и callback исключаются
        XCTAssertEqual(sig1, sig2)
        XCTAssertEqual(sig1.count, 32) // MD5 даёт ровно 32 шестнадцатеричных символа
    }
    
    @MainActor
    func testSignatureKeysAreSortedAlphabetically() {
        let service = LastFMService.shared
        
        let params1: [String: String] = [
            "track": "Around the World",
            "artist": "Daft Punk",
            "api_key": "dummy_key"
        ]
        
        let params2: [String: String] = [
            "api_key": "dummy_key",
            "artist": "Daft Punk",
            "track": "Around the World"
        ]
        
        let sig1 = service.createSignature(params: params1)
        let sig2 = service.createSignature(params: params2)
        
        // Порядок добавления ключей в словарь не должен влиять на подпись
        XCTAssertEqual(sig1, sig2)
    }
}
