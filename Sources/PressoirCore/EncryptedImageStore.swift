import Foundation

/// Adapter: one sealed file per image, `<blobId>.enc`, in its own folder.
public struct EncryptedImageStore: ImageStore {
    private static let fileExtension = "enc"

    private let directory: URL
    private let keyProvider: any EncryptionKeyProvider

    public init(directory: URL, keyProvider: any EncryptionKeyProvider) {
        self.directory = directory
        self.keyProvider = keyProvider
    }

    public static func defaultDirectory() -> URL {
        EncryptedHistoryStore.defaultLocation().deletingLastPathComponent()
            .appendingPathComponent("images", isDirectory: true)
    }

    public func save(_ data: Data, as blobId: UUID) throws(HistoryStoreError) {
        let key = try keyProvider.key()
        do {
            try SealedFile.write(data, to: fileURL(for: blobId), key: key)
        } catch {
            throw .unwritable("image \(blobId.uuidString): \(error)")
        }
    }

    public func load(_ blobId: UUID) throws(HistoryStoreError) -> Data {
        let key = try keyProvider.key()
        do {
            return try SealedFile.read(fileURL(for: blobId), key: key)
        } catch {
            throw .unreadable("image \(blobId.uuidString): \(error)")
        }
    }

    public func retainOnly(_ blobIds: Set<UUID>) throws(HistoryStoreError) {
        let keptNames = Set(blobIds.map { fileURL(for: $0).lastPathComponent })
        do {
            for file in try storedFiles() where !keptNames.contains(file.lastPathComponent) {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            throw .unwritable("nettoyage des images : \(error)")
        }
    }

    private func storedFiles() throws -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == Self.fileExtension }
    }

    private func fileURL(for blobId: UUID) -> URL {
        directory.appendingPathComponent(blobId.uuidString).appendingPathExtension(Self.fileExtension)
    }
}
