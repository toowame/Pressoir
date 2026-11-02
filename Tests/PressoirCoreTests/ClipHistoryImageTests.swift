import Foundation
import Testing

@testable import PressoirCore

@Suite("Historique : images")
struct ClipHistoryImageTests {
    private let t0 = Date(timeIntervalSince1970: 1_000)
    private let t1 = Date(timeIntervalSince1970: 2_000)

    private func image(_ digest: String) -> ClipContent {
        .image(ImageRef(blobId: UUID(), digest: digest, pixelWidth: 1, pixelHeight: 1, byteCount: 1))
    }

    @Test("Recopier la même image la remonte sans doublon")
    func sameImageMovesToTop() {
        let history = ClipHistory(capacity: 10)
            .recording(image("x"), at: t0)
            .recording("texte", at: t0)
            .recording(image("x"), at: t1)

        #expect(history.items.count == 2)
        #expect(history.items.first?.content.isSameCopy(as: image("x")) == true)
    }

    @Test("Une recherche non vide ne remonte pas les images")
    func searchSkipsImages() {
        let history = ClipHistory(capacity: 10)
            .recording(image("x"), at: t0)
            .recording("Image de test", at: t1)

        #expect(history.ordered(matching: "image").map(\.text) == ["Image de test"])
        #expect(history.ordered(matching: "").count == 2)
    }

    @Test("Les fichiers d'image à garder sont exactement ceux encore dans l'historique")
    func imageBlobIdsFollowEviction() throws {
        let first = image("a")
        let history = ClipHistory(capacity: 1)
            .recording(first, at: t0)
            .recording(image("b"), at: t1)

        guard case .image(let kept) = try #require(history.items.first?.content) else {
            Issue.record("une image était attendue")
            return
        }
        #expect(history.imageBlobIds == [kept.blobId])
    }
}
