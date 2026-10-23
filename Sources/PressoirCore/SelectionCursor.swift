/// Keyboard selection in the panel list: arrows wrap around, digits 1–9 jump.
public struct SelectionCursor: Equatable, Sendable {
    public let count: Int
    public let index: Int?

    public init(count: Int, index: Int? = 0) {
        let bounded = max(count, 0)
        self.count = bounded
        self.index = bounded == 0 ? nil : index.map { min(max($0, 0), bounded - 1) }
    }

    public func movingDown() -> SelectionCursor { moved(by: 1) }

    public func movingUp() -> SelectionCursor { moved(by: -1) }

    public func resized(to newCount: Int) -> SelectionCursor {
        SelectionCursor(count: newCount, index: index ?? 0)
    }

    /// `shortcut` is the digit typed (1 selects the first row).
    public func selecting(shortcut: Int) -> SelectionCursor? {
        let target = shortcut - 1
        guard (0..<count).contains(target) else { return nil }
        return SelectionCursor(count: count, index: target)
    }

    private func moved(by step: Int) -> SelectionCursor {
        guard let index else { return self }
        return SelectionCursor(count: count, index: (index + step + count) % count)
    }
}
