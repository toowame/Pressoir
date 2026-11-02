import Foundation
import PressoirCore

/// The data folders: private to the user, and out of Time Machine (an old backup
/// paired with the key of its time would otherwise bring back deleted entries).
enum DataFolder {
    private static let privateDirectoryPermissions = 0o700

    /// Tightens folders an earlier version created with the default 0755.
    static func makePrivate(_ folders: [URL]) {
        for folder in folders where FileManager.default.fileExists(atPath: folder.path) {
            do {
                try FileManager.default.setAttributes(
                    [.posixPermissions: privateDirectoryPermissions], ofItemAtPath: folder.path)
            } catch {
                Log.write("Droits du dossier \(folder.lastPathComponent) impossibles à resserrer")
            }
        }
    }

    static func excludeFromBackup(_ folder: URL) {
        var url = folder
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try url.setResourceValues(values)
        } catch {
            Log.write("Exclusion Time Machine impossible : \(ErrorSummary.of(error))")
        }
    }
}
