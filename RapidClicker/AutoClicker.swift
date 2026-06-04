//
//  AutoClicker.swift
//  RapidClicker
//
//  Synthesizes repeated left mouse clicks at the current cursor location.
//

import CoreGraphics
import Foundation

/// Drives the actual clicking: a high-priority dispatch timer that posts a
/// left-button down/up pair at the pointer's current position on every tick.
///
/// A `DispatchSourceTimer` on a dedicated `.userInteractive` queue is used
/// (instead of a main-thread `Timer`) so that high click rates stay accurate
/// and aren't throttled while the UI is doing work.
final class AutoClicker {
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.catalystone.RapidClicker.clicker",
                                      qos: .userInteractive)
    private let eventSource = CGEventSource(stateID: .combinedSessionState)

    /// Whether the clicker is currently firing. Mutated only from the main thread.
    private(set) var isRunning = false

    /// Starts clicking every `interval` seconds. Restarts if already running.
    func start(interval: TimeInterval) {
        stop()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .nanoseconds(0))
        timer.setEventHandler { [weak self] in self?.click() }
        timer.resume()
        self.timer = timer
        isRunning = true
    }

    /// Stops clicking. Safe to call when already stopped.
    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
    }

    /// Posts a single left-button down/up at the pointer's current position.
    private func click() {
        guard let location = CGEvent(source: nil)?.location else { return }
        for type in [CGEventType.leftMouseDown, .leftMouseUp] {
            CGEvent(mouseEventSource: eventSource,
                    mouseType: type,
                    mouseCursorPosition: location,
                    mouseButton: .left)?
                .post(tap: .cghidEventTap)
        }
    }
}
