//
//  AppDelegate.swift
//  RapidClicker
//
//  App lifecycle: installs the global hotkey, wires it to the auto-clicker,
//  and makes sure we have the Accessibility permission clicks require.
//

import Cocoa
import Carbon
import ApplicationServices

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let clicker = AutoClicker()
    private var hotKeyRef: EventHotKeyRef?

    /// Four-char signature identifying our hotkey in the Carbon event stream.
    private static let hotKeySignature = "Rcik".fourCharCodeValue

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        promptForAccessibilityIfNeeded()
        installHotKeyHandler()
        registerSavedOrDefaultShortcut()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - Clicking

    /// Toggles clicking on/off and notifies observers (e.g. the Start/Stop button).
    func toggleClick() {
        if clicker.isRunning {
            clicker.stop()
        } else {
            clicker.start(interval: ClickSettings.shared.interval)
        }
        NotificationCenter.default.post(name: .didToggleClick, object: clicker.isRunning)
    }

    // MARK: - Global hotkey

    /// Installs the Carbon handler that listens for our registered hotkey.
    private func installHotKeyHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, eventPtr, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(eventPtr,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hotKeyID)
            if hotKeyID.signature == AppDelegate.hotKeySignature,
               let delegate = NSApp.delegate as? AppDelegate {
                delegate.toggleClick()
            }
            return noErr
        }, 1, &spec, nil, nil)
    }

    /// Registers (or re-registers) the global hotkey. Shows an alert on failure.
    func registerShortcut(modifiers: UInt32, keyCode: UInt32) {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        let hotKeyID = EventHotKeyID(signature: AppDelegate.hotKeySignature, id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            presentHotKeyFailure(status: status)
        }
    }

    /// Reads the saved shortcut from `UserDefaults`, seeding a default ⌘+⇧+A
    /// on first launch, then registers it.
    private func registerSavedOrDefaultShortcut() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: DefaultsKey.key) == nil {
            defaults.set(Int(UInt32(cmdKey) | UInt32(shiftKey)), forKey: DefaultsKey.modifiers)
            defaults.set("A", forKey: DefaultsKey.key)
        }

        let modifiers = UInt32(defaults.integer(forKey: DefaultsKey.modifiers))
        let letter = defaults.string(forKey: DefaultsKey.key) ?? "A"
        guard let keyCode = KeyCodes.code(for: letter) else { return }
        registerShortcut(modifiers: modifiers, keyCode: keyCode)
    }

    private func presentHotKeyFailure(status: OSStatus) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Shortcut Registration Failed"
            alert.informativeText = """
                Could not register the global hotkey (error \(status)). \
                Another app may already be using this combination.
                """
            alert.runModal()
        }
    }

    // MARK: - Accessibility

    /// Posting clicks into other apps requires Accessibility permission. This
    /// prompts the user (once) to grant it in System Settings if not already trusted.
    private func promptForAccessibilityIfNeeded() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }
}
