import Foundation
import Testing

@testable import PressoirCore

/// Test double; the lock makes it safe to share across test isolation domains.
final class InMemoryImageStore: ImageStore, @unchecked Sendable {
    private let lock = NSLock()
    private var blobs: [UUID: Data] = [:]
    private let failing: Bool

    init(failing: Bool = false) {
        self.failing = failing
    }

    var savedCount: Int { lock.withLock { blobs.count } }

    func save(_ data: Data, as blobId: UUID) throws(HistoryStoreError) {
        if failing { throw .unwritable("disque plein") }
        lock.withLock { blobs[blobId] = data }
    }

    func load(_ blobId: UUID) throws(HistoryStoreError) -> Data {
        guard let data = lock.withLock({ blobs[blobId] }) else { throw .unreadable("absent") }
        return data
    }

    func retainOnly(_ blobIds: Set<UUID>) throws(HistoryStoreError) {
        lock.withLock { blobs = blobs.filter { blobIds.contains($0.key) } }
    }
}

@Suite("Entrée d'une copie dans l'historique")
struct ClipIntakeTests {
    private let now = Date(timeIntervalSince1970: 5_000)
    private let picture = PasteboardImage(
        data: Data([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]), pixelWidth: 640, pixelHeight: 480)

    @Test("Un texte entre tel quel")
    func ingestsText() throws {
        let history = try ClipIntake(imageStore: InMemoryImageStore()).ingest(
            .text("bonjour"), into: ClipHistory(), at: now)

        #expect(history.items.first?.content == .text("bonjour"))
    }

    @Test("Une image est rangée dans le stockage et référencée avec ses dimensions")
    func ingestsImage() throws {
        let store = InMemoryImageStore()

        let history = try ClipIntake(imageStore: store).ingest(.image(picture), into: ClipHistory(), at: now)

        guard case .image(let ref) = history.items.first?.content else {
            Issue.record("une image était attendue")
            return
        }
        #expect(ref.pixelWidth == 640 && ref.pixelHeight == 480 && ref.byteCount == picture.data.count)
        #expect(try store.load(ref.blobId) == picture.data)
    }

    @Test("La même image recopiée n'est stockée qu'une fois")
    func duplicateImageStoredOnce() throws {
        let store = InMemoryImageStore()
        let intake = ClipIntake(imageStore: store)

        let once = try intake.ingest(.image(picture), into: ClipHistory(), at: now)
        let twice = try intake.ingest(.image(picture), into: once.recording("entre-deux", at: now), at: now)

        #expect(store.savedCount == 1)
        #expect(twice.items.count == 2)
        #expect(twice.items.first?.text == nil)
    }

    @Test("Une image trop lourde est ignorée")
    func oversizedImageIgnored() throws {
        let store = InMemoryImageStore()
        let huge = PasteboardImage(data: Data(count: ClipIntake.maxImageBytes + 1), pixelWidth: 1, pixelHeight: 1)

        let history = try ClipIntake(imageStore: store).ingest(.image(huge), into: ClipHistory(), at: now)

        #expect(history.items.isEmpty)
        #expect(store.savedCount == 0)
    }

    @Test("Si l'image ne peut pas être stockée, l'erreur remonte et l'historique ne bouge pas")
    func storeFailurePropagates() {
        #expect(throws: HistoryStoreError.unwritable("disque plein")) {
            try ClipIntake(imageStore: InMemoryImageStore(failing: true))
                .ingest(.image(picture), into: ClipHistory(), at: now)
        }
    }
}
