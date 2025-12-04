import Foundation
import Carbon

final class HotKeyManager {
    typealias Handler = () -> Void
    private var handlers: [UInt32: Handler] = [:]
    private var nextID: UInt32 = 1

    init() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handlerRefCon = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (handlerRef, event, userData) -> OSStatus in
                var hkID = EventHotKeyID()

                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
                let id = hkID.id

                guard let userData = userData else { return noErr }

                let mgr = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                mgr.trigger(id: id)

                return noErr
            },
            1,
            &eventSpec,
            handlerRefCon,
            nil
        )
    }

    private func trigger(id: UInt32) {
        handlers[id]?()
    }

    func register(hotKey: (cmd:Bool, shift:Bool, option:Bool, control:Bool, keyCode:UInt32), handler: @escaping Handler) {
        var modifiers: UInt32 = 0
        if hotKey.cmd { modifiers |= UInt32(cmdKey) }
        if hotKey.shift { modifiers |= UInt32(shiftKey) }
        if hotKey.option { modifiers |= UInt32(optionKey) }
        if hotKey.control { modifiers |= UInt32(controlKey) }

        var gHotKeyRef: EventHotKeyRef? = nil
        let hkID = EventHotKeyID(signature: OSType(0x4d544b47), id: nextID) // "MTKG"

        RegisterEventHotKey(hotKey.keyCode, modifiers, hkID, GetApplicationEventTarget(), 0, &gHotKeyRef)

        handlers[nextID] = handler
        nextID += 1
    }

    func unregisterAll() { handlers.removeAll() }
}
