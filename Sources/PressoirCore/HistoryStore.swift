import CryptoKit
import Foundation

public enum HistoryStoreError: Error, Equatable {
    case unreadable(String)
    case unwritable(String)
    case keyUnavailable(String)
}

/// Port: where the history survives a restart.
public protocol HistoryStore: Sendable {
    func load() throws(HistoryStoreError) -> ClipHistory?
    func save(_ history: ClipHistory) throws(HistoryStoreError)
}

/// Port: the secret that encrypts the history file (the Keychain in the app).
public protocol EncryptionKeyProvider: Sendable {
    func key() throws(HistoryStoreError) -> SymmetricKey
}

/// Adapter: the history as one AES-256-GCM sealed file (random nonce per save,
/// authenticated, so a tampered or foreign file is rejected), readable by the
/// user only. Nothing copied ever reaches the disk in clear.
public struct EncryptedHistoryStore: HistoryStore {
    private static let privatePermissions = 0o600

    private let fileURL: URL
    private let keyProvider: any EncryptionKeyProvider

    public init(fileURL: URL, keyProvider: any EncryptionKeyProvider) {
        self.fileURL = fileURL
        self.keyProvider = keyProvider
    }

    public static func defaultLocation() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Pressoir", isDirectory: true)
            .appendingPathComponent("history.enc")
    }

    public func load() throws(HistoryStoreError) -> ClipHistory? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let key = try keyProvider.key()
        do {
            let box = try AES.GCM.SealedBox(combined: Data(contentsOf: fileURL))
            return try HistoryCodec.decode(AES.GCM.open(box, using: key))
        } catch {
            throw .unreadable("\(fileURL.lastPathComponent): \(error)")
        }
    }

    public func save(_ history: ClipHistory) throws(HistoryStoreError) {
        let key = try keyProvider.key()
        do {
            guard let sealed = try AES.GCM.seal(HistoryCodec.encode(history), using: key).combined else {
                throw HistoryStoreError.unwritable("nonce non standard")
            }
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try sealed.write(to: fileURL, options: [.atomic, .completeFileProtection])
            try FileManager.default.setAttributes(
                [.posixPermissions: Self.privatePermissions], ofItemAtPath: fileURL.path)
        } catch {
            throw .unwritable("\(fileURL.lastPathComponent): \(error)")
        }
    }
}

private enum HistoryCodec {
    static func encode(_ history: ClipHistory) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(history)
    }

    static func decode(_ data: Data) throws -> ClipHistory {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ClipHistory.self, from: data)
    }
}
