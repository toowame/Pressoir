import AppKit
import Carbon.HIToolbox
import PressoirCore

/// Turns a key press into a shortcut candidate. NSEvent isn't Sendable, so the
/// values are read here, on the main thread, before anything else sees them.
struct RecordedKey {
    let keyCode: UInt32
    let modifiers: Set<ShortcutModifier>
    let keyLabel: String

    init(event: NSEvent) {
        keyCode = UInt32(event.keyCode)
        modifiers = Self.modifiers(of: event.modifierFlags)
        keyLabel = KeyName.special(keyCode: keyCode) ?? event.characters(byApplyingModifiers: []) ?? ""
    }

    var label: String { Shortcut.label(modifiers: modifiers, keyLabel: keyLabel) }

    var isCancel: Bool { modifiers.isEmpty && KeyName.isCancel(keyCode: keyCode) }

    /// Tab, Return or Space without modifiers: moving between and pressing buttons.
    var isButtonNavigation: Bool { modifiers.isEmpty && Self.navigationKeys.contains(keyCode) }

    private static let navigationKeys: Set<UInt32> = [
        UInt32(kVK_Tab), UInt32(kVK_Return), UInt32(kVK_Space),
    ]

    func shortcut() throws(ShortcutError) -> Shortcut {
        try Shortcut.validated(keyCode: keyCode, modifiers: modifiers, keyLabel: keyLabel)
    }

    private static func modifiers(of flags: NSEvent.ModifierFlags) -> Set<ShortcutModifier> {
        let pairs: [(NSEvent.ModifierFlags, ShortcutModifier)] = [
            (.control, .control), (.option, .option), (.shift, .shift), (.command, .command),
        ]
        return Set(pairs.filter { flags.contains($0.0) }.map(\.1))
    }
}
