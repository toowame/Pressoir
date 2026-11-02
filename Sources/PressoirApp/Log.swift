import Foundation

/// Append-only trace in `~/Library/Logs/Pressoir.log`, readable by the user only,
/// rotated past `maxBytes` (one previous file kept). Never logs clipboard
/// contents: only events and short error summaries.
enum Log {
    private static let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/Pressoir.log")
    private static let previousURL = url.appendingPathExtension("1")
    private static let maxBytes: UInt64 = 1024 * 1024
    private static let privatePermissions = 0o600
    private static let queue = DispatchQueue(label: "pressoir.log")

    static func write(_ message: String) {
        let line = "\(Date().ISO8601Format())  \(message)\n"
        queue.async {
            guard let data = line.data(using: .utf8) else { return }
            rotateIfNeeded()
            append(data)
        }
    }

    // Logging must never fail the app, and has nowhere to report its own failure:
    // write errors are deliberately dropped below.
    private static func append(_ data: Data) {
        let manager = FileManager.default
        if !manager.fileExists(atPath: url.path) {
            manager.createFile(
                atPath: url.path, contents: nil, attributes: [.posixPermissions: privatePermissions])
        }
        try? manager.setAttributes([.posixPermissions: privatePermissions], ofItemAtPath: url.path)
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
    }

    private static func rotateIfNeeded() {
        let manager = FileManager.default
        let size = (try? manager.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0
        guard size > maxBytes else { return }
        try? manager.removeItem(at: previousURL)
        try? manager.moveItem(at: url, to: previousURL)
    }
}
