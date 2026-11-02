import CryptoKit
import Foundation

/// Port: the Keychain, split so that reading never creates a key by accident.
public protocol KeyStore: Sendable {
    func existingKey() throws(HistoryStoreError) -> SymmetricKey?
    func createKey() throws(HistoryStoreError) -> SymmetricKey
}

/// The key resolved once at launch, handed to the stores (no Keychain round-trip
/// per save).
public struct ResolvedKey: EncryptionKeyProvider {
    private let symmetricKey: SymmetricKey

    public init(_ symmetricKey: SymmetricKey) {
        self.symmetricKey = symmetricKey
    }

    public func key() throws(HistoryStoreError) -> SymmetricKey { symmetricKey }
}

public enum VaultStatus: Equatable, Sendable {
    case ready
    /// Existing data could not be read; it was moved to this folder, untouched.
    case quarantined(URL)
    /// The Keychain refused to answer; nothing is read or written this session.
    case locked(String)
}

public struct OpenedVault: Sendable {
    public let history: ClipHistory
    /// Nil when locked: the app then keeps the history in memory only.
    public let keyProvider: ResolvedKey?
    public let status: VaultStatus
}

/// Use case run once at launch. Its one rule: data that cannot be read is never
/// overwritten. A new key is only created when there is nothing to lose, or after
/// the unreadable data has been moved aside.
public struct VaultOpener: Sendable {
    private let historyURL: URL
    private let imagesDirectory: URL
    private let keyStore: any KeyStore

    public init(historyURL: URL, imagesDirectory: URL, keyStore: any KeyStore) {
        self.historyURL = historyURL
        self.imagesDirectory = imagesDirectory
        self.keyStore = keyStore
    }

    public func open(at date: Date) -> OpenedVault {
        let existing: SymmetricKey?
        do {
            existing = try keyStore.existingKey()
        } catch {
            return Self.locked(ErrorSummary.of(error))
        }
        guard let existing else { return openWithoutKey(at: date) }
        return openWithKey(existing, at: date)
    }

    private func openWithoutKey(at date: Date) -> OpenedVault {
        var status = VaultStatus.ready
        if hasStoredData() {
            guard let folder = quarantine(at: date) else { return Self.locked("mise de côté impossible") }
            status = .quarantined(folder)
        }
        do {
            return OpenedVault(
                history: ClipHistory(), keyProvider: ResolvedKey(try keyStore.createKey()), status: status)
        } catch {
            return Self.locked(ErrorSummary.of(error))
        }
    }

    private func openWithKey(_ key: SymmetricKey, at date: Date) -> OpenedVault {
        let provider = ResolvedKey(key)
        do {
            let history = try EncryptedHistoryStore(fileURL: historyURL, keyProvider: provider).load()
            return OpenedVault(history: history ?? ClipHistory(), keyProvider: provider, status: .ready)
        } catch {
            guard let folder = quarantine(at: date) else { return Self.locked("mise de côté impossible") }
            return OpenedVault(history: ClipHistory(), keyProvider: provider, status: .quarantined(folder))
        }
    }

    private func hasStoredData() -> Bool {
        let manager = FileManager.default
        let images = (try? manager.contentsOfDirectory(atPath: imagesDirectory.path)) ?? []
        return manager.fileExists(atPath: historyURL.path) || !images.isEmpty
    }

    /// Moves the history file and the images folder into `quarantaine-<date>/`.
    private func quarantine(at date: Date) -> URL? {
        let manager = FileManager.default
        let folder = historyURL.deletingLastPathComponent()
            .appendingPathComponent("quarantaine-\(Self.stamp(date))", isDirectory: true)
        do {
            try manager.createDirectory(at: folder, withIntermediateDirectories: true)
            for source in [historyURL, imagesDirectory] where manager.fileExists(atPath: source.path) {
                try manager.moveItem(at: source, to: folder.appendingPathComponent(source.lastPathComponent))
            }
            return folder
        } catch {
            return nil
        }
    }

    private static func stamp(_ date: Date) -> String {
        date.ISO8601Format(.iso8601.year().month().day().time(includingFractionalSeconds: false))
            .replacingOccurrences(of: ":", with: "")
    }

    private static func locked(_ reason: String) -> OpenedVault {
        OpenedVault(history: ClipHistory(), keyProvider: nil, status: .locked(reason))
    }
}
