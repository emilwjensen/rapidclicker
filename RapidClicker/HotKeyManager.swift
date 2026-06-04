//
//  HotKeyManager.swift
//  RapidClicker
//
//  Thin wrapper around the Carbon global hotkey API. Installs a single event
//  handler and invokes `onTrigger` whenever the registered hotkey is pressed,
//  from anywhere in the system.
//

import Carbon

final class HotKeyManager {
    /// Called on the main queue when the registered hotkey fires.
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    /// Four-char signature identifying our hotkey in the Carbon event stream.
    private static let signature = "Rcik".fourCharCodeValue

    init() {
        installHandler()
    }

    deinit {
        unregister()
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    /// Registers (replacing any existing) the global hotkey. Returns `true` on success.
    @discardableResult
    func register(modifiers: UInt32, keyCode: UInt32) -> Bool {
        unregister()
        let id = EventHotKeyID(signature: Self.signature, id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, id,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        return status == noErr
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: OSType(kEventHotKeyPressed))
        // Pass `self` through the handler's userData so the C callback (which
        // can't capture context) can reach this instance.
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, eventPtr, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            GetEventParameter(eventPtr,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hotKeyID)

            if hotKeyID.signature == HotKeyManager.signature {
                DispatchQueue.main.async { manager.onTrigger?() }
            }
            return noErr
        }, 1, &spec, context, &handlerRef)
    }
}
