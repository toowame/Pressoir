/// Names for keys that print nothing readable, by layout-independent key code.
/// Every other key is labelled with the character it types.
public enum KeyName {
    static let escape: UInt32 = 53

    private static let names: [UInt32: String] = [
        49: "Space", 36: "↩", 76: "⌤", 48: "⇥", 51: "⌫", 117: "⌦", escape: "⎋", 114: "Help",
        123: "←", 124: "→", 125: "↓", 126: "↑", 115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
        106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20",
    ]

    public static func special(keyCode: UInt32) -> String? { names[keyCode] }

    /// Escape without modifiers cancels recording instead of becoming the shortcut.
    public static func isCancel(keyCode: UInt32) -> Bool { keyCode == escape }
}
