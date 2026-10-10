//
//  GlobalHotKeyManager.swift
//  FocusTimer
//

import Carbon.HIToolbox
import Foundation

/// Thin wrapper around the Carbon RegisterEventHotKey API, the standard way
/// non-sandboxed macOS apps register systemwide keyboard shortcuts without
/// needing Accessibility/Input Monitoring permission.
final class GlobalHotKeyManager {
    static let shared = GlobalHotKeyManager()

    private let signature: FourCharCode = {
        var result: FourCharCode = 0
        for scalar in "FTMR".unicodeScalars {
            result = (result << 8) + FourCharCode(scalar.value)
        }
        return result
    }()

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1

    private init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handlers[hotKeyID.id]?()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    /// Registers a systemwide shortcut. `modifiers` uses the Carbon modifier
    /// masks (`controlKey`, `optionKey`, `shiftKey`, `cmdKey`), OR'd together.
    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> UInt32 {
        let id = nextID
        nextID += 1

        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        var hotKeyRef: EventHotKeyRef?
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        if let hotKeyRef {
            hotKeyRefs[id] = hotKeyRef
        }
        handlers[id] = handler
        return id
    }

    func unregister(id: UInt32) {
        if let ref = hotKeyRefs.removeValue(forKey: id) {
            UnregisterEventHotKey(ref)
        }
        handlers.removeValue(forKey: id)
    }
}
