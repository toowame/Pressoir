import PressoirCore

/// Every user-facing string, in one place.
enum Labels {
    static let searchPlaceholder = "Rechercher dans l'historique"
    static let emptyTitle = "Rien de copié pour l'instant"
    static let emptyHint = "Copiez un texte ou une image (⌘C), il apparaîtra ici."
    static let noMatch = "Aucun résultat"
    static let footer = "↩ coller · ⌘1–9 · ⌘P épingler · ⌘⌫ supprimer"
    static let pin = "Épingler"
    static let unpin = "Désépingler"
    static let remove = "Supprimer"

    static let menuOpen = "Ouvrir l'historique"
    static let menuClear = "Effacer l'historique (hors épinglés)"
    static let menuLaunchAtLogin = "Ouvrir au démarrage"
    static let menuQuit = "Quitter Pressoir"

    static func lineCount(_ count: Int) -> String { "\(count) lignes" }

    static func imageSize(width: Int, height: Int) -> String { "Image · \(width) × \(height)" }

    /// Shown at the top of the menu when the history could not be opened normally.
    static func vaultWarning(_ status: VaultStatus) -> String? {
        switch status {
        case .ready: nil
        case .quarantined(let folder): "Ancien historique illisible, mis de côté dans « \(folder.lastPathComponent) »"
        case .locked: "Trousseau inaccessible : historique non enregistré"
        }
    }
}
