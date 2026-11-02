import CryptoKit
import Foundation

/// One file on disk holding AES-256-GCM sealed bytes (random nonce per write,
/// authenticated), readable by the user only. Shared by every encrypted store.
enum SealedFile {
    private static let privatePermissions = 0o600

    static func write(_ plaintext: Data, to url: URL, key: SymmetricKey) throws {
        guard let sealed = try AES.GCM.seal(plaintext, using: key).combined else {
            throw HistoryStoreError.unwritable("nonce non standard")
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try sealed.write(to: url, options: [.atomic, .completeFileProtection])
        try FileManager.default.setAttributes([.posixPermissions: privatePermissions], ofItemAtPath: url.path)
    }

    static func read(_ url: URL, key: SymmetricKey) throws -> Data {
        try AES.GCM.open(AES.GCM.SealedBox(combined: Data(contentsOf: url)), using: key)
    }
}
