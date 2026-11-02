import Foundation

/// One copy (text or image), identified independently of its content so that
/// pinning and selection survive a re-copy of the same thing.
public struct ClipItem: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let content: ClipContent
    public let copiedAt: Date
    public let isPinned: Bool

    public init(id: UUID = UUID(), content: ClipContent, copiedAt: Date, isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.copiedAt = copiedAt
        self.isPinned = isPinned
    }

    /// The copied text, or nil for an image.
    public var text: String? {
        guard case .text(let text) = content else { return nil }
        return text
    }

    func copied(at date: Date) -> ClipItem {
        ClipItem(id: id, content: content, copiedAt: date, isPinned: isPinned)
    }

    func togglingPin() -> ClipItem {
        ClipItem(id: id, content: content, copiedAt: copiedAt, isPinned: !isPinned)
    }

    private enum CodingKeys: String, CodingKey {
        case id, content, copiedAt, isPinned
        /// Histories saved before images existed stored a bare `text`.
        case legacyText = "text"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        copiedAt = try container.decode(Date.self, forKey: .copiedAt)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        if let legacy = try container.decodeIfPresent(String.self, forKey: .legacyText) {
            content = .text(legacy)
        } else {
            content = try container.decode(ClipContent.self, forKey: .content)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(copiedAt, forKey: .copiedAt)
        try container.encode(isPinned, forKey: .isPinned)
    }
}
