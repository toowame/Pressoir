import AppKit
import Carbon.HIToolbox

/// The keys the panel reacts to; anything else goes to the search field.
enum PanelKeyCommand: Equatable {
    case close, up, down, choose, togglePin, remove
    case chooseShortcut(Int)

    private static let digitKeyCodes: [Int: Int] = [
        kVK_ANSI_1: 1, kVK_ANSI_2: 2, kVK_ANSI_3: 3, kVK_ANSI_4: 4, kVK_ANSI_5: 5,
        kVK_ANSI_6: 6, kVK_ANSI_7: 7, kVK_ANSI_8: 8, kVK_ANSI_9: 9,
    ]

    init?(event: NSEvent) {
        let keyCode = Int(event.keyCode)
        let command = event.modifierFlags.contains(.command)
        switch keyCode {
        case kVK_Escape: self = .close
        case kVK_UpArrow: self = .up
        case kVK_DownArrow: self = .down
        case kVK_Return, kVK_ANSI_KeypadEnter: self = .choose
        case kVK_ANSI_P where command: self = .togglePin
        case kVK_Delete where command: self = .remove
        default:
            guard command, let digit = Self.digitKeyCodes[keyCode] else { return nil }
            self = .chooseShortcut(digit)
        }
    }
}
