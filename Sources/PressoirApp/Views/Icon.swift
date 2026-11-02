import SwiftUI

/// The only way the UI shows a symbol: one named catalogue, no ad-hoc strings.
enum AppIcon: String {
    case clipboard = "doc.on.clipboard"
    case search = "magnifyingglass"
    case pin = "pin.fill"
    case pinOutline = "pin"
    case remove = "xmark"
    case lines = "text.alignleft"
    case empty = "tray"
    case image = "photo"
}

struct Icon: View {
    let symbol: AppIcon

    init(_ symbol: AppIcon) {
        self.symbol = symbol
    }

    var body: some View {
        Image(systemName: symbol.rawValue)
    }
}
