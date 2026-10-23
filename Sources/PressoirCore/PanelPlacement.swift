import CoreGraphics

/// Where the history panel opens: its top-left corner on the mouse pointer, flipped
/// left or upwards when that would overflow, and always clamped inside the screen.
/// Coordinates are AppKit's (bottom-left origin, y upwards).
public enum PanelPlacement {
    public static func origin(mouse: CGPoint, panelSize: CGSize, visibleFrame: CGRect) -> CGPoint {
        let x = mouse.x + panelSize.width <= visibleFrame.maxX ? mouse.x : mouse.x - panelSize.width
        let y = mouse.y - panelSize.height >= visibleFrame.minY ? mouse.y - panelSize.height : mouse.y
        return CGPoint(
            x: clamp(x, lower: visibleFrame.minX, upper: visibleFrame.maxX - panelSize.width),
            y: clamp(y, lower: visibleFrame.minY, upper: visibleFrame.maxY - panelSize.height)
        )
    }

    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), max(lower, upper))
    }
}
