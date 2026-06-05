//
//  ShortcutRecorderView.swift
//  RapidClicker
//
//  A button that records a global keyboard shortcut: click it, then press the
//  key combination you want. Requires at least one of ⌘ / ⌥ / ⌃.
//

import SwiftUI
import Carbon

struct ShortcutRecorderView: View {
    /// Current shortcut, shown when not recording.
    let current: String
    /// Called with a Carbon key code + Carbon modifier mask when a combo is captured.
    let onRecord: (UInt32, UInt32) -> Void

    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggle) {
            Text(recording ? "Press keys…" : current)
                .font(.body.monospaced())
                .frame(minWidth: 120)
        }
        .buttonStyle(.bordered)
        .tint(recording ? .accentColor : nil)
        .help("Click, then press a shortcut using ⌘, ⌥ or ⌃. Press Esc to cancel.")
        .onDisappear(perform: stop)
    }

    private func toggle() { recording ? stop() : start() }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil  // swallow the event while recording
        }
    }

    private func stop() {
        recording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handle(_ event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        if keyCode == UInt32(kVK_Escape) { stop(); return }  // cancel

        let carbon = Self.carbonModifiers(from: event.modifierFlags)
        let required = UInt32(cmdKey) | UInt32(optionKey) | UInt32(controlKey)
        guard carbon & required != 0 else { return }  // keep waiting for a real combo

        onRecord(keyCode, carbon)
        stop()
    }

    /// Translates AppKit modifier flags to a Carbon modifier mask.
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mask: UInt32 = 0
        if flags.contains(.command) { mask |= UInt32(cmdKey) }
        if flags.contains(.option) { mask |= UInt32(optionKey) }
        if flags.contains(.control) { mask |= UInt32(controlKey) }
        if flags.contains(.shift) { mask |= UInt32(shiftKey) }
        return mask
    }
}
