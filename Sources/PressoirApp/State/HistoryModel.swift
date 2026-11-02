import AppKit
import Observation
import PressoirCore

/// Application service: applies a command to the history, persists it, and
/// deletes the image files the history no longer references.
@MainActor
@Observable
final class HistoryModel {
    private static let thumbnailMaxPixels: CGFloat = 240

    private(set) var history: ClipHistory
    private let store: any HistoryStore
    private let imageStore: any ImageStore
    private let intake: ClipIntake
    @ObservationIgnored private var thumbnails: [UUID: NSImage] = [:]

    init(store: any HistoryStore, imageStore: any ImageStore) {
        self.store = store
        self.imageStore = imageStore
        self.intake = ClipIntake(imageStore: imageStore)
        self.history = Self.loadOrStartEmpty(from: store)
    }

    func record(_ clip: CapturedClip) {
        do {
            apply(try intake.ingest(clip, into: history, at: Date()))
        } catch {
            Log.write("Copie non enregistrée : \(error)")
        }
    }

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
        guard let data = imageData(ref), let image = NSImage(data: data) else { return nil }
        let thumbnail = Self.downscaled(image)
        thumbnails[ref.blobId] = thumbnail
        return thumbnail
    }

    private func imageData(_ ref: ImageRef) -> Data? {
        do {
            return try imageStore.load(ref.blobId)
        } catch {
            Log.write("Image illisible : \(error)")
            return nil
        }
    }

    private func apply(_ next: ClipHistory) {
        guard next != history else { return }
        history = next
        thumbnails = thumbnails.filter { next.imageBlobIds.contains($0.key) }
        do {
            try store.save(next)
            try imageStore.retainOnly(next.imageBlobIds)
        } catch {
            Log.write("Sauvegarde de l'historique impossible : \(error)")
        }
    }

    private static func downscaled(_ image: NSImage) -> NSImage {
        let scale = min(1, thumbnailMaxPixels / max(image.size.width, image.size.height, 1))
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        return NSImage(size: size, flipped: false) { rect in
            image.draw(in: rect)
            return true
        }
    }

    private static func loadOrStartEmpty(from store: any HistoryStore) -> ClipHistory {
        do {
            return try store.load() ?? ClipHistory()
        } catch {
            // A corrupted file must not prevent the app from starting; the cause is logged.
            Log.write("Lecture de l'historique impossible, départ à vide : \(error)")
            return ClipHistory()
        }
    }
}
