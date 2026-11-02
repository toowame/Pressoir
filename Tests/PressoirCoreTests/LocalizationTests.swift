import Foundation
import Testing

/// The interface strings live in Resources/Localization/<language>.lproj. A key
/// missing from one language would show its raw identifier in the menu, and a
/// placeholder that differs would crash `String(format:)`.
@Suite("Traductions de l'interface")
struct LocalizationTests {
    private static let languages = ["en", "fr"]

    private static func strings(_ language: String) throws -> [String: String] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/Localization/\(language).lproj/Localizable.strings")
        let data = try Data(contentsOf: url)
        let table = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(table as? [String: String])
    }

    private static func placeholders(_ text: String) -> [String] {
        let pattern = /%(\d+\$)?[@dlu]+/
        return text.matches(of: pattern).map { String($0.output.0) }.sorted()
    }

    @Test("Chaque langue a des textes")
    func everyLanguageHasStrings() throws {
        for language in Self.languages {
            #expect(try !Self.strings(language).isEmpty, "\(language) vide")
        }
    }

    @Test("Toutes les langues ont exactement les mêmes clés")
    func sameKeysEverywhere() throws {
        let reference = try Set(Self.strings("en").keys)
        for language in Self.languages {
            let keys = try Set(Self.strings(language).keys)
            #expect(keys.subtracting(reference).isEmpty, "\(language) : clés en trop")
            #expect(reference.subtracting(keys).isEmpty, "\(language) : clés manquantes")
        }
    }

    @Test("Les marqueurs de format sont identiques d'une langue à l'autre")
    func samePlaceholders() throws {
        let reference = try Self.strings("en")
        for language in Self.languages {
            let table = try Self.strings(language)
            for (key, text) in reference {
                #expect(
                    Self.placeholders(table[key] ?? "") == Self.placeholders(text),
                    "\(language) : marqueurs différents pour \(key)")
            }
        }
    }

    @Test("Aucun texte vide")
    func noEmptyText() throws {
        for language in Self.languages {
            for (key, text) in try Self.strings(language) {
                #expect(!text.trimmingCharacters(in: .whitespaces).isEmpty, "\(language) : \(key) vide")
            }
        }
    }
}
