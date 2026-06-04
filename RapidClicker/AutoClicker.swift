//
//  AutoClicker.swift
//  RapidClicker
//
//  Synthesizes repeated left mouse clicks at the current cursor location.
//

import Cocoa

/// Drives the actual clicking: a repeating timer that posts a left-button
/// down/up pair at the pointer's current position on every tick.
final class AutoClicker {
    private var timer: Timer?

    /// Whether the clicker is currently firing.
    var isRunning: Bool { timer != nil }

    /// Starts clicking every `interval` seconds. Restarts if already running.
    func start(interval: TimeInterval) {
        stop()
        // Scheduled on the common run-loop mode so it keeps firing while menus
        // or controls are being tracked.
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.click()
        }
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Stops clicking. Safe to call when already stopped.
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Posts a single left-button down/up at the pointer's current position.
    private func click() {
        guard let location = CGEvent(source: nil)?.location else { return }
        let source = CGEventSource(stateID: .combinedSessionState)
        for type in [CGEventType.leftMouseDown, .leftMouseUp] {
            CGEvent(mouseEventSource: source,
                    mouseType: type,
                    mouseCursorPosition: location,
                    mouseButton: .left)?
                .post(tap: .cghidEventTap)
        }
    }
}
