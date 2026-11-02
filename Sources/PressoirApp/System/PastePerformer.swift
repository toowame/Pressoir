import AppKit
import ApplicationServices
import Carbon.HIToolbox
import PressoirCore

/// What goes back on the pasteboard when an entry is chosen.
enum PastePayload {
    case text(String)
    case png(Data)
}

/// Puts the chosen entry on the pasteboard and, if `PasteGuard` agrees, types ⌘V
/// into the app that was in front when the panel opened. Synthesising keystrokes
/// needs the Accessibility permission; without it, or when the guard refuses, the
/// entry stays on the pasteboard for a manual ⌘V.
@MainActor
final class PastePerformer {
    /// Lets the panel finish closing so the keystroke lands in the previous app.
    private static let pasteDelay: Duration = .milliseconds(60)
    private static let ownPasteType = NSPasteboard.PasteboardType(PasteboardChangeFilter.ownPasteType)

    private var hasPromptedForAccessibility = false

    func paste(_ payload: PastePayload, into targetPid: pid_t?) {
        write(payload, to: .general)
        guard isTrusted() else {
            Log.write("Accessibilité non accordée : élément copié, collage automatique ignoré")
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: Self.pasteDelay)
            Self.pasteIfStillSafe(into: targetPid)
        }
    }

    private static func pasteIfStillSafe(into targetPid: pid_t?) {
        let decision = PasteGuard.decide(
            expectedPid: targetPid,
            currentPid: NSWorkspace.shared.frontmostApplication?.processIdentifier,
            focusedRole: FocusedElement.role())
        guard decision == .paste else {
            Log.write("Collage automatique annulé (\(decision)) : l'élément reste dans le presse-papier")
            return
        }
        postCommandV()
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
        // Lets the monitor recognise (and skip) Pressoir's own write.
        pasteboard.setData(Data(), forType: Self.ownPasteType)
    }

    /// Prompts for the permission once per launch, not on every paste.
    private func isTrusted() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": !hasPromptedForAccessibility] as CFDictionary
        hasPromptedForAccessibility = true
        return AXIsProcessTrustedWithOptions(options)
    }

    /// A private event source ignores the physical modifiers still held (the ⇧
    /// of ⇧⌘V), so the target receives exactly ⌘V.
    private static func postCommandV() {
        let source = CGEventSource(stateID: .privateState)
        let keyCode = CGKeyCode(kVK_ANSI_V)
        for isDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
    }
}

/// The focused UI element of the frontmost app, as seen through Accessibility.
enum FocusedElement {
    /// An unresponsive app must not freeze Pressoir (the default AX timeout is ~6 s).
    private static let messagingTimeout: Float = 0.2

    /// Subrole first: a password field is `AXTextField` with subrole `AXSecureTextField`.
    static func role() -> String? {
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, messagingTimeout)
        guard let focused = attribute(kAXFocusedUIElementAttribute, of: system),
            CFGetTypeID(focused) == AXUIElementGetTypeID()
        else { return nil }
        let element = unsafeDowncast(focused, to: AXUIElement.self)
        return (attribute(kAXSubroleAttribute, of: element) as? String)
            ?? (attribute(kAXRoleAttribute, of: element) as? String)
    }

    private static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
}
