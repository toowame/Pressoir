import Foundation

/// Recognises well-known credential formats anywhere in a copied text, so a
/// pasted `.env` or a token copied from a terminal is never kept. Deliberately
/// limited to unambiguous prefixes: a generic "looks random" rule would also
/// swallow hashes, ids and URLs.
public enum SecretDetector {
    static let patterns: [String] = [
        #"\bgh[pousr]_[A-Za-z0-9]{36,}"#,  // GitHub tokens
        #"\bgithub_pat_[A-Za-z0-9_]{22,}"#,  // GitHub fine-grained tokens
        #"\b(AKIA|ASIA)[0-9A-Z]{16}\b"#,  // AWS access key ids
        #"eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}"#,  // JWT
        #"xox[abprs]-[A-Za-z0-9-]{10,}"#,  // Slack
        #"\bsk-(ant-[A-Za-z0-9_-]{20,}|proj-[A-Za-z0-9_-]{20,}|[A-Za-z0-9]{40,})"#,  // Anthropic, OpenAI
        #"\b[rs]k_live_[A-Za-z0-9]{20,}"#,  // Stripe
        #"\bAIza[0-9A-Za-z_-]{35}"#,  // Google API keys
        #"-----BEGIN [A-Z ]*PRIVATE KEY-----"#,  // PEM / OpenSSH private keys
    ]

    public static func looksLikeSecret(_ text: String) -> Bool {
        patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
}
