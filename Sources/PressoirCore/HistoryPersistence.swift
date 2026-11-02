import Foundation

/// Persists a new history state: the history first, then the image files it no
/// longer references. If the history cannot be saved, no image is deleted, so the
/// file on disk never points to a missing picture.
public struct HistoryPersistence: Sendable {
    private let history: any HistoryStore
    private let images: any ImageStore

    public init(history: any HistoryStore, images: any ImageStore) {
        self.history = history
        self.images = images
    }

    public func commit(_ next: ClipHistory) throws(HistoryStoreError) {
        try history.save(next)
        try images.retainOnly(next.imageBlobIds)
    }

    public func imageData(_ ref: ImageRef) throws(HistoryStoreError) -> Data {
        try images.load(ref.blobId)
    }
}
