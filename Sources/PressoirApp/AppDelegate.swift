import AppKit
import PressoirCore

/// Composition root: builds every adapter once and wires them together.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: HistoryModel?
    private var monitor: ClipboardMonitor?
    private var panel: PanelController?
    private var hotKey: HotKey?
    private var statusMenu: StatusMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let keys = KeychainKeyProvider()
        let store = EncryptedHistoryStore(fileURL: EncryptedHistoryStore.defaultLocation(), keyProvider: keys)
        let imageStore = EncryptedImageStore(directory: EncryptedImageStore.defaultDirectory(), keyProvider: keys)
        Self.migratePlaintextHistory(into: store)
        let model = HistoryModel(store: store, imageStore: imageStore)
        let panel = PanelController(model: model, paster: PastePerformer())
        let monitor = ClipboardMonitor { model.record($0) }

        monitor.start()
        hotKey = HotKey(shortcut: .openHistory) { panel.toggle() }
        statusMenu = StatusMenu(model: model, onOpen: { panel.toggle() })

        self.model = model
        self.panel = panel
        self.monitor = monitor
        Log.write("Pressoir démarré — \(model.history.items.count) éléments chargés")
    }

    private static func migratePlaintextHistory(into store: any HistoryStore) {
        do {
            try PlaintextHistoryMigration(legacyURL: PlaintextHistoryMigration.defaultLegacyLocation()).run(into: store)
        } catch {
            Log.write("Reprise de l'ancien historique en clair impossible : \(error)")
        }
    }
}
