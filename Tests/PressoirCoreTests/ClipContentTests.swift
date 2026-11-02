import Foundation
import Testing

@testable import PressoirCore

@Suite("Contenu d'un élément : texte ou image")
struct ClipContentTests {
    private func image(digest: String) -> ImageRef {
        ImageRef(blobId: UUID(), digest: digest, pixelWidth: 10, pixelHeight: 20, byteCount: 300)
    }

    @Test("Un historique enregistré avant les images (champ « text ») se relit en texte")
    func decodesLegacyTextItems() throws {
        let legacy = """
            {"capacity":50,"items":[{"id":"6F1C2B9E-6F59-4C2D-9C55-3E1A0B9C7D11",
            "text":"ancien","copiedAt":"2026-10-23T08:00:00Z","isPinned":true}]}
            """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let history = try decoder.decode(ClipHistory.self, from: Data(legacy.utf8))

        #expect(history.items.first?.content == .text("ancien"))
        #expect(history.items.first?.isPinned == true)
    }

    @Test("Une image fait l'aller-retour JSON à l'identique")
    func imageRoundTrips() throws {
        let item = ClipItem(content: .image(image(digest: "abc")), copiedAt: Date(timeIntervalSince1970: 0))

        let data = try JSONEncoder().encode(item)

        #expect(try JSONDecoder().decode(ClipItem.self, from: data) == item)
    }

    @Test("Deux images sont « la même copie » si leur empreinte est identique")
    func imagesMatchByDigest() {
        #expect(ClipContent.image(image(digest: "x")).isSameCopy(as: .image(image(digest: "x"))))
        #expect(!ClipContent.image(image(digest: "x")).isSameCopy(as: .image(image(digest: "y"))))
        #expect(!ClipContent.text("x").isSameCopy(as: .image(image(digest: "x"))))
    }
}
