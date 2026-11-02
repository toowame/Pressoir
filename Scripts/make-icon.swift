// Draws the Pressoir app icon with Core Graphics and writes every size macOS
// needs into an .iconset folder, plus a README logo.
//
// Usage: swift Scripts/make-icon.swift <iconset-dir> <logo.png>
// (Scripts/make-icon.sh wraps it and builds Resources/AppIcon.icns.)
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let canvas: CGFloat = 1024

struct Palette {
    static let wineTop = CGColor(srgbRed: 0.56, green: 0.23, blue: 0.37, alpha: 1)
    static let wineBottom = CGColor(srgbRed: 0.29, green: 0.09, blue: 0.20, alpha: 1)
    static let clip = CGColor(srgbRed: 0.24, green: 0.07, blue: 0.16, alpha: 1)
    static let board = CGColor(srgbRed: 1, green: 0.98, blue: 0.97, alpha: 1)
    static let line = CGColor(srgbRed: 0.88, green: 0.82, blue: 0.85, alpha: 1)
    static let selected = CGColor(srgbRed: 0.56, green: 0.23, blue: 0.37, alpha: 1)
    static let shadow = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.35)
}

/// A script has nothing to recover from: a missing Core Graphics object stops it with a message.
func required<T>(_ value: T?, _ what: String) -> T {
    guard let value else { fatalError("\(what) indisponible") }
    return value
}

let sRGB = required(CGColorSpace(name: CGColorSpace.sRGB), "espace sRGB")

func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

/// Apple's icon grid: an 824 pt rounded square centred on the 1024 pt canvas.
func drawBackground(in context: CGContext) {
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: Palette.shadow)
    context.addPath(roundedRect(tile, radius: 185))
    context.setFillColor(Palette.wineBottom)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(roundedRect(tile, radius: 185))
    context.clip()
    let gradient = required(
        CGGradient(colorsSpace: sRGB, colors: [Palette.wineTop, Palette.wineBottom] as CFArray, locations: [0, 1]),
        "dégradé")
    context.drawLinearGradient(
        gradient, start: CGPoint(x: 512, y: tile.maxY), end: CGPoint(x: 512, y: tile.minY), options: [])
    context.restoreGState()
}

func drawClipboard(in context: CGContext) {
    let board = CGRect(x: 302, y: 214, width: 420, height: 540)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: Palette.shadow)
    context.addPath(roundedRect(board, radius: 52))
    context.setFillColor(Palette.board)
    context.fillPath()
    context.restoreGState()

    // The clip, with its hole.
    let clip = CGRect(x: 417, y: 708, width: 190, height: 92)
    context.addPath(roundedRect(clip, radius: 32))
    context.setFillColor(Palette.clip)
    context.fillPath()
    context.addEllipse(in: CGRect(x: 494, y: 758, width: 36, height: 28))
    context.setFillColor(Palette.wineTop)
    context.fillPath()

    // Three history rows; the first one is the selected entry.
    let rows: [(y: CGFloat, width: CGFloat, color: CGColor)] = [
        (560, 300, Palette.selected), (464, 300, Palette.line), (368, 210, Palette.line),
    ]
    for row in rows {
        context.addPath(roundedRect(CGRect(x: 362, y: row.y, width: row.width, height: 52), radius: 26))
        context.setFillColor(row.color)
        context.fillPath()
    }
}

func squareContext(_ size: Int) -> CGContext {
    required(
        CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
        "contexte \(size) px")
}

func renderMaster() -> CGImage {
    let context = squareContext(Int(canvas))
    drawBackground(in: context)
    drawClipboard(in: context)
    return required(context.makeImage(), "image maîtresse")
}

func resized(_ image: CGImage, to size: Int) -> CGImage {
    let context = squareContext(size)
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    return required(context.makeImage(), "image \(size) px")
}

func writePNG(_ image: CGImage, to url: URL) {
    let destination = required(
        CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil), "fichier \(url.path)")
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("écriture impossible : \(url.path)") }
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else { fatalError("usage: make-icon.swift <iconset-dir> <logo.png>") }
let iconset = URL(fileURLWithPath: arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let master = renderMaster()
for points in [16, 32, 128, 256, 512] {
    writePNG(resized(master, to: points), to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    writePNG(resized(master, to: points * 2), to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
writePNG(resized(master, to: 512), to: URL(fileURLWithPath: arguments[2]))
