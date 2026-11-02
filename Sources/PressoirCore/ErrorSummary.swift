import Foundation

/// A loggable one-liner for any error: domain and code only. Foundation's
/// descriptions can quote the offending value (a decoding error may echo part of
/// a copied text), so they never reach the log.
public enum ErrorSummary {
    public static func of(_ error: any Error) -> String {
        if let storeError = error as? HistoryStoreError { return "\(storeError)" }
        let nsError = error as NSError
        return "\(nsError.domain)#\(nsError.code)"
    }
}
