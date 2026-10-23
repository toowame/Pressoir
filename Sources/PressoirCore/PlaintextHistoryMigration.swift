import Foundation

/// One-shot move of the pre-encryption `history.json` into the encrypted store.
/// The plaintext file is removed only once its content is safely re-saved,
/// since keeping it would defeat the encryption.
public struct PlaintextHistoryMigration: Sendable {
    private let legacyURL: URL

    public init(legacyURL: URL) {
        self.legacyURL = legacyURL
    }

    public static func defaultLegacyLocation() -> URL {
        EncryptedHistoryStore.defaultLocation().deletingLastPathComponent().appendingPathComponent("history.json")
    }

    public func run(into store: any HistoryStore) throws(HistoryStoreError) {
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }
        try store.save(try readLegacy())
        do {
            try FileManager.default.removeItem(at: legacyURL)
        } catch {
            throw .unwritable("suppression de \(legacyURL.lastPathComponent): \(error)")
        }
    }

    private func readLegacy() throws(HistoryStoreError) -> ClipHistory {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ClipHistory.self, from: Data(contentsOf: legacyURL))
        } catch {
            throw .unreadable("\(legacyURL.lastPathComponent): \(error)")
        }
    }
}
