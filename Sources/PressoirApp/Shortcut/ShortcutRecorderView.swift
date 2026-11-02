import PressoirCore
import SwiftUI

/// "Press the new shortcut": the current one, the last refusal, reset and cancel.
struct ShortcutRecorderView: View {
    let state: ShortcutRecorderState
    let onReset: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: RecorderMetrics.spacing) {
            Icon(.keyboard).font(.largeTitle).foregroundStyle(.secondary)
            Text(Labels.shortcutPrompt).font(.headline)
            Text(state.current.label)
                .font(.system(.title, design: .rounded).weight(.semibold))
                .padding(.horizontal, RecorderMetrics.keyPadding)
                .padding(.vertical, RecorderMetrics.keyPadding / 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: RecorderMetrics.keyCornerRadius))
            Text(state.problem ?? Labels.shortcutHint)
                .font(.callout)
                .foregroundStyle(state.problem == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(Labels.shortcutReset(Shortcut.default.label), action: onReset)
                    .disabled(state.current == .default)
                Spacer()
                // Escape is handled by the recorder's key monitor, which sees it first.
                Button(Labels.shortcutCancel, action: onCancel)
            }
        }
        .padding(RecorderMetrics.padding)
        .frame(width: RecorderMetrics.width)
    }
}

enum RecorderMetrics {
    static let width: CGFloat = 340
    static let padding: CGFloat = 24
    static let spacing: CGFloat = 14
    static let keyPadding: CGFloat = 18
    static let keyCornerRadius: CGFloat = 10
}
