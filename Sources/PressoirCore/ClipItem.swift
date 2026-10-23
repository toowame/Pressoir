import Foundation

/// One copied text, identified independently of its content so that pinning and
/// selection survive a re-copy of the same text.
public struct ClipItem: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let text: String
    public let copiedAt: Date
    public let isPinned: Bool

    public init(id: UUID = UUID(), text: String, copiedAt: Date, isPinned: Bool = false) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
        self.isPinned = isPinned
    }

    func copied(at date: Date) -> ClipItem {
        ClipItem(id: id, text: text, copiedAt: date, isPinned: isPinned)
    }

    func togglingPin() -> ClipItem {
        ClipItem(id: id, text: text, copiedAt: copiedAt, isPinned: !isPinned)
    }
}
