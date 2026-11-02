import AppKit
import PressoirCore

/// macOS has no "clipboard changed" notification: the pasteboard's changeCount
/// is polled, the core filter decides what to read, and only then is the
/// (possibly heavy) content fetched.
@MainActor
final class ClipboardMonitor {
    private static let pollInterval: TimeInterval = 0.5

    private let pasteboard = NSPasteboard.general
    private let onCapture: (CapturedClip) -> Void
    private var filter: PasteboardChangeFilter
    private var timer: Timer?

    init(onCapture: @escaping (CapturedClip) -> Void) {
        self.onCapture = onCapture
        self.filter = PasteboardChangeFilter(lastChangeCount: NSPasteboard.general.changeCount)
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
    }

    private func poll() {
        let changeCount = pasteboard.changeCount
        guard changeCount != filter.lastChangeCount else { return }
        let types = Set((pasteboard.types ?? []).map(\.rawValue))
        let (next, kind) = filter.evaluate(changeCount: changeCount, types: types)
        filter = next
        if let clip = kind.flatMap(read) { onCapture(clip) }
    }

    private func read(_ kind: CaptureKind) -> CapturedClip? {
        switch kind {
        case .text: pasteboard.string(forType: .string).map(CapturedClip.text)
        case .image: PasteboardImageReader.read(from: pasteboard).map(CapturedClip.image)
        }
    }
}
