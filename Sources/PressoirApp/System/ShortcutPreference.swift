import Foundation
import PressoirCore

/// The chosen shortcut, kept in the app's user defaults. Not a secret: a key
/// combination, checked again by `Shortcut.restored` when read back.
enum ShortcutPreference {
    private static let key = "openHistoryShortcut"

    static func load() -> Shortcut {
        Shortcut.restored(from: UserDefaults.standard.data(forKey: key))
    }

    static func save(_ shortcut: Shortcut) {
        UserDefaults.standard.set(shortcut.encoded(), forKey: key)
    }
}
