import SwiftUI

struct SearchField: View {
    @Binding var query: String
    let focusToken: Int
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Icon(.search).foregroundStyle(.secondary)
            TextField(Labels.searchPlaceholder, text: $query)
                .textFieldStyle(.plain)
                .focused($isFocused)
        }
        .font(.body)
        .padding(PanelMetrics.padding)
        .onAppear { isFocused = true }
        .onChange(of: focusToken) { isFocused = true }
    }
}
