import Foundation

/// Append-only trace in `~/Library/Logs/Pressoir.log`. Never logs clipboard
/// contents — only events and errors.
enum Log {
    private static let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/Pressoir.log")
    private static let queue = DispatchQueue(label: "pressoir.log")

    static func write(_ message: String) {
        let line = "\(Date().ISO8601Format())  \(message)\n"
        queue.async {
            guard let data = line.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: url)
            }
        }
    }
}
