import PressoirCore
import SwiftUI

struct ClipRow: View {
    let item: ClipItem
    let shortcut: Int?
    let isSelected: Bool
    let onChoose: () -> Void
    let onTogglePin: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            ShortcutBadge(digit: shortcut)
            VStack(alignment: .leading, spacing: 2) {
                Text(ClipPreview.line(for: item.text, maxLength: PanelMetrics.previewLength))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                LineCountBadge(text: item.text)
            }
            Spacer(minLength: 4)
            RowActions(
                isPinned: item.isPinned, isVisible: isHovered || isSelected || item.isPinned,
                onTogglePin: onTogglePin, onRemove: onRemove)
        }
        .padding(.horizontal, PanelMetrics.padding)
        .padding(.vertical, 7)
        .background(RowBackground(isSelected: isSelected, isHovered: isHovered))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onChoose)
        .help(item.text)
    }
}

private struct ShortcutBadge: View {
    let digit: Int?

    var body: some View {
        Text(digit.map(String.init) ?? " ")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.tertiary)
            .frame(width: 12)
    }
}

/// Only shown for multi-line texts, whose one-line preview hides the line breaks.
private struct LineCountBadge: View {
    let text: String

    var body: some View {
        let lines = ClipPreview.lineCount(of: text)
        if lines > 1 {
            HStack(spacing: 6) {
                Icon(.lines)
                Text(Labels.lineCount(lines))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct RowActions: View {
    let isPinned: Bool
    let isVisible: Bool
    let onTogglePin: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
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
        RoundedRectangle(cornerRadius: 7)
            .fill(isSelected ? Color.accentColor.opacity(0.18) : isHovered ? Color.primary.opacity(0.05) : .clear)
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
