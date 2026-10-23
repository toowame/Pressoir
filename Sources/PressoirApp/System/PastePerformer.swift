import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Puts a text on the pasteboard and, if allowed, types ⌘V into the frontmost app.
/// Synthesising keystrokes needs the Accessibility permission; without it the text
/// is still copied, so a manual ⌘V works.
@MainActor
struct PastePerformer {
    /// Lets the panel finish closing so the keystroke lands in the previous app.
    private static let pasteDelay: Duration = .milliseconds(60)

    func paste(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard isTrusted(prompting: true) else {
            Log.write("Accessibilité non accordée : texte copié, collage automatique ignoré")
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: Self.pasteDelay)
            Self.postCommandV()
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
