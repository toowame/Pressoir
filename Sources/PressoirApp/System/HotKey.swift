import Carbon.HIToolbox
import PressoirCore

/// A system-wide shortcut. Carbon's RegisterEventHotKey is still the only public
/// API that needs no Accessibility permission to listen globally.
@MainActor
final class HotKey {
    private static let signature: OSType = 0x5052_5353  // "PRSS"
    private static var handlers: [UInt32: () -> Void] = [:]
    private static var nextId: UInt32 = 1
    private static var eventHandlerInstalled = false

    private let id: UInt32
    private var reference: EventHotKeyRef?
    private(set) var shortcut: Shortcut

    init(shortcut: Shortcut, action: @escaping () -> Void) {
        Self.installEventHandlerOnce()
        id = Self.nextId
        Self.nextId += 1
        Self.handlers[id] = action
        self.shortcut = shortcut
        if !register(shortcut) {
            Log.write("Raccourci \(shortcut.label) indisponible — déjà pris par une autre app ?")
        }
    }

    /// Swaps the shortcut. When macOS refuses the new one (already taken by
    /// another app), the previous one is registered again and false is returned.
    func replace(with candidate: Shortcut) -> Bool {
        suspend()
        guard register(candidate) else {
            _ = register(shortcut)
            return false
        }
        shortcut = candidate
        return true
    }

    /// Stops listening, so the current shortcut can be pressed while recording a new one.
    func suspend() {
        guard let reference else { return }
        UnregisterEventHotKey(reference)
        self.reference = nil
    }

    func resume() {
        guard reference == nil else { return }
        _ = register(shortcut)
    }

    private func register(_ candidate: Shortcut) -> Bool {
        var newReference: EventHotKeyRef?
        let status = RegisterEventHotKey(
            candidate.keyCode, Self.carbonModifiers(candidate.modifiers),
            EventHotKeyID(signature: Self.signature, id: id), GetApplicationEventTarget(), 0, &newReference)
        guard status == noErr else {
            Log.write("Enregistrement du raccourci refusé (OSStatus \(status))")
            return false
        }
        reference = newReference
        return true
    }

    private static func carbonModifiers(_ modifiers: Set<ShortcutModifier>) -> UInt32 {
        modifiers.reduce(0) { mask, modifier in
            switch modifier {
            case .command: mask | UInt32(cmdKey)
            case .shift: mask | UInt32(shiftKey)
            case .option: mask | UInt32(optionKey)
            case .control: mask | UInt32(controlKey)
            }
        }
    }

    private static func installEventHandlerOnce() {
        guard !eventHandlerInstalled else { return }
        eventHandlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                var hotKeyId = EventHotKeyID()
                let readStatus = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &hotKeyId)
                guard readStatus == noErr else { return readStatus }
                let id = hotKeyId.id
                // Carbon delivers hot-key events on the main thread.
                MainActor.assumeIsolated { HotKey.handlers[id]?() }
                return noErr
            }, 1, &spec, nil, nil)
        if status != noErr {
            Log.write("Écoute des raccourcis impossible (OSStatus \(status)) : le raccourci ne répondra pas")
        }
    }
}
