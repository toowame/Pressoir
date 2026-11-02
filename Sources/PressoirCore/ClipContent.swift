import Foundation

/// Points to an image stored apart from the history (one encrypted file per
/// image, so the history file stays small). The file is named after `blobId`,
/// a random id, so its name reveals nothing about the picture; `digest` (SHA-256
/// of the pixels' PNG) only serves to spot a re-copy, and lives inside the
/// encrypted history.
public struct ImageRef: Equatable, Codable, Sendable {
    public let blobId: UUID
    public let digest: String
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let byteCount: Int

    public init(blobId: UUID, digest: String, pixelWidth: Int, pixelHeight: Int, byteCount: Int) {
        self.blobId = blobId
        self.digest = digest
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.byteCount = byteCount
    }
}

public enum ClipContent: Equatable, Codable, Sendable {
    case text(String)
    case image(ImageRef)

    /// Same text, or same picture even if stored under another file.
    public func isSameCopy(as other: ClipContent) -> Bool {
        switch (self, other) {
        case (.text(let lhs), .text(let rhs)): lhs == rhs
        case (.image(let lhs), .image(let rhs)): lhs.digest == rhs.digest
        default: false
        }
    }

    var isBlank: Bool {
        guard case .text(let text) = self else { return false }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
