import CryptoKit
import Foundation
import Testing

@testable import PressoirCore

private struct TestKeys: EncryptionKeyProvider {
    let symmetricKey = SymmetricKey(size: .bits256)

    func key() throws(HistoryStoreError) -> SymmetricKey { symmetricKey }
}

@Suite("Reprise de l'ancien historique en clair")
struct PlaintextHistoryMigrationTests {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("pressoir-migration-\(UUID().uuidString)", isDirectory: true)

    private var legacyURL: URL { directory.appendingPathComponent("history.json") }
    private var store: EncryptedHistoryStore {
        EncryptedHistoryStore(fileURL: directory.appendingPathComponent("history.enc"), keyProvider: TestKeys())
    }

    private func writeLegacy(_ history: ClipHistory) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(history).write(to: legacyURL)
    }

    @Test("L'ancien fichier est rechiffré puis supprimé, le contenu est conservé")
    func migratesAndRemovesPlaintext() throws {
        let legacy = ClipHistory(capacity: 5).recording("ancien", at: Date(timeIntervalSince1970: 1))
        try writeLegacy(legacy)
        let target = store

        try PlaintextHistoryMigration(legacyURL: legacyURL).run(into: target)

        #expect(try target.load() == legacy)
        #expect(!FileManager.default.fileExists(atPath: legacyURL.path))
    }

    @Test("Sans ancien fichier, rien ne se passe")
    func noLegacyIsNoop() throws {
        let target = store

        try PlaintextHistoryMigration(legacyURL: legacyURL).run(into: target)

        #expect(try target.load() == nil)
    }

    @Test("Un ancien fichier illisible est laissé en place, erreur explicite")
    func corruptedLegacyIsKept() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("pas du json".utf8).write(to: legacyURL)

        #expect(throws: HistoryStoreError.self) {
            try PlaintextHistoryMigration(legacyURL: legacyURL).run(into: store)
        }
        #expect(FileManager.default.fileExists(atPath: legacyURL.path))
    }
}
