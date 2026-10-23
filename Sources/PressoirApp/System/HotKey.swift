import Carbon.HIToolbox

/// A system-wide shortcut. Carbon's RegisterEventHotKey is still the only public
/// API that needs no Accessibility permission to listen globally.
struct Shortcut {
    let keyCode: UInt32
    let modifiers: UInt32
    let label: String

    static let openHistory = Shortcut(
        keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | shiftKey), label: "⇧⌘V")
}

@MainActor
final class HotKey {
    private static let signature: OSType = 0x5052_5353  // "PRSS"
    private static var handlers: [UInt32: () -> Void] = [:]
    private static var nextId: UInt32 = 1
    private static var eventHandlerInstalled = false

    private var reference: EventHotKeyRef?

    init(shortcut: Shortcut, action: @escaping () -> Void) {
        Self.installEventHandlerOnce()
        let id = Self.nextId
        Self.nextId += 1
        Self.handlers[id] = action
        let status = RegisterEventHotKey(
            shortcut.keyCode, shortcut.modifiers, EventHotKeyID(signature: Self.signature, id: id),
            GetApplicationEventTarget(), 0, &reference)
        if status != noErr {
            Log.write("Raccourci \(shortcut.label) indisponible (OSStatus \(status)) — déjà pris par une autre app ?")
        }
    }

    private static func installEventHandlerOnce() {
        guard !eventHandlerInstalled else { return }
        eventHandlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                var hotKeyId = EventHotKeyID()
                GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &hotKeyId)
                let id = hotKeyId.id
                // Carbon delivers hot-key events on the main thread.
                MainActor.assumeIsolated { HotKey.handlers[id]?() }
                return noErr
            }, 1, &spec, nil, nil)
    }
}
