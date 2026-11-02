import AppKit
import PressoirCore
import SwiftUI

/// The small window that records a new global shortcut. While it is open the
/// current shortcut is suspended, so pressing it again is recorded, not obeyed.
@MainActor
final class ShortcutRecorder {
    private let hotKey: HotKey
    private let onOpen: () -> Void
    private let onChange: (Shortcut) -> Void
    private var window: NSWindow?
    private var keyMonitor: Any?
    private var closeObserver: NSObjectProtocol?
    private var state: ShortcutRecorderState?

    /// `onOpen` runs before the window shows, to close the history panel whose
    /// keyboard would otherwise compete with the recorder.
    init(hotKey: HotKey, onOpen: @escaping () -> Void, onChange: @escaping (Shortcut) -> Void) {
        self.hotKey = hotKey
        self.onOpen = onOpen
        self.onChange = onChange
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        onOpen()
        let state = ShortcutRecorderState(current: hotKey.shortcut)
        let window = makeWindow(state: state)
        self.state = state
        self.window = window
        hotKey.suspend()
        startListening()
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tearDown() }
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private func makeWindow(state: ShortcutRecorderState) -> NSWindow {
        let view = ShortcutRecorderView(
            state: state, onReset: { [weak self] in self?.apply(.default) },
            onCancel: { [weak self] in self?.window?.close() })
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = Labels.shortcutTitle
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.level = .floating
        return window
    }

    /// Only keys typed in this window are recorded. Tab, Return and Space alone
    /// go through to the buttons, so the window stays usable from the keyboard.
    private func startListening() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let key = RecordedKey(event: event)
            let isOwnWindow = MainActor.assumeIsolated { event.window != nil && event.window === self?.window }
            guard isOwnWindow, !key.isButtonNavigation else { return event }
            MainActor.assumeIsolated { self?.record(key) }
            return nil
        }
    }

    private func record(_ key: RecordedKey) {
        guard !key.isCancel else {
            window?.close()
            return
        }
        do {
            apply(try key.shortcut())
        } catch {
            state?.problem = Labels.shortcutProblem(error, label: key.label)
        }
    }

    /// Either way the hot key is suspended again afterwards: the window is still
    /// open, and closing it (`tearDown`) is what resumes listening.
    private func apply(_ candidate: Shortcut) {
        guard hotKey.replace(with: candidate) else {
            hotKey.suspend()
            state?.problem = Labels.shortcutUnavailable(candidate.label)
            return
        }
        hotKey.suspend()
        ShortcutPreference.save(candidate)
        Log.write("Nouveau raccourci : \(candidate.label)")
        onChange(candidate)
        window?.close()
    }

    private func tearDown() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
        keyMonitor = nil
        closeObserver = nil
        hotKey.resume()
        window = nil
        state = nil
    }
}
