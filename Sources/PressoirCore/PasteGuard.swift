public enum PasteSkipReason: Equatable, Sendable {
    case noTarget, targetChanged, secureField
}

public enum PasteDecision: Equatable, Sendable {
    case paste
    case skip(PasteSkipReason)
}

/// Checked right before the synthetic ⌘V: it only goes to the app that was in
/// front when the panel opened, and never into a password field. When skipped,
/// the entry stays on the pasteboard for a manual ⌘V.
public enum PasteGuard {
    static let secureFieldRole = "AXSecureTextField"

    public static func decide(expectedPid: Int32?, currentPid: Int32?, focusedRole: String?) -> PasteDecision {
        guard let expectedPid, let currentPid else { return .skip(.noTarget) }
        guard expectedPid == currentPid else { return .skip(.targetChanged) }
        guard focusedRole != secureFieldRole else { return .skip(.secureField) }
        return .paste
    }
}
