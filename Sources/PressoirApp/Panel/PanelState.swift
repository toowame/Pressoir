import Observation
import PressoirCore

/// What the panel shows right now: the search text and the highlighted row.
@MainActor
@Observable
final class PanelState {
    var query = ""
    var cursor = SelectionCursor(count: 0)
    /// Bumped on every opening so the search field takes focus again.
    private(set) var openings = 0

    func reset() {
        query = ""
        cursor = SelectionCursor(count: 0)
        openings += 1
    }
}
