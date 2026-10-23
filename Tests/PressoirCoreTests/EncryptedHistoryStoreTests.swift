import CryptoKit
import Foundation
import Testing

@testable import PressoirCore

private struct FixedKeyProvider: EncryptionKeyProvider {
    let symmetricKey: SymmetricKey

    func key() throws(HistoryStoreError) -> SymmetricKey { symmetricKey }
}

private struct FailingKeyProvider: EncryptionKeyProvider {
    func key() throws(HistoryStoreError) -> SymmetricKey { throw .keyUnavailable("trousseau verrouillé") }
}

@Suite("Persistance chiffrée de l'historique")
struct EncryptedHistoryStoreTests {
    private let directory: URL
    private let keys = FixedKeyProvider(symmetricKey: SymmetricKey(size: .bits256))

    init() {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("pressoir-tests-\(UUID().uuidString)", isDirectory: true)
    }

    private var fileURL: URL { directory.appendingPathComponent("history.enc") }

    private func sample() -> ClipHistory {
        ClipHistory(capacity: 5)
            .recording("IBAN FR76 3000 6000 0112 3456 7890 189", at: Date(timeIntervalSince1970: 1))
            .recording("deuxième", at: Date(timeIntervalSince1970: 2))
    }

    @Test("Ce qui est sauvé est relu à l'identique avec la même clé")
    func roundTrips() throws {
        let store = EncryptedHistoryStore(fileURL: fileURL, keyProvider: keys)
        let history = sample()

        try store.save(history)

        #expect(try store.load() == history)
    }

    @Test("Le fichier sur disque ne contient aucun texte copié en clair")
    func fileHoldsNoPlaintext() throws {
        try EncryptedHistoryStore(fileURL: fileURL, keyProvider: keys).save(sample())

        let raw = try Data(contentsOf: fileURL)
        for needle in ["IBAN", "FR76", "deuxième", "items", "copiedAt"] {
            #expect(raw.range(of: Data(needle.utf8)) == nil, "« \(needle) » lisible dans le fichier")
        }
    }

    @Test("Avec une autre clé, le fichier est illisible")
    func wrongKeyCannotRead() throws {
        try EncryptedHistoryStore(fileURL: fileURL, keyProvider: keys).save(sample())
        let intruder = EncryptedHistoryStore(
            fileURL: fileURL, keyProvider: FixedKeyProvider(symmetricKey: SymmetricKey(size: .bits256)))

        #expect(throws: HistoryStoreError.self) { try intruder.load() }
    }

    @Test("Un fichier altéré est rejeté (authentification GCM)")
    func tamperedFileIsRejected() throws {
        let store = EncryptedHistoryStore(fileURL: fileURL, keyProvider: keys)
        try store.save(sample())
        var bytes = try Data(contentsOf: fileURL)
        bytes[bytes.count - 1] ^= 0xFF
        try bytes.write(to: fileURL)

        #expect(throws: HistoryStoreError.self) { try store.load() }
    }

    @Test("Deux sauvegardes du même historique produisent des fichiers différents (nonce aléatoire)")
    func nonceIsFreshEachSave() throws {
        let store = EncryptedHistoryStore(fileURL: fileURL, keyProvider: keys)
        try store.save(sample())
        let first = try Data(contentsOf: fileURL)
        try store.save(sample())

        #expect(try Data(contentsOf: fileURL) != first)
    }

    @Test("Sans fichier, il n'y a pas d'historique")
    func missingFileLoadsNil() throws {
        #expect(try EncryptedHistoryStore(fileURL: fileURL, keyProvider: keys).load() == nil)
    }

    @Test("Le fichier n'est lisible que par l'utilisateur (0600)")
    func fileIsPrivate() throws {
        try EncryptedHistoryStore(fileURL: fileURL, keyProvider: keys).save(sample())

        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
    }

    @Test("Clé indisponible : ni lecture ni écriture, erreur explicite")
    func unavailableKeyFails() throws {
        try EncryptedHistoryStore(fileURL: fileURL, keyProvider: keys).save(sample())
        let store = EncryptedHistoryStore(fileURL: fileURL, keyProvider: FailingKeyProvider())

        #expect(throws: HistoryStoreError.keyUnavailable("trousseau verrouillé")) { try store.load() }
        #expect(throws: HistoryStoreError.keyUnavailable("trousseau verrouillé")) { try store.save(sample()) }
    }
}
