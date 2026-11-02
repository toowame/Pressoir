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
    private static let label = "Pressoir — clé de l'historique"

    func existingKey() throws(HistoryStoreError) -> SymmetricKey? {
        if let current = try Self.read() { return SymmetricKey(data: current) }
        return try Self.adoptKeyFromEarlierIdentifier().map(SymmetricKey.init(data:))
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

    private static func read(service name: String = service) throws(HistoryStoreError) -> Data? {
        var query = baseQuery
        query[kSecAttrService] = name
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

    /// Builds made before the app identifier changed stored the key under another
    /// service name. It is found by its account and label, copied under the current
    /// service, and the old entry is removed only once the copy exists.
    private static func adoptKeyFromEarlierIdentifier() throws(HistoryStoreError) -> Data? {
        guard let earlier = try earlierEntry() else { return nil }
        let status = add(earlier.data)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            Log.write("Reprise de la clé sous le nouvel identifiant impossible (OSStatus \(status))")
            return earlier.data
        }
        let removal: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: earlier.service, kSecAttrAccount: account,
        ]
        let removed = SecItemDelete(removal as CFDictionary)
        Log.write("Clé reprise sous le nouvel identifiant (ancienne entrée supprimée : OSStatus \(removed))")
        return earlier.data
    }

    /// macOS refuses to return the data of several items at once (errSecParam):
    /// the matching entries are listed by attributes, then the one key is read.
    private static func earlierEntry() throws(HistoryStoreError) -> (service: String, data: Data)? {
        let listing: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrAccount: account, kSecAttrLabel: label,
            kSecReturnAttributes: true, kSecMatchLimit: kSecMatchLimitAll,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(listing as CFDictionary, &result)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let entries = result as? [[CFString: Any]] else {
            throw .keyUnavailable("recherche de l'ancienne clé, OSStatus \(status)")
        }
        let services = entries.compactMap { $0[kSecAttrService] as? String }.filter { $0 != service }
        guard let earlier = services.first else { return nil }
        guard let data = try read(service: earlier) else { return nil }
        return (earlier, data)
    }

    private static func add(_ data: Data) -> OSStatus {
        var attributes = baseQuery
        attributes[kSecValueData] = data
        attributes[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        attributes[kSecAttrLabel] = label
        return SecItemAdd(attributes as CFDictionary, nil)
    }
}
