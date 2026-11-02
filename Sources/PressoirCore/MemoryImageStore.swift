import Foundation

/// Adapter used when the Keychain is unavailable: images live in memory for the
/// session only, nothing touches the disk.
public final class MemoryImageStore: ImageStore, @unchecked Sendable {
    private let lock = NSLock()
    private var blobs: [UUID: Data] = [:]

    public init() {}

    public func save(_ data: Data, as blobId: UUID) throws(HistoryStoreError) {
        lock.withLock { blobs[blobId] = data }
    }

    public func load(_ blobId: UUID) throws(HistoryStoreError) -> Data {
        guard let data = lock.withLock({ blobs[blobId] }) else { throw .unreadable("image absente de la mémoire") }
        return data
    }

    public func retainOnly(_ blobIds: Set<UUID>) throws(HistoryStoreError) {
        lock.withLock { blobs = blobs.filter { blobIds.contains($0.key) } }
    }
}
