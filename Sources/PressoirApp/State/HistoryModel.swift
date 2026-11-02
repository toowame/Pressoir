import AppKit
import Observation
import PressoirCore

/// Thin UI-facing wrapper: holds the current history, delegates each change to
/// the core (`ClipIntake`, `HistoryPersistence`) and caches thumbnails.
/// `persistence` is nil when the Keychain is unavailable: the history then lives
/// in memory only.
@MainActor
@Observable
final class HistoryModel {
    private(set) var history: ClipHistory
    let vaultStatus: VaultStatus
    private let images: any ImageStore
    private let intake: ClipIntake
    private let persistence: HistoryPersistence?
    @ObservationIgnored private var thumbnails: [UUID: NSImage] = [:]

    init(history: ClipHistory, vaultStatus: VaultStatus, images: any ImageStore, persistence: HistoryPersistence?) {
        self.history = history
        self.vaultStatus = vaultStatus
        self.images = images
        self.intake = ClipIntake(imageStore: images)
        self.persistence = persistence
    }

    func record(_ clip: CapturedClip) {
        do {
            apply(try intake.ingest(clip, into: history, at: Date()))
        } catch {
            Log.write("Copie non enregistrée : \(ErrorSummary.of(error))")
        }
    }

    /// A pasted entry moves back to the top, as if copied again.
    func markPasted(_ item: ClipItem) { apply(history.recording(item.content, at: Date())) }

    func togglePin(_ id: ClipItem.ID) { apply(history.togglingPin(id)) }

    func remove(_ id: ClipItem.ID) { apply(history.removing(id)) }

    func clearUnpinned() { apply(history.clearingUnpinned()) }

    func payload(for item: ClipItem) -> PastePayload? {
        switch item.content {
        case .text(let text): return .text(text)
        case .image(let ref): return imageData(ref).map(PastePayload.png)
        }
    }

    /// Decrypted once, then kept in memory as a small thumbnail.
    func thumbnail(for ref: ImageRef) -> NSImage? {
        if let cached = thumbnails[ref.blobId] { return cached }
        guard let thumbnail = imageData(ref).flatMap(ImageThumbnailer.thumbnail) else { return nil }
        thumbnails[ref.blobId] = thumbnail
        return thumbnail
    }

    private func imageData(_ ref: ImageRef) -> Data? {
        do {
            return try images.load(ref.blobId)
        } catch {
            Log.write("Image illisible : \(ErrorSummary.of(error))")
            return nil
        }
    }

    private func apply(_ next: ClipHistory) {
        guard next != history else { return }
        history = next
        thumbnails = thumbnails.filter { next.imageBlobIds.contains($0.key) }
        do {
            if let persistence {
                try persistence.commit(next)
            } else {
                try images.retainOnly(next.imageBlobIds)
            }
        } catch {
            Log.write("Sauvegarde de l'historique impossible : \(ErrorSummary.of(error))")
        }
    }
}
