import Observation
import PressoirCore

/// What the recorder window shows: the shortcut in use and the last problem, if any.
@MainActor
@Observable
final class ShortcutRecorderState {
    var current: Shortcut
    var problem: String?

    init(current: Shortcut) {
        self.current = current
    }
}
