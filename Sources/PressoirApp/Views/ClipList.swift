import PressoirCore
import SwiftUI

struct ClipList: View {
    let items: [ClipItem]
    let selectedIndex: Int?
    let model: HistoryModel
    let onChoose: (ClipItem) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: PanelMetrics.rowSpacing) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        ClipRow(
                            item: item,
                            shortcut: index < PanelMetrics.shortcutCount ? index + 1 : nil,
                            isSelected: index == selectedIndex,
                            onChoose: { onChoose(item) },
                            onTogglePin: { model.togglePin(item.id) },
                            onRemove: { model.remove(item.id) }
                        )
                        .id(item.id)
                    }
                }
                .padding(PanelMetrics.padding / 2)
            }
            .onChange(of: selectedIndex) {
                guard let selectedIndex, items.indices.contains(selectedIndex) else { return }
                proxy.scrollTo(items[selectedIndex].id)
            }
        }
    }
}
