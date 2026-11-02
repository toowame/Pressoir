import AppKit
import PressoirCore
import ServiceManagement

/// The menu-bar icon: vault warning if any, open, clear, shortcut, launch at login, quit.
@MainActor
final class StatusMenu: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let model: HistoryModel
    private let onOpen: () -> Void
    private let onChangeShortcut: () -> Void
    private let launchAtLogin = NSMenuItem(title: Labels.menuLaunchAtLogin, action: nil, keyEquivalent: "")
    private let openItem = NSMenuItem(title: Labels.menuOpen, action: nil, keyEquivalent: "")
    private let shortcutItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    init(model: HistoryModel, shortcut: Shortcut, onOpen: @escaping () -> Void, onChangeShortcut: @escaping () -> Void)
    {
        self.model = model
        self.onOpen = onOpen
        self.onChangeShortcut = onChangeShortcut
        super.init()
        item.button?.image = NSImage(systemSymbolName: AppIcon.clipboard.rawValue, accessibilityDescription: "Pressoir")
        item.menu = buildMenu()
        show(shortcut)
    }

    /// Writes the shortcut in use next to "Open History" and in the shortcut item.
    func show(_ shortcut: Shortcut) {
        openItem.title = Labels.menuOpen + "  " + shortcut.label
        shortcutItem.title = Labels.menuShortcut(shortcut.label)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        if let warning = Labels.vaultWarning(model.vaultStatus) {
            let notice = NSMenuItem(title: warning, action: nil, keyEquivalent: "")
            notice.isEnabled = false
            menu.addItem(notice)
            menu.addItem(.separator())
        }
        menu.addItem(wire(openItem, #selector(open)))
        menu.addItem(entry(Labels.menuClear, #selector(clear)))
        menu.addItem(.separator())
        menu.addItem(wire(shortcutItem, #selector(changeShortcut)))
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
        wire(NSMenuItem(title: title, action: nil, keyEquivalent: ""), action)
    }

    private func wire(_ menuItem: NSMenuItem, _ action: Selector) -> NSMenuItem {
        menuItem.action = action
        menuItem.target = self
        return menuItem
    }

    @objc private func open() { onOpen() }

    @objc private func changeShortcut() { onChangeShortcut() }

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
