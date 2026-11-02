import Foundation
import PressoirCore

/// Every user-facing string, in one place. The texts live in
/// Resources/Localization/<language>.lproj, copied into the app bundle, and macOS
/// picks the language from the system settings (English when it has no match).
enum Labels {
    static let searchPlaceholder = text("search.placeholder")
    static let emptyTitle = text("empty.title")
    static let emptyHint = text("empty.hint")
    static let noMatch = text("search.noMatch")
    static let footer = text("panel.footer")
    static let pin = text("row.pin")
    static let unpin = text("row.unpin")
    static let remove = text("row.remove")

    static let menuOpen = text("menu.open")
    static let menuClear = text("menu.clear")
    static let menuLaunchAtLogin = text("menu.launchAtLogin")
    static let menuQuit = text("menu.quit")

    static func lineCount(_ count: Int) -> String { format("row.lineCount", count) }

    static func imageSize(width: Int, height: Int) -> String { format("row.imageSize", width, height) }

    /// Shown at the top of the menu when the history could not be opened normally.
    static func vaultWarning(_ status: VaultStatus) -> String? {
        switch status {
        case .ready: nil
        case .quarantined(let folder): format("vault.quarantined", folder.lastPathComponent)
        case .locked: text("vault.locked")
        }
    }

    private static func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }

    private static func format(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: text(key), locale: .current, arguments: arguments)
    }
}
