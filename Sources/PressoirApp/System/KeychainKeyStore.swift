import CryptoKit
import Foundation
import PressoirCore
import Security

/// The history key lives in the login Keychain, never on disk next to the file.
/// Reading and creating are separate on purpose: only `VaultOpener` decides when
/// a new key may be created (never while unreadable data exists).
/// `WhenUnlockedThisDeviceOnly`: not synced to iCloud, not restored on another Mac.
struct KeychainKeyStore: KeyStore {
    private static let service = "io.github.toowame.Pressoir"
    private static let account = "history-encryption-key"

    func existingKey() throws(HistoryStoreError) -> SymmetricKey? {
        try Self.read().map(SymmetricKey.init(data:))
    }

    func createKey() throws(HistoryStoreError) -> SymmetricKey {
        let fresh = SymmetricKey(size: .bits256)
        let status = Self.add(fresh.withUnsafeBytes { Data($0) })
        switch status {
        case errSecSuccess:
            return fresh
        case errSecDuplicateItem:
            // Another launch created it first: use that one, never overwrite it.
            guard let existing = try Self.read() else { throw .keyUnavailable("clé introuvable après doublon") }
            return SymmetricKey(data: existing)
        default:
            throw .keyUnavailable("écriture Trousseau, OSStatus \(status)")
        }
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

    private static func add(_ data: Data) -> OSStatus {
        var attributes = baseQuery
        attributes[kSecValueData] = data
        attributes[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        attributes[kSecAttrLabel] = "Pressoir — clé de l'historique"
        return SecItemAdd(attributes as CFDictionary, nil)
    }
}
