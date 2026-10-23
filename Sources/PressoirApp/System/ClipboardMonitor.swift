import AppKit
import PressoirCore

/// macOS has no "clipboard changed" notification: the pasteboard's changeCount
/// is polled, and the core filter decides what is worth keeping.
@MainActor
final class ClipboardMonitor {
    private static let pollInterval: TimeInterval = 0.5

    private let pasteboard = NSPasteboard.general
    private let onCapture: (String) -> Void
    private var filter: PasteboardChangeFilter
    private var timer: Timer?

    init(onCapture: @escaping (String) -> Void) {
        self.onCapture = onCapture
        self.filter = PasteboardChangeFilter(lastChangeCount: NSPasteboard.general.changeCount)
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
    }

    private func poll() {
        let (next, captured) = filter.evaluate(snapshot())
        filter = next
        if let captured { onCapture(captured) }
    }

    private func snapshot() -> PasteboardSnapshot {
        PasteboardSnapshot(
            changeCount: pasteboard.changeCount,
            text: pasteboard.string(forType: .string),
            types: Set((pasteboard.types ?? []).map(\.rawValue))
        )
    }
}
