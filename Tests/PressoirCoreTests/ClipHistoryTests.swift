import Foundation
import Testing

@testable import PressoirCore

@Suite("Historique du presse-papier")
struct ClipHistoryTests {
    private let t0 = Date(timeIntervalSince1970: 1_000)
    private let t1 = Date(timeIntervalSince1970: 2_000)
    private let t2 = Date(timeIntervalSince1970: 3_000)

    @Test("Un texte copié arrive en tête")
    func recordingPutsNewestFirst() {
        let history = ClipHistory(capacity: 10)
            .recording("a", at: t0)
            .recording("b", at: t1)

        #expect(history.items.map(\.text) == ["b", "a"])
    }

    @Test("Un texte vide ou fait d'espaces est ignoré", arguments: ["", "   ", "\n\t "])
    func blankTextIsIgnored(text: String) {
        let history = ClipHistory(capacity: 10).recording(text, at: t0)

        #expect(history.items.isEmpty)
    }

    @Test("Recopier un texte existant le remonte sans le dupliquer et garde son identité")
    func recordingExistingTextMovesItToTop() throws {
        let initial = ClipHistory(capacity: 10)
            .recording("a", at: t0)
            .recording("b", at: t1)
        let originalId = try #require(initial.items.last?.id)

        let history = initial.recording("a", at: t2)

        #expect(history.items.map(\.text) == ["a", "b"])
        #expect(history.items.first?.id == originalId)
        #expect(history.items.first?.copiedAt == t2)
    }

    @Test("Au-delà de la capacité, le plus ancien non épinglé sort ; les épinglés ne comptent pas")
    func capacityEvictsOldestUnpinned() throws {
        let start = ClipHistory(capacity: 2).recording("a", at: t0)
        let pinned = start.togglingPin(try #require(start.items.first?.id))

        let history =
            pinned
            .recording("b", at: t1)
            .recording("c", at: t2)
            .recording("d", at: t2)

        #expect(history.items.map(\.text) == ["d", "c", "a"])
    }

    @Test("L'enregistrement ne mute jamais l'historique d'origine")
    func recordingIsImmutable() {
        let original = ClipHistory(capacity: 10).recording("a", at: t0)

        _ = original.recording("b", at: t1)

        #expect(original.items.map(\.text) == ["a"])
    }

    @Test("Les épinglés s'affichent en premier, puis le reste par récence")
    func orderedShowsPinnedFirst() throws {
        let base = ClipHistory(capacity: 10)
            .recording("a", at: t0)
            .recording("b", at: t1)
            .recording("c", at: t2)
        let aId = try #require(base.items.first { $0.text == "a" }?.id)

        let history = base.togglingPin(aId)

        #expect(history.ordered(matching: "").map(\.text) == ["a", "c", "b"])
    }

    @Test("La recherche filtre sans tenir compte de la casse ni des accents")
    func orderedFiltersByQuery() {
        let history = ClipHistory(capacity: 10)
            .recording("Réunion lundi", at: t0)
            .recording("Facture 2026", at: t1)

        #expect(history.ordered(matching: "reunion").map(\.text) == ["Réunion lundi"])
        #expect(history.ordered(matching: "  ").count == 2)
    }

    @Test("Épingler deux fois revient à l'état initial")
    func togglingPinTwiceRestores() throws {
        let history = ClipHistory(capacity: 10).recording("a", at: t0)
        let id = try #require(history.items.first?.id)

        #expect(history.togglingPin(id).items.first?.isPinned == true)
        #expect(history.togglingPin(id).togglingPin(id) == history)
    }

    @Test("Supprimer retire uniquement l'élément visé")
    func removingDropsOnlyTarget() throws {
        let history = ClipHistory(capacity: 10)
            .recording("a", at: t0)
            .recording("b", at: t1)
        let bId = try #require(history.items.first?.id)

        #expect(history.removing(bId).items.map(\.text) == ["a"])
    }

    @Test("Effacer garde les épinglés")
    func clearingKeepsPinned() throws {
        let base = ClipHistory(capacity: 10)
            .recording("a", at: t0)
            .recording("b", at: t1)
        let aId = try #require(base.items.last?.id)

        let history = base.togglingPin(aId).clearingUnpinned()

        #expect(history.items.map(\.text) == ["a"])
    }

    @Test("Une capacité inférieure à 1 est ramenée à 1")
    func capacityIsAtLeastOne() {
        let history = ClipHistory(capacity: 0)
            .recording("a", at: t0)
            .recording("b", at: t1)

        #expect(history.capacity == 1)
        #expect(history.items.map(\.text) == ["b"])
    }
}
