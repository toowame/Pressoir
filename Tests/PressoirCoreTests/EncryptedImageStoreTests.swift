import CryptoKit
import Foundation
import Testing

@testable import PressoirCore

private struct StaticKeys: EncryptionKeyProvider {
    let symmetricKey = SymmetricKey(size: .bits256)

    func key() throws(HistoryStoreError) -> SymmetricKey { symmetricKey }
}

@Suite("Stockage chiffré des images")
struct EncryptedImageStoreTests {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("pressoir-images-\(UUID().uuidString)", isDirectory: true)
    private let keys = StaticKeys()
    private let pngHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    private var store: EncryptedImageStore { EncryptedImageStore(directory: directory, keyProvider: keys) }

    private func files() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    }

    @Test("Une image sauvée est relue à l'identique")
    func roundTrips() throws {
        let id = UUID()
        let data = pngHeader + Data(repeating: 7, count: 100)

        try store.save(data, as: id)

        #expect(try store.load(id) == data)
    }

    @Test("Le fichier ne contient pas l'image en clair et son nom ne révèle rien du contenu")
    func fileIsOpaque() throws {
        let id = UUID()
        try store.save(pngHeader + Data(repeating: 7, count: 100), as: id)

        let file = try #require(try files().first)
        #expect(try Data(contentsOf: file).range(of: pngHeader) == nil)
        #expect(file.lastPathComponent == "\(id.uuidString).enc")
    }

    @Test("Les fichiers sont lisibles par l'utilisateur seul (0600)")
    func filesArePrivate() throws {
        try store.save(pngHeader, as: UUID())

        let file = try #require(try files().first)
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
    }

    @Test("Ne garder que certaines images supprime toutes les autres")
    func retainOnlyRemovesOthers() throws {
        let kept = UUID()
        let dropped = UUID()
        try store.save(pngHeader, as: kept)
        try store.save(pngHeader, as: dropped)

        try store.retainOnly([kept])

        #expect(try files().map(\.lastPathComponent) == ["\(kept.uuidString).enc"])
    }

    @Test("Ne rien garder sur un dossier absent ne lève pas d'erreur")
    func retainOnlyWithoutDirectory() throws {
        try store.retainOnly([])
    }

    @Test("Une image absente lève une erreur explicite")
    func missingImageThrows() {
        #expect(throws: HistoryStoreError.self) { try store.load(UUID()) }
    }
}

@Suite("Droits des dossiers de données")
struct DataDirectoryPermissionsTests {
    @Test("Le dossier créé pour un fichier scellé n'est accessible qu'à l'utilisateur (0700)")
    func directoryIsPrivate() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("pressoir-perms-\(UUID().uuidString)", isDirectory: true)
        try EncryptedImageStore(directory: directory, keyProvider: ResolvedKey(.init(size: .bits256)))
            .save(Data([1]), as: UUID())

        let attributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o700)
    }
}
