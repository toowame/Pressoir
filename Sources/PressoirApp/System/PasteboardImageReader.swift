import AppKit
import ImageIO
import PressoirCore

/// Reads the pasteboard picture (PNG, or TIFF from screenshots and Preview) and
/// normalises it to PNG. Size and declared dimensions are checked against
/// `ImageLimits` before anything is decoded; decoding itself runs off the main
/// thread (see `ClipboardMonitor`).
enum PasteboardImageReader {
    /// Raw bytes only: the pasteboard must be read on the main thread.
    @MainActor
    static func rawData(from pasteboard: NSPasteboard) -> Data? {
        pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff)
    }

    static func decode(_ raw: Data) -> PasteboardImage? {
        guard let size = ImageThumbnailer.pixelSize(of: raw) else {
            Log.write("Image du presse-papier illisible, ignorée")
            return nil
        }
        guard ImageLimits.accepts(rawBytes: raw.count, pixelWidth: size.width, pixelHeight: size.height) else {
            Log.write("Image du presse-papier trop grande (\(raw.count) octets, \(size.width)×\(size.height)), ignorée")
            return nil
        }
        guard let png = NSBitmapImageRep(data: raw)?.representation(using: .png, properties: [:]) else {
            Log.write("Image du presse-papier impossible à convertir, ignorée")
            return nil
        }
        return PasteboardImage(data: png, pixelWidth: size.width, pixelHeight: size.height)
    }
}
