import CryptoKit
import Foundation
import Testing

@testable import PressoirCore

/// Keychain double: holds at most one key, can be made unreadable.
private final class FakeKeyStore: KeyStore, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: SymmetricKey?
    private let unreadable: Bool
    private(set) var createdCount = 0

    init(key: SymmetricKey? = nil, unreadable: Bool = false) {
        self.stored = key
        self.unreadable = unreadable
    }

    func existingKey() throws(HistoryStoreError) -> SymmetricKey? {
        if unreadable { throw .keyUnavailable("trousseau verrouillé") }
        return lock.withLock { stored }
    }

    func createKey() throws(HistoryStoreError) -> SymmetricKey {
        lock.withLock {
            createdCount += 1
            let key = SymmetricKey(size: .bits256)
            stored = key
            return key
        }
    }
}

@Suite("Ouverture du coffre : ne jamais écraser un historique illisible")
struct VaultOpenerTests {
    private let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("pressoir-vault-\(UUID().uuidString)", isDirectory: true)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var historyURL: URL { root.appendingPathComponent("history.enc") }
    private var imagesURL: URL { root.appendingPathComponent("images", isDirectory: true) }

    private func opener(_ keys: FakeKeyStore) -> VaultOpener {
        VaultOpener(historyURL: historyURL, imagesDirectory: imagesURL, keyStore: keys)
    }

    private func seed(with key: SymmetricKey) throws -> ClipHistory {
        let history = ClipHistory().recording("précieux", at: now)
        try EncryptedHistoryStore(fileURL: historyURL, keyProvider: ResolvedKey(key)).save(history)
        try EncryptedImageStore(directory: imagesURL, keyProvider: ResolvedKey(key)).save(Data([1, 2]), as: UUID())
        return history
    }

    private func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

    @Test("Premier lancement : une clé est créée, historique vide, prêt")
    func firstLaunchCreatesKey() {
        let keys = FakeKeyStore()

        let vault = opener(keys).open(at: now)

        #expect(vault.status == .ready)
        #expect(vault.history.items.isEmpty)
        #expect(vault.keyProvider != nil)
        #expect(keys.createdCount == 1)
    }

    @Test("Clé présente et fichier lisible : l'historique est rechargé, aucune clé créée")
    func reopensExistingHistory() throws {
        let key = SymmetricKey(size: .bits256)
        let saved = try seed(with: key)
        let keys = FakeKeyStore(key: key)

        let vault = opener(keys).open(at: now)

        #expect(vault.status == .ready)
        #expect(vault.history == saved)
        #expect(keys.createdCount == 0)
    }

    @Test("Clé disparue mais données présentes : tout est mis de côté avant de créer une clé")
    func missingKeyQuarantinesData() throws {
        _ = try seed(with: SymmetricKey(size: .bits256))
        let keys = FakeKeyStore()

        let vault = opener(keys).open(at: now)

        guard case .quarantined(let folder) = vault.status else {
            Issue.record("mise en quarantaine attendue, obtenu \(vault.status)")
            return
        }
        #expect(exists(folder.appendingPathComponent("history.enc")))
        #expect(exists(folder.appendingPathComponent("images")))
        #expect(!exists(historyURL))
        #expect(vault.history.items.isEmpty)
        #expect(keys.createdCount == 1)
    }

    @Test("Clé présente mais fichier indéchiffrable : il est mis de côté, la clé est gardée")
    func undecryptableFileQuarantined() throws {
        _ = try seed(with: SymmetricKey(size: .bits256))
        let keys = FakeKeyStore(key: SymmetricKey(size: .bits256))

        let vault = opener(keys).open(at: now)

        guard case .quarantined(let folder) = vault.status else {
            Issue.record("mise en quarantaine attendue, obtenu \(vault.status)")
            return
        }
        #expect(exists(folder.appendingPathComponent("history.enc")))
        #expect(keys.createdCount == 0)
    }

    @Test("Trousseau illisible : rien n'est touché ni enregistré (mode sans persistance)")
    func lockedKeychainTouchesNothing() throws {
        _ = try seed(with: SymmetricKey(size: .bits256))
        let keys = FakeKeyStore(unreadable: true)

        let vault = opener(keys).open(at: now)

        guard case .locked(let reason) = vault.status else {
            Issue.record("mode verrouillé attendu, obtenu \(vault.status)")
            return
        }
        #expect(reason.contains("trousseau verrouillé"))
        #expect(vault.keyProvider == nil)
        #expect(exists(historyURL))
        #expect(keys.createdCount == 0)
    }
}
