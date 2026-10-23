import CoreGraphics
import Testing

@testable import PressoirCore

/// Coordinates follow AppKit: origin at the bottom-left of the screen, y grows upwards.
@Suite("Placement du panneau sous la souris")
struct PanelPlacementTests {
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let size = CGSize(width: 300, height: 400)

    @Test("Le coin haut-gauche du panneau se pose sur la souris")
    func anchorsTopLeftAtMouse() {
        let origin = PanelPlacement.origin(mouse: CGPoint(x: 100, y: 700), panelSize: size, visibleFrame: screen)

        #expect(origin == CGPoint(x: 100, y: 300))
    }

    @Test("Près du bord droit, le panneau bascule à gauche de la souris")
    func flipsLeftNearRightEdge() {
        let origin = PanelPlacement.origin(mouse: CGPoint(x: 900, y: 700), panelSize: size, visibleFrame: screen)

        #expect(origin.x == 600)
    }

    @Test("Près du bas, le panneau s'ouvre au-dessus de la souris")
    func flipsUpNearBottom() {
        let origin = PanelPlacement.origin(mouse: CGPoint(x: 100, y: 100), panelSize: size, visibleFrame: screen)

        #expect(origin.y == 100)
    }

    @Test(
        "Le panneau reste toujours dans l'écran",
        arguments: [
            CGPoint(x: -50, y: -50), CGPoint(x: 2000, y: 2000), CGPoint(x: 500, y: 400),
        ])
    func staysInsideScreen(mouse: CGPoint) {
        let origin = PanelPlacement.origin(mouse: mouse, panelSize: size, visibleFrame: screen)
        let frame = CGRect(origin: origin, size: size)

        #expect(screen.contains(frame))
    }

    @Test("Écran décalé (second moniteur) : le placement reste relatif à cet écran")
    func handlesOffsetScreen() {
        let second = CGRect(x: 1000, y: 0, width: 800, height: 600)
        let origin = PanelPlacement.origin(mouse: CGPoint(x: 1100, y: 500), panelSize: size, visibleFrame: second)

        #expect(origin == CGPoint(x: 1100, y: 100))
    }
}
