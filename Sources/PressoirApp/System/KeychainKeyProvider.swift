import CryptoKit
import Foundation
import PressoirCore
import Security

/// The history key lives in the login Keychain, never on disk next to the file.
/// Created on first use (256 random bits), bound to this Mac
/// (`ThisDeviceOnly`: not synced to iCloud, not restored on another machine).
struct KeychainKeyProvider: EncryptionKeyProvider {
    private static let service = "io.github.toowame.Pressoir"
    private static let account = "history-encryption-key"

    func key() throws(HistoryStoreError) -> SymmetricKey {
        if let existing = try Self.read() { return SymmetricKey(data: existing) }
        let fresh = SymmetricKey(size: .bits256)
        try Self.store(fresh.withUnsafeBytes { Data($0) })
        return fresh
    }

    private static var baseQuery: [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
    }

    private static func read() throws(HistoryStoreError) -> Data? {
        var query = baseQuery
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw .keyUnavailable("lecture Trousseau, OSStatus \(status)")
        }
    }

    private static func store(_ data: Data) throws(HistoryStoreError) {
        var attributes = baseQuery
        attributes[kSecValueData] = data
        attributes[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        attributes[kSecAttrLabel] = "Pressoir — clé de l'historique"
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw .keyUnavailable("écriture Trousseau, OSStatus \(status)") }
    }
}
