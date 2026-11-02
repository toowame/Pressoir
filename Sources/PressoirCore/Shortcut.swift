import Foundation

public enum ShortcutModifier: String, Codable, CaseIterable, Sendable {
    // Declared in the order macOS displays them.
    case control, option, shift, command

    var symbol: String {
        switch self {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        }
    }
}

public enum ShortcutError: Error, Equatable, Sendable {
    /// A letter alone, or with ⇧, would fire while typing.
    case needsModifier
    /// ⌘ plus an editing or system key (⌘C, ⌘V, ⌘Q…) would break every app.
    case reserved
    case unnamedKey
}

/// The global shortcut that opens the history. `keyCode` is the layout-independent
/// virtual key; `keyLabel` is what that key printed when it was recorded, since
/// the same key code shows a different letter on AZERTY and QWERTY keyboards.
public struct Shortcut: Codable, Equatable, Sendable {
    public let keyCode: UInt32
    public let modifiers: Set<ShortcutModifier>
    public let keyLabel: String

    private enum Key {
        static let a: UInt32 = 0
        static let h: UInt32 = 4
        static let z: UInt32 = 6
        static let x: UInt32 = 7
        static let c: UInt32 = 8
        static let v: UInt32 = 9
        static let q: UInt32 = 12
        static let w: UInt32 = 13
        static let three: UInt32 = 20
        static let four: UInt32 = 21
        static let six: UInt32 = 22
        static let five: UInt32 = 23
        static let m: UInt32 = 46
        static let tab: UInt32 = 48
        static let space: UInt32 = 49
    }

    private struct Combination: Hashable {
        let keyCode: UInt32
        let modifiers: Set<ShortcutModifier>
    }

    /// Left to macOS and the front app: editing and window keys with ⌘ alone,
    /// screenshots, log out and input source switching. macOS may accept the
    /// registration of these and still never deliver them.
    private static let reserved: Set<Combination> = {
        let commandAlone = [Key.a, Key.c, Key.v, Key.x, Key.z, Key.q, Key.w, Key.h, Key.m, Key.tab, Key.space]
            .map { Combination(keyCode: $0, modifiers: [.command]) }
        let shiftCommand = [Key.three, Key.four, Key.five, Key.six, Key.q]
            .map { Combination(keyCode: $0, modifiers: [.shift, .command]) }
        let inputSource = [
            Combination(keyCode: Key.space, modifiers: [.control]),
            Combination(keyCode: Key.space, modifiers: [.control, .option]),
        ]
        return Set(commandAlone + shiftCommand + inputSource)
    }()

    /// Keys macOS reports with a private-use character (F13 and beyond without a
    /// name, media keys) would show an unreadable glyph.
    private static let privateUse: ClosedRange<UInt32> = 0xF700...0xF8FF

    /// Labelled "V" as on QWERTY and AZERTY; on a layout where that key prints
    /// something else the label is off until the user records their own shortcut.
    public static let `default` = Shortcut(keyCode: Key.v, modifiers: [.shift, .command], keyLabel: "V")

    public var label: String { Self.label(modifiers: modifiers, keyLabel: keyLabel) }

    /// How macOS writes a combination: ⌃⌥⇧⌘ in that order, then the key. Also used
    /// to name a combination that was refused.
    public static func label(modifiers: Set<ShortcutModifier>, keyLabel: String) -> String {
        ShortcutModifier.allCases.filter(modifiers.contains).map(\.symbol).joined() + displayName(keyLabel)
    }

    /// Letters are shown in capitals, as in macOS menus; named keys keep their name.
    private static func displayName(_ keyLabel: String) -> String {
        let trimmed = keyLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 1 ? trimmed.uppercased() : trimmed
    }

    private init(keyCode: UInt32, modifiers: Set<ShortcutModifier>, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyLabel = keyLabel
    }

    public static func validated(
        keyCode: UInt32, modifiers: Set<ShortcutModifier>, keyLabel: String
    ) throws(ShortcutError) -> Shortcut {
        let name = displayName(keyLabel)
        guard !name.isEmpty, !name.unicodeScalars.allSatisfy({ privateUse.contains($0.value) }) else {
            throw .unnamedKey
        }
        guard !modifiers.isDisjoint(with: [.command, .control, .option]) else { throw .needsModifier }
        guard !reserved.contains(Combination(keyCode: keyCode, modifiers: modifiers)) else { throw .reserved }
        return Shortcut(keyCode: keyCode, modifiers: modifiers, keyLabel: name)
    }

    public func encoded() -> Data {
        // Encoding a struct of plain values cannot fail.
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    /// The stored preference, checked again: a damaged or hand-edited value falls
    /// back to ⇧⌘V instead of registering something unusable.
    public static func restored(from data: Data?) -> Shortcut {
        guard let data, let stored = try? JSONDecoder().decode(Shortcut.self, from: data) else { return .default }
        return (try? validated(keyCode: stored.keyCode, modifiers: stored.modifiers, keyLabel: stored.keyLabel))
            ?? .default
    }
}
