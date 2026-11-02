import AppKit
import PressoirCore

/// Composition root: opens the vault once, builds every adapter and wires them.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Files and folders created by Pressoir are readable by the user only.
    private static let privateUmask: mode_t = 0o077

    private var model: HistoryModel?
    private var monitor: ClipboardMonitor?
    private var panel: PanelController?
    private var hotKey: HotKey?
    private var statusMenu: StatusMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        umask(Self.privateUmask)
        let model = Self.openHistory()
        let panel = PanelController(model: model, paster: PastePerformer())
        let monitor = ClipboardMonitor { model.record($0) }

        monitor.start()
        hotKey = HotKey(shortcut: .openHistory) { panel.toggle() }
        statusMenu = StatusMenu(model: model, onOpen: { panel.toggle() })

        self.model = model
        self.panel = panel
        self.monitor = monitor
        Log.write("Pressoir démarré — \(model.history.items.count) éléments chargés, coffre : \(model.vaultStatus)")
    }

    private static func openHistory() -> HistoryModel {
        let historyURL = EncryptedHistoryStore.defaultLocation()
        let imagesURL = EncryptedImageStore.defaultDirectory()
        DataFolder.excludeFromBackup(historyURL.deletingLastPathComponent())
        DataFolder.makePrivate([historyURL.deletingLastPathComponent(), imagesURL])
        let vault = VaultOpener(historyURL: historyURL, imagesDirectory: imagesURL, keyStore: KeychainKeyStore())
            .open(at: Date())
        guard let key = vault.keyProvider else {
            return HistoryModel(
                history: vault.history, vaultStatus: vault.status, images: MemoryImageStore(), persistence: nil)
        }
        let store = EncryptedHistoryStore(fileURL: historyURL, keyProvider: key)
        let images = EncryptedImageStore(directory: imagesURL, keyProvider: key)
        return HistoryModel(
            history: vault.history, vaultStatus: vault.status, images: images,
            persistence: HistoryPersistence(history: store, images: images))
    }
}
