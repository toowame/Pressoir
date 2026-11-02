import Foundation

/// Aggregate root of the clipboard history. Every command returns a new history;
/// the invariants (no blank entry, no duplicate copy, at most `capacity` unpinned
/// entries, pinned entries never evicted) are enforced here and nowhere else.
public struct ClipHistory: Equatable, Codable, Sendable {
    public static let defaultCapacity = 50
    private static let minimumCapacity = 1

    /// Most recent first.
    public let items: [ClipItem]
    public let capacity: Int

    public init(capacity: Int = ClipHistory.defaultCapacity, items: [ClipItem] = []) {
        self.capacity = max(capacity, Self.minimumCapacity)
        self.items = items
    }

    public func recording(_ text: String, at date: Date) -> ClipHistory {
        recording(.text(text), at: date)
    }

    public func recording(_ content: ClipContent, at date: Date) -> ClipHistory {
        guard !content.isBlank else { return self }
        let existing = items.first { $0.content.isSameCopy(as: content) }
        let entry = existing?.copied(at: date) ?? ClipItem(content: content, copiedAt: date)
        let others = items.filter { !$0.content.isSameCopy(as: content) }
        return replacingItems(with: evictingOverflow(from: [entry] + others))
    }

    public func item(matching content: ClipContent) -> ClipItem? {
        items.first { $0.content.isSameCopy(as: content) }
    }

    /// Image files still referenced; any other stored image is an orphan to delete.
    public var imageBlobIds: Set<UUID> {
        Set(
            items.compactMap {
                guard case .image(let ref) = $0.content else { return nil }
                return ref.blobId
            })
    }

    public func togglingPin(_ id: ClipItem.ID) -> ClipHistory {
        replacingItems(with: items.map { $0.id == id ? $0.togglingPin() : $0 })
    }

    public func removing(_ id: ClipItem.ID) -> ClipHistory {
        replacingItems(with: items.filter { $0.id != id })
    }

    public func clearingUnpinned() -> ClipHistory {
        replacingItems(with: items.filter(\.isPinned))
    }

    /// What the panel lists: pinned first, then by recency, narrowed by `query`
    /// (case and diacritic insensitive; a blank query keeps everything, a non-blank
    /// one only matches texts).
    public func ordered(matching query: String) -> [ClipItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching =
            needle.isEmpty
            ? items
            : items.filter { $0.text?.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        return matching.filter(\.isPinned) + matching.filter { !$0.isPinned }
    }

    private func evictingOverflow(from candidates: [ClipItem]) -> [ClipItem] {
        let keptUnpinnedIds = Set(candidates.filter { !$0.isPinned }.prefix(capacity).map(\.id))
        return candidates.filter { $0.isPinned || keptUnpinnedIds.contains($0.id) }
    }

    private func replacingItems(with newItems: [ClipItem]) -> ClipHistory {
        ClipHistory(capacity: capacity, items: newItems)
    }
}
