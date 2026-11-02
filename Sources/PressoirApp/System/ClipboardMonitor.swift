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
        let source = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let (next, kind) = filter.evaluate(changeCount: changeCount, types: types, sourceBundleId: source)
        filter = next
        switch kind {
        case .text: pasteboard.string(forType: .string).map { onCapture(.text($0)) }
        case .image: PasteboardImageReader.rawData(from: pasteboard).map(captureImage)
        case nil: break
        }
    }

    /// A large picture takes a noticeable time to decode: never on the main thread.
    private func captureImage(_ raw: Data) {
        Task { [weak self] in
            let image = await Task.detached(priority: .utility) { PasteboardImageReader.decode(raw) }.value
            if let image { self?.onCapture(.image(image)) }
        }
    }
}
