import PressoirCore
import SwiftUI

/// The panel content: search field, list, keyboard hints.
struct HistoryView: View {
    let model: HistoryModel
    @Bindable var state: PanelState
    let onChoose: (ClipItem) -> Void

    private var items: [ClipItem] { model.history.ordered(matching: state.query) }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(query: $state.query, focusToken: state.openings)
            Divider()
            content
            Divider()
            KeyHintFooter()
        }
        .frame(width: PanelController.panelSize.width, height: PanelController.panelSize.height)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: PanelMetrics.cornerRadius))
        .clipShape(RoundedRectangle(cornerRadius: PanelMetrics.cornerRadius))
        .onChange(of: state.query) { state.cursor = SelectionCursor(count: items.count) }
    }

    @ViewBuilder
    private var content: some View {
        if items.isEmpty {
            EmptyHistory(isSearching: !state.query.trimmingCharacters(in: .whitespaces).isEmpty)
        } else {
            ClipList(
                items: items,
                selectedIndex: state.cursor.resized(to: items.count).index,
                model: model,
                onChoose: onChoose)
        }
    }
}

enum PanelMetrics {
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 10
    static let rowSpacing: CGFloat = 2
    static let previewLength = 90
    static let shortcutCount = 9
}
