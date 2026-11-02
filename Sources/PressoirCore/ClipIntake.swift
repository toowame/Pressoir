import CryptoKit
import Foundation

/// An image read from the pasteboard, already normalised to PNG by the app.
public struct PasteboardImage: Equatable, Sendable {
    public let data: Data
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(data: Data, pixelWidth: Int, pixelHeight: Int) {
        self.data = data
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

public enum CapturedClip: Equatable, Sendable {
    case text(String)
    case image(PasteboardImage)
}

/// Port: where image bytes live, apart from the history.
public protocol ImageStore: Sendable {
    func save(_ data: Data, as blobId: UUID) throws(HistoryStoreError)
    func load(_ blobId: UUID) throws(HistoryStoreError) -> Data
    func retainOnly(_ blobIds: Set<UUID>) throws(HistoryStoreError)
}

/// Use case: turns a fresh pasteboard capture into the next history, storing an
/// image's bytes once (a re-copied picture reuses its existing file).
public struct ClipIntake: Sendable {
    /// Beyond this, a picture is skipped: the history is for everyday copies.
    public static let maxImageBytes = 20 * 1024 * 1024

    private let imageStore: any ImageStore

    public init(imageStore: any ImageStore) {
        self.imageStore = imageStore
    }

    public func ingest(_ clip: CapturedClip, into history: ClipHistory, at date: Date) throws(HistoryStoreError)
        -> ClipHistory
    {
        switch clip {
        case .text(let text): return history.recording(text, at: date)
        case .image(let image): return try ingestImage(image, into: history, at: date)
        }
    }

    private func ingestImage(_ image: PasteboardImage, into history: ClipHistory, at date: Date)
        throws(HistoryStoreError) -> ClipHistory
    {
        guard image.data.count <= Self.maxImageBytes else { return history }
        let digest = SHA256.hash(data: image.data).map { String(format: "%02x", $0) }.joined()
        let probe = ImageRef(
            blobId: UUID(), digest: digest, pixelWidth: image.pixelWidth, pixelHeight: image.pixelHeight,
            byteCount: image.data.count)
        if let existing = history.item(matching: .image(probe)) {
            return history.recording(existing.content, at: date)
        }
        try imageStore.save(image.data, as: probe.blobId)
        return history.recording(.image(probe), at: date)
    }
}
