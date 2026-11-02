import AppKit
import PressoirCore
import SwiftUI

/// The left part of a row: a one-line text preview, or an image thumbnail.
struct ClipRowContent: View {
    let content: ClipContent
    let thumbnail: NSImage?

    var body: some View {
        switch content {
        case .text(let text): TextPreview(text: text)
        case .image(let ref): ImagePreview(ref: ref, thumbnail: thumbnail)
        }
    }
}

private struct TextPreview: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ClipPreview.line(for: text, maxLength: PanelMetrics.previewLength))
                .lineLimit(2)
                .foregroundStyle(.primary)
            LineCountBadge(text: text)
        }
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

private struct ImagePreview: View {
    let ref: ImageRef
    let thumbnail: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ThumbnailFrame(thumbnail: thumbnail)
            Text(Labels.imageSize(width: ref.pixelWidth, height: ref.pixelHeight))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ThumbnailFrame: View {
    let thumbnail: NSImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(nsImage: thumbnail).resizable().scaledToFit()
            } else {
                Icon(.image).font(.title2).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: PanelMetrics.thumbnailMaxWidth, maxHeight: PanelMetrics.thumbnailHeight, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: PanelMetrics.thumbnailCornerRadius))
    }
}
