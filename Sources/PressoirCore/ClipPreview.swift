import Foundation

/// Turns a copied text into what fits on one row of the panel.
public enum ClipPreview {
    private static let ellipsis = "…"

    public static func line(for text: String, maxLength: Int) -> String {
        let collapsed =
            text
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        guard collapsed.count > maxLength else { return collapsed }
        return String(collapsed.prefix(max(maxLength - ellipsis.count, 0))) + ellipsis
    }

    public static func lineCount(of text: String) -> Int {
        text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count
    }
}
