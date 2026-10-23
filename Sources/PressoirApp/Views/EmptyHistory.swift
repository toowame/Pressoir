import SwiftUI

struct EmptyHistory: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 8) {
            Icon(.empty).font(.title2).foregroundStyle(.tertiary)
            Text(isSearching ? Labels.noMatch : Labels.emptyTitle).foregroundStyle(.secondary)
            if !isSearching {
                Text(Labels.emptyHint).font(.caption).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct KeyHintFooter: View {
    var body: some View {
        Text(Labels.footer)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }
}
