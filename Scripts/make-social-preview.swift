// Draws the GitHub social preview (1280 × 640): icon, name, tagline and the
// default shortcut as key caps.
//
// Usage: swift Scripts/make-social-preview.swift <logo.png> <output.png>
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

let size = CGSize(width: 1280, height: 640)

/// A script has nothing to recover from: a missing Core Graphics object stops it with a message.
func required<T>(_ value: T?, _ what: String) -> T {
    guard let value else { fatalError("\(what) indisponible") }
    return value
}

let sRGB = required(CGColorSpace(name: CGColorSpace.sRGB), "espace sRGB")

struct Palette {
    static let top = CGColor(srgbRed: 0.18, green: 0.06, blue: 0.12, alpha: 1)
    static let bottom = CGColor(srgbRed: 0.09, green: 0.03, blue: 0.06, alpha: 1)
    static let title = CGColor(srgbRed: 1, green: 0.98, blue: 0.97, alpha: 1)
    static let tagline = CGColor(srgbRed: 0.93, green: 0.72, blue: 0.82, alpha: 1)
    static let body = CGColor(srgbRed: 0.80, green: 0.74, blue: 0.77, alpha: 1)
    static let keyFill = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10)
    static let keyStroke = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.28)
}

func drawBackground(_ context: CGContext) {
    let gradient = required(
        CGGradient(colorsSpace: sRGB, colors: [Palette.top, Palette.bottom] as CFArray, locations: [0, 1]), "dégradé")
    context.drawLinearGradient(
        gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: size.width, y: 0), options: [])
}

func drawText(
    _ text: String, _ context: CGContext, at point: CGPoint, size points: CGFloat, weight: NSFont.Weight, color: CGColor
) {
    let font = NSFont.systemFont(ofSize: points, weight: weight)
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(cgColor: color) ?? .white]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    context.textPosition = point
    CTLineDraw(line, context)
}

/// Draws one key cap and returns its right edge.
func drawKey(_ label: String, _ context: CGContext, x: CGFloat, y: CGFloat) -> CGFloat {
    let cap = CGRect(x: x, y: y, width: 92, height: 84)
    let path = CGPath(roundedRect: cap, cornerWidth: 18, cornerHeight: 18, transform: nil)
    context.addPath(path)
    context.setFillColor(Palette.keyFill)
    context.fillPath()
    context.addPath(path)
    context.setStrokeColor(Palette.keyStroke)
    context.setLineWidth(2)
    context.strokePath()
    let font = NSFont.systemFont(ofSize: 40, weight: .semibold)
    let width = (label as NSString).size(withAttributes: [.font: font]).width
    drawText(
        label, context, at: CGPoint(x: cap.midX - width / 2, y: y + 28), size: 40, weight: .semibold,
        color: Palette.title)
    return cap.maxX
}

func render(logo: CGImage) -> CGImage {
    let context = required(
        CGContext(
            data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
            space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
        "contexte")
    drawBackground(context)
    context.draw(logo, in: CGRect(x: 70, y: 150, width: 340, height: 340))
    let left: CGFloat = 450
    drawText("Pressoir", context, at: CGPoint(x: left, y: 400), size: 104, weight: .bold, color: Palette.title)
    drawText(
        "Win + V for your Mac", context, at: CGPoint(x: left, y: 330), size: 46, weight: .semibold,
        color: Palette.tagline)
    drawText(
        "Clipboard history under your mouse · encrypted · native Swift", context,
        at: CGPoint(x: left, y: 276), size: 27, weight: .regular, color: Palette.body)
    var x = left
    for key in ["⇧", "⌘", "V"] { x = drawKey(key, context, x: x, y: 150) + 16 }
    return required(context.makeImage(), "image")
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else { fatalError("usage: make-social-preview.swift <logo.png> <output.png>") }
let source = required(CGImageSourceCreateWithURL(URL(fileURLWithPath: arguments[1]) as CFURL, nil), "logo")
let logo = required(CGImageSourceCreateImageAtIndex(source, 0, nil), "logo")
let destination = required(
    CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: arguments[2]) as CFURL, UTType.png.identifier as CFString, 1, nil),
    "fichier de sortie")
CGImageDestinationAddImage(destination, render(logo: logo), nil)
guard CGImageDestinationFinalize(destination) else { fatalError("écriture impossible : \(arguments[2])") }
