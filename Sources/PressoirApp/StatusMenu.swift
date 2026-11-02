import AppKit
import PressoirCore
import ServiceManagement

/// The menu-bar icon: vault warning if any, open, clear, launch at login, quit.
@MainActor
final class StatusMenu: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let model: HistoryModel
    private let onOpen: () -> Void
    private let launchAtLogin = NSMenuItem(title: Labels.menuLaunchAtLogin, action: nil, keyEquivalent: "")

    init(model: HistoryModel, onOpen: @escaping () -> Void) {
        self.model = model
        self.onOpen = onOpen
        super.init()
        item.button?.image = NSImage(systemSymbolName: AppIcon.clipboard.rawValue, accessibilityDescription: "Pressoir")
        item.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        if let warning = Labels.vaultWarning(model.vaultStatus) {
            let notice = NSMenuItem(title: warning, action: nil, keyEquivalent: "")
            notice.isEnabled = false
            menu.addItem(notice)
            menu.addItem(.separator())
        }
        menu.addItem(entry(Labels.menuOpen + "  " + Shortcut.openHistory.label, #selector(open)))
        menu.addItem(entry(Labels.menuClear, #selector(clear)))
        menu.addItem(.separator())
        launchAtLogin.target = self
        launchAtLogin.action = #selector(toggleLaunchAtLogin)
        launchAtLogin.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLogin)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: Labels.menuQuit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private func entry(_ title: String, _ action: Selector) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = self
        return menuItem
    }

    @objc private func open() { onOpen() }

    @objc private func clear() { model.clearUnpinned() }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            Log.write("Ouverture au démarrage impossible à modifier : \(ErrorSummary.of(error))")
        }
        launchAtLogin.state = service.status == .enabled ? .on : .off
    }
}
