import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// What goes back on the pasteboard when an entry is chosen.
enum PastePayload {
    case text(String)
    case png(Data)
}

/// Puts the chosen entry on the pasteboard and, if allowed, types ⌘V into the
/// frontmost app. Synthesising keystrokes needs the Accessibility permission;
/// without it the entry is still copied, so a manual ⌘V works.
@MainActor
struct PastePerformer {
    /// Lets the panel finish closing so the keystroke lands in the previous app.
    private static let pasteDelay: Duration = .milliseconds(60)

    func paste(_ payload: PastePayload) {
        write(payload, to: .general)

        guard isTrusted(prompting: true) else {
            Log.write("Accessibilité non accordée : élément copié, collage automatique ignoré")
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: Self.pasteDelay)
            Self.postCommandV()
        }
    }

    private func write(_ payload: PastePayload, to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        switch payload {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .png(let data):
            // TIFF too: older apps (and some Office builds) only accept TIFF.
            pasteboard.setData(data, forType: .png)
            if let tiff = NSImage(data: data)?.tiffRepresentation { pasteboard.setData(tiff, forType: .tiff) }
        }
    }

    private func isTrusted(prompting: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompting] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyCode = CGKeyCode(kVK_ANSI_V)
        for isDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
    }
}
