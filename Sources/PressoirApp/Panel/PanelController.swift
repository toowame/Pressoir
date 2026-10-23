import AppKit
import PressoirCore
import SwiftUI

/// Opens the panel under the mouse, routes the keyboard, and pastes the choice.
@MainActor
final class PanelController {
    static let panelSize = CGSize(width: 380, height: 440)

    private let model: HistoryModel
    private let paster: PastePerformer
    private let state = PanelState()
    private var panel: HistoryPanel?
    private var keyMonitor: Any?

    init(model: HistoryModel, paster: PastePerformer) {
        self.model = model
        self.paster = paster
    }

    func toggle() {
        if panel?.isVisible == true { close() } else { open() }
    }

    private func open() {
        state.reset()
        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.setFrameOrigin(originUnderMouse())
        panel.makeKeyAndOrderFront(nil)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // NSEvent isn't Sendable: only the decision crosses into the main-actor closure.
            let command = PanelKeyCommand(event: event)
            let consumed = MainActor.assumeIsolated { self?.handle(command) == true }
            return consumed ? nil : event
        }
    }

    private func close() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        panel?.orderOut(nil)
    }

    private func choose(_ item: ClipItem) {
        close()
        paster.paste(item.text)
    }

    private func visibleItems() -> [ClipItem] {
        model.history.ordered(matching: state.query)
    }

    private func handle(_ command: PanelKeyCommand?) -> Bool {
        let items = visibleItems()
        guard let command else { return false }
        switch command {
        case .close: close()
        case .up: state.cursor = state.cursor.resized(to: items.count).movingUp()
        case .down: state.cursor = state.cursor.resized(to: items.count).movingDown()
        case .choose: selected(in: items).map(choose)
        case .chooseShortcut(let digit):
            state.cursor.resized(to: items.count).selecting(shortcut: digit)
                .flatMap { $0.index }.map { choose(items[$0]) }
        case .togglePin: selected(in: items).map { model.togglePin($0.id) }
        case .remove: selected(in: items).map { model.remove($0.id) }
        }
        return true
    }

    private func selected(in items: [ClipItem]) -> ClipItem? {
        state.cursor.resized(to: items.count).index.map { items[$0] }
    }

    private func makePanel() -> HistoryPanel {
        let panel = HistoryPanel(contentRect: NSRect(origin: .zero, size: Self.panelSize))
        let root = HistoryView(model: model, state: state, onChoose: { [weak self] in self?.choose($0) })
        panel.contentView = NSHostingView(rootView: root)
        panel.onResignKey = { [weak self] in self?.close() }
        return panel
    }

    private func originUnderMouse() -> CGPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? CGRect(origin: .zero, size: Self.panelSize)
        return PanelPlacement.origin(mouse: mouse, panelSize: Self.panelSize, visibleFrame: visibleFrame)
    }
}
