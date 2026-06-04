import Cocoa
import Carbon

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var clickTimer: Timer?
    private var isClicking = false
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1) Install the global hot‑key handler
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  OSType(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventPtr, _ in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    eventPtr,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout.size(ofValue: hkID),
                    nil,
                    &hkID
                )
                if hkID.signature == OSType("Rcik".fourCharCodeValue) {
                    (NSApp.delegate as! AppDelegate).toggleClick()
                }
                return noErr
            },
            1, &spec,
            nil, nil
        )

        // 2) Register either the saved combo or a default ⌘+⇧+A
        registerSavedOrDefault()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }

    /// Register or re‑register the global hot‑key
    func registerShortcut(modifiers: UInt32, keyCode: UInt32) {
        // Unregister existing
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        // Build the Carbon ID
        let hotKeyID = EventHotKeyID(
            signature: OSType("Rcik".fourCharCodeValue),
            id: 1
        )

        // Attempt registration
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        // Debug output
        let names: [(Int,String)] = [
            (cmdKey, "⌘"), (optionKey, "⌥"),
            (controlKey, "⌃"), (shiftKey, "⇧")
        ]
        let modNames = names
            .filter { modifiers & UInt32($0.0) != 0 }
            .map    { $0.1 }
            .joined(separator: "+")
        print("🔑 registerShortcut →", modNames, "+", keyCode, "status:", status)

        // Alert on failure
        if status != noErr {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle      = .warning
                alert.messageText     = "Shortcut Registration Failed"
                alert.informativeText = "Could not register \(modNames) + code \(keyCode) (error \(status))."
                alert.runModal()
            }
        }
    }

    /// Toggle the clicker on/off
    func toggleClick() {
        isClicking.toggle()
        NotificationCenter.default.post(
            name: .didToggleClick,
            object: isClicking
        )
        if isClicking { startClicking() } else { stopClicking() }
    }

    private func startClicking() {
        let interval = ClickSettings.shared.interval
        clickTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in self?.postClick() }
        RunLoop.current.add(clickTimer!, forMode: .common)
    }

    private func stopClicking() {
        clickTimer?.invalidate()
        clickTimer = nil
    }

    private func postClick() {
        let loc = CGEventTapLocation.cghidEventTap
        guard let pt = CGEvent(source: nil)?.location else { return }
        CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: pt,
            mouseButton: .left
        )!.post(tap: loc)
        CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: pt,
            mouseButton: .left
        )!.post(tap: loc)
    }

    /// Reads UserDefaults or sets a default ⌘+⇧+A, then calls registerShortcut(...)
    private func registerSavedOrDefault() {
        let d = UserDefaults.standard
        let savedMod = UInt32(d.integer(forKey: "savedModifiers"))
        let savedKey = d.string(forKey: "savedKey") ?? "A"
        // If nothing saved, store default ⌘+⇧ + "A"
        if d.string(forKey: "savedKey") == nil {
            d.set(Int(UInt32(cmdKey)|UInt32(shiftKey)), forKey: "savedModifiers")
            d.set("A", forKey: "savedKey")
        }
        // Map letter to actual KeyCode
        let keyMap: [String: UInt32] = [
            "A": UInt32(kVK_ANSI_A), "B": UInt32(kVK_ANSI_B),
            "C": UInt32(kVK_ANSI_C), "D": UInt32(kVK_ANSI_D),
            "E": UInt32(kVK_ANSI_E), "F": UInt32(kVK_ANSI_F),
            "G": UInt32(kVK_ANSI_G), "H": UInt32(kVK_ANSI_H),
            "I": UInt32(kVK_ANSI_I), "J": UInt32(kVK_ANSI_J),
            "K": UInt32(kVK_ANSI_K), "L": UInt32(kVK_ANSI_L),
            "M": UInt32(kVK_ANSI_M), "N": UInt32(kVK_ANSI_N),
            "O": UInt32(kVK_ANSI_O), "P": UInt32(kVK_ANSI_P),
            "Q": UInt32(kVK_ANSI_Q), "R": UInt32(kVK_ANSI_R),
            "S": UInt32(kVK_ANSI_S), "T": UInt32(kVK_ANSI_T),
            "U": UInt32(kVK_ANSI_U), "V": UInt32(kVK_ANSI_V),
            "W": UInt32(kVK_ANSI_W), "X": UInt32(kVK_ANSI_X),
            "Y": UInt32(kVK_ANSI_Y), "Z": UInt32(kVK_ANSI_Z)
        ]
        guard let code = keyMap[savedKey] else { return }
        registerShortcut(modifiers: savedMod, keyCode: code)
    }
}

// MARK: – Helpers

extension Notification.Name {
    static let didToggleClick    = Notification.Name("didToggleClick")
    static let didChangeInterval = Notification.Name("didChangeInterval")
}

class ClickSettings {
    static let shared = ClickSettings()
    private init() {}
    var interval: TimeInterval = 0.01 {
        didSet {
            NotificationCenter.default.post(
                name: .didChangeInterval, object: interval
            )
        }
    }
}

extension String {
    var fourCharCodeValue: FourCharCode {
        var code: FourCharCode = 0
        for c in utf16 { code = (code << 8) + FourCharCode(c) }
        return code
    }
}
