import AppKit
import PressoirCore
import SwiftUI

struct ClipRow: View {
    let item: ClipItem
    /// Only for an image entry; nil while unavailable or for a text.
    let thumbnail: NSImage?
    let shortcut: Int?
    let isSelected: Bool
    let onChoose: () -> Void
    let onTogglePin: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: PanelMetrics.itemSpacing) {
            ShortcutBadge(digit: shortcut)
            ClipRowContent(content: item.content, thumbnail: thumbnail)
            Spacer(minLength: PanelMetrics.captionSpacing)
            RowActions(
                isPinned: item.isPinned, isVisible: isHovered || isSelected || item.isPinned,
                onTogglePin: onTogglePin, onRemove: onRemove)
        }
        .padding(.horizontal, PanelMetrics.padding)
        .padding(.vertical, PanelMetrics.rowVerticalPadding)
        .background(RowBackground(isSelected: isSelected, isHovered: isHovered))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onChoose)
        .help(item.text ?? "")
    }
}

private struct ShortcutBadge: View {
    let digit: Int?

    var body: some View {
        Text(digit.map(String.init) ?? " ")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.tertiary)
            .frame(width: PanelMetrics.shortcutBadgeWidth)
    }
}

private struct RowActions: View {
    let isPinned: Bool
    let isVisible: Bool
    let onTogglePin: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: PanelMetrics.compactSpacing) {
            IconButton(
                symbol: isPinned ? .pin : .pinOutline, help: isPinned ? Labels.unpin : Labels.pin,
                action: onTogglePin
            )
            .foregroundStyle(isPinned ? Color.accentColor : Color.secondary)
            IconButton(symbol: .remove, help: Labels.remove, action: onRemove)
                .foregroundStyle(.secondary)
        }
        .opacity(isVisible ? 1 : 0)
    }
}

private struct RowBackground: View {
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: PanelMetrics.rowCornerRadius)
            .fill(
                isSelected
                    ? Color.accentColor.opacity(PanelMetrics.selectedRowOpacity)
                    : isHovered ? Color.primary.opacity(PanelMetrics.hoveredRowOpacity) : .clear)
    }
}

struct IconButton: View {
    let symbol: AppIcon
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { Icon(symbol) }
            .buttonStyle(.plain)
            .help(help)
    }
}
