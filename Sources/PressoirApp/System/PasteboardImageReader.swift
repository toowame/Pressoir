import AppKit
import PressoirCore

/// Reads the pasteboard picture (PNG, or TIFF from screenshots and Preview) and
/// normalises it to PNG, which is lossless and much smaller than raw TIFF.
enum PasteboardImageReader {
    static func read(from pasteboard: NSPasteboard) -> PasteboardImage? {
        guard
            let raw = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
            let bitmap = NSBitmapImageRep(data: raw),
            let png = bitmap.representation(using: .png, properties: [:])
        else {
            Log.write("Image du presse-papier illisible, ignorée")
            return nil
        }
        return PasteboardImage(data: png, pixelWidth: bitmap.pixelsWide, pixelHeight: bitmap.pixelsHigh)
    }
}
