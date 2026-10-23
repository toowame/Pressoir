import Testing

@testable import PressoirCore

@Suite("Aperçu d'une ligne")
struct ClipPreviewTests {
    @Test("Les retours à la ligne et espaces multiples sont fondus en un espace")
    func collapsesWhitespace() {
        #expect(ClipPreview.line(for: "  un\n\n deux\tTrois  ", maxLength: 50) == "un deux Trois")
    }

    @Test("Un texte trop long est tronqué avec une ellipse")
    func truncatesLongText() {
        #expect(ClipPreview.line(for: "abcdefghij", maxLength: 5) == "abcd…")
    }

    @Test("Un texte à la longueur exacte n'est pas tronqué")
    func keepsExactLength() {
        #expect(ClipPreview.line(for: "abcde", maxLength: 5) == "abcde")
    }

    @Test("Le nombre de lignes est compté pour les textes multi-lignes")
    func countsLines() {
        #expect(ClipPreview.lineCount(of: "a\nb\r\nc") == 3)
        #expect(ClipPreview.lineCount(of: "seul") == 1)
    }
}
