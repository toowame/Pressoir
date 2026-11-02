/// Checked on the raw pasteboard bytes and the declared dimensions, before any
/// decoding: a tiny file declaring 30 000 × 30 000 pixels must never reach the
/// decoder, which would allocate gigabytes.
public enum ImageLimits {
    public static let maxRawBytes = 50 * 1024 * 1024
    public static let maxPixels = 64_000_000

    public static func accepts(rawBytes: Int, pixelWidth: Int, pixelHeight: Int) -> Bool {
        guard rawBytes <= maxRawBytes, pixelWidth > 0, pixelHeight > 0 else { return false }
        let (pixels, overflow) = pixelWidth.multipliedReportingOverflow(by: pixelHeight)
        return !overflow && pixels <= maxPixels
    }
}
