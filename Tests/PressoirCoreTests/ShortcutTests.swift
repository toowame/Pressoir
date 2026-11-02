import Foundation
import Testing

@testable import PressoirCore

@Suite("Raccourci configurable")
struct ShortcutTests {
    private static let keyV: UInt32 = 9
    private static let keyC: UInt32 = 8
    private static let keyK: UInt32 = 40
    private static let keySpace: UInt32 = 49

    @Test("Par défaut : ⇧⌘V")
    func defaultIsShiftCommandV() {
        #expect(Shortcut.default.keyCode == Self.keyV)
        #expect(Shortcut.default.modifiers == [.shift, .command])
        #expect(Shortcut.default.label == "⇧⌘V")
    }

    @Test("Libellé dans l'ordre de macOS : ⌃⌥⇧⌘ puis la touche")
    func labelFollowsMacOrder() throws {
        let shortcut = try Shortcut.validated(
            keyCode: Self.keyK, modifiers: [.command, .shift, .option, .control], keyLabel: "k")
        #expect(shortcut.label == "⌃⌥⇧⌘K")
    }

    @Test("Sans ⌘, ⌃ ni ⌥ : refusé (une lettre seule ou avec ⇧ se tape dans un texte)")
    func needsACommandLikeModifier() {
        #expect(throws: ShortcutError.needsModifier) {
            try Shortcut.validated(keyCode: Self.keyK, modifiers: [], keyLabel: "K")
        }
        #expect(throws: ShortcutError.needsModifier) {
            try Shortcut.validated(keyCode: Self.keyK, modifiers: [.shift], keyLabel: "K")
        }
    }

    @Test("Les raccourcis d'édition et de système avec ⌘ seul sont réservés")
    func reservesSystemShortcuts() {
        #expect(throws: ShortcutError.reserved) {
            try Shortcut.validated(keyCode: Self.keyC, modifiers: [.command], keyLabel: "C")
        }
        #expect(throws: ShortcutError.reserved) {
            try Shortcut.validated(keyCode: Self.keyV, modifiers: [.command], keyLabel: "V")
        }
        #expect(throws: ShortcutError.reserved) {
            try Shortcut.validated(keyCode: Self.keySpace, modifiers: [.command], keyLabel: "Space")
        }
    }

    /// (key code, modifiers): screenshots ⇧⌘3/4/5/6, log out ⇧⌘Q, input source ⌃Space and ⌃⌥Space.
    static let systemWide: [(UInt32, Set<ShortcutModifier>)] = [
        (20, [.shift, .command]), (21, [.shift, .command]), (23, [.shift, .command]),
        (22, [.shift, .command]), (12, [.shift, .command]), (49, [.control]), (49, [.control, .option]),
    ]

    @Test("Les raccourcis interceptés par macOS sont réservés", arguments: systemWide)
    func reservesSystemWideCombinations(keyCode: UInt32, modifiers: Set<ShortcutModifier>) {
        #expect(throws: ShortcutError.reserved) {
            try Shortcut.validated(keyCode: keyCode, modifiers: modifiers, keyLabel: "x")
        }
    }

    @Test("Touche qui n'imprime qu'un caractère privé (F13 sans nom) : refusée")
    func rejectsPrivateUseLabels() {
        #expect(throws: ShortcutError.unnamedKey) {
            try Shortcut.validated(keyCode: 105, modifiers: [.command], keyLabel: "\u{F710}")
        }
    }

    @Test("Une touche réservée reste possible avec un autre modificateur")
    func reservedKeyWithExtraModifierIsAllowed() throws {
        let shortcut = try Shortcut.validated(keyCode: Self.keyC, modifiers: [.command, .option], keyLabel: "c")
        #expect(shortcut.label == "⌥⌘C")
    }

    @Test("Une touche nommée garde son nom : ⌥Space")
    func namedKeyKeepsItsName() throws {
        let shortcut = try Shortcut.validated(keyCode: Self.keySpace, modifiers: [.option], keyLabel: "Space")
        #expect(shortcut.label == "⌥Space")
    }

    @Test("Une combinaison refusée se nomme aussi : ⌘C")
    func refusedCombinationHasALabel() {
        #expect(Shortcut.label(modifiers: [.command], keyLabel: "c") == "⌘C")
    }

    @Test("Touche sans nom : refusée")
    func needsAKeyLabel() {
        #expect(throws: ShortcutError.unnamedKey) {
            try Shortcut.validated(keyCode: Self.keyK, modifiers: [.command], keyLabel: "  ")
        }
    }

    @Test("Aller-retour par la préférence enregistrée")
    func roundTripsThroughStoredPreference() throws {
        let shortcut = try Shortcut.validated(keyCode: Self.keyK, modifiers: [.control, .option], keyLabel: "K")
        #expect(Shortcut.restored(from: shortcut.encoded()) == shortcut)
    }

    @Test("Préférence absente, illisible ou devenue invalide : retour à ⇧⌘V")
    func fallsBackToDefault() throws {
        #expect(Shortcut.restored(from: nil) == .default)
        #expect(Shortcut.restored(from: Data("pas du json".utf8)) == .default)
        let tampered = Data(#"{"keyCode":8,"modifiers":["command"],"keyLabel":"C"}"#.utf8)
        #expect(Shortcut.restored(from: tampered) == .default)
    }
}

@Suite("Nom des touches spéciales")
struct KeyNameTests {
    @Test(
        "Touches sans caractère imprimable",
        arguments: [
            (UInt32(49), "Space"), (36, "↩"), (48, "⇥"), (51, "⌫"), (123, "←"), (126, "↑"), (122, "F1"), (111, "F12"),
            (105, "F13"), (90, "F20"),
        ]
    )
    func namesSpecialKeys(keyCode: UInt32, name: String) {
        #expect(KeyName.special(keyCode: keyCode) == name)
    }

    @Test("Une lettre n'a pas de nom spécial : on garde ce qu'elle imprime")
    func lettersHaveNoSpecialName() {
        #expect(KeyName.special(keyCode: 9) == nil)
    }

    @Test("Échap annule l'enregistrement")
    func escapeCancels() {
        #expect(KeyName.isCancel(keyCode: 53))
        #expect(!KeyName.isCancel(keyCode: 9))
    }
}
