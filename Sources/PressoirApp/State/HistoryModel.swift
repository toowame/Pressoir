import Foundation
import Observation
import PressoirCore

/// Application service: applies a command to the history, then persists it.
@MainActor
@Observable
final class HistoryModel {
    private(set) var history: ClipHistory
    private let store: any HistoryStore

    init(store: any HistoryStore) {
        self.store = store
        self.history = Self.loadOrStartEmpty(from: store)
    }

    func record(_ text: String) { apply(history.recording(text, at: Date())) }

    func togglePin(_ id: ClipItem.ID) { apply(history.togglingPin(id)) }

    func remove(_ id: ClipItem.ID) { apply(history.removing(id)) }

    func clearUnpinned() { apply(history.clearingUnpinned()) }

    private func apply(_ next: ClipHistory) {
        guard next != history else { return }
        history = next
        do {
            try store.save(next)
        } catch {
            Log.write("Sauvegarde de l'historique impossible : \(error)")
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
