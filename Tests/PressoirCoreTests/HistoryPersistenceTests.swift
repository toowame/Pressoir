import Foundation
import Testing

@testable import PressoirCore

private final class RecordingHistoryStore: HistoryStore, @unchecked Sendable {
    private let lock = NSLock()
    private let failing: Bool
    private var saved: [ClipHistory] = []

    init(failing: Bool = false) {
        self.failing = failing
    }

    var saveCount: Int { lock.withLock { saved.count } }

    func load() throws(HistoryStoreError) -> ClipHistory? { lock.withLock { saved.last } }

    func save(_ history: ClipHistory) throws(HistoryStoreError) {
        if failing { throw .unwritable("disque plein") }
        lock.withLock { saved.append(history) }
    }
}

@Suite("Persistance d'un changement d'historique")
struct HistoryPersistenceTests {
    private let picture = PasteboardImage(data: Data([1, 2, 3]), pixelWidth: 1, pixelHeight: 1)

    @Test("Un changement est sauvé, puis les images qui ne servent plus sont effacées")
    func savesThenPrunesImages() throws {
        let images = InMemoryImageStore()
        let history = RecordingHistoryStore()
        let withImage = try ClipIntake(imageStore: images).ingest(.image(picture), into: ClipHistory(), at: Date())
        let imageId = try #require(withImage.items.first?.id)

        try HistoryPersistence(history: history, images: images).commit(withImage.removing(imageId))

        #expect(history.saveCount == 1)
        #expect(images.savedCount == 0)
    }

    @Test("Si la sauvegarde échoue, aucune image n'est effacée")
    func failedSaveKeepsImages() throws {
        let images = InMemoryImageStore()
        let withImage = try ClipIntake(imageStore: images).ingest(.image(picture), into: ClipHistory(), at: Date())
        let imageId = try #require(withImage.items.first?.id)
        let persistence = HistoryPersistence(history: RecordingHistoryStore(failing: true), images: images)

        #expect(throws: HistoryStoreError.unwritable("disque plein")) {
            try persistence.commit(withImage.removing(imageId))
        }
        #expect(images.savedCount == 1)
    }
}
