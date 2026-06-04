//
//  ClickerModel.swift
//  RapidClicker
//
//  The app's single source of truth. Owns the click engine and the global
//  hotkey, exposes observable state to the SwiftUI views, and persists the
//  user's settings.
//

import AppKit
import Carbon
import Observation
import ApplicationServices

@Observable
final class ClickerModel {

    // MARK: - Observable state

    /// Whether the auto-clicker is currently firing.
    private(set) var isRunning = false

    /// Clicks sent in the current run (live; resets each time clicking starts).
    private(set) var clicksSent = 0

    /// Seconds between synthesized clicks (kept within `intervalRange`).
    var interval: TimeInterval {
        didSet {
            // Clamp out-of-range values. Re-assigning here re-enters `didSet`
            // once (because @Observable makes this a computed setter), so guard
            // it to avoid infinite recursion.
            let clamped = min(max(interval, Self.intervalRange.lowerBound), Self.intervalRange.upperBound)
            if interval != clamped {
                interval = clamped
                return
            }
            defaults.set(interval, forKey: Keys.interval)
            if isRunning { clicker.start(interval: interval) }
        }
    }

    /// Carbon modifier mask for the global hotkey (always includes Shift).
    var modifierMask: UInt32 {
        didSet { persistAndRegisterHotKey() }
    }

    /// Uppercase letter ("A"–"Z") for the global hotkey.
    var keyLetter: String {
        didSet { persistAndRegisterHotKey() }
    }

    /// Whether the app has been granted Accessibility permission.
    private(set) var accessibilityTrusted = AXIsProcessTrusted()

    // MARK: - Constants

    /// User-facing click-rate range, in clicks per second.
    static let rateRange: ClosedRange<Double> = 1...100

    /// Allowed interval range (seconds), derived from `rateRange`.
    static let intervalRange: ClosedRange<TimeInterval> =
        (1.0 / rateRange.upperBound)...(1.0 / rateRange.lowerBound)

    // MARK: - Collaborators

    @ObservationIgnored private let clicker = AutoClicker()
    @ObservationIgnored private let hotKey = HotKeyManager()
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var displayTimer: Timer?

    private enum Keys {
        static let modifiers = "savedModifiers"
        static let key = "savedKey"
        static let interval = "savedInterval"
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        // Seed a default ⌘+⇧+A hotkey on first launch.
        if defaults.string(forKey: Keys.key) == nil {
            defaults.set(Int(UInt32(cmdKey) | UInt32(shiftKey)), forKey: Keys.modifiers)
            defaults.set("A", forKey: Keys.key)
        }

        let savedInterval = defaults.object(forKey: Keys.interval) as? TimeInterval ?? 0.1
        interval = min(max(savedInterval, Self.intervalRange.lowerBound), Self.intervalRange.upperBound)
        modifierMask = UInt32(defaults.integer(forKey: Keys.modifiers))
        keyLetter = defaults.string(forKey: Keys.key) ?? "A"

        hotKey.onTrigger = { [weak self] in self?.toggle() }
        registerHotKey()

        // Re-check Accessibility status whenever the app comes forward, so the
        // UI updates after the user grants permission in System Settings.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshAccessibility()
        }
    }

    // MARK: - Clicking

    /// Starts or stops clicking.
    func toggle() {
        if isRunning {
            clicker.stop()
            stopDisplayUpdates()
        } else {
            clicker.resetCount()
            clicksSent = 0
            clicker.start(interval: interval)
            startDisplayUpdates()
        }
        isRunning = clicker.isRunning
    }

    /// Polls the engine a few times a second to surface a live click count.
    private func startDisplayUpdates() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.clicksSent = self.clicker.currentCount()
        }
    }

    private func stopDisplayUpdates() {
        displayTimer?.invalidate()
        displayTimer = nil
        clicksSent = clicker.currentCount()
    }

    // MARK: - Derived display values

    /// Click rate in clicks per second. Backed by `interval` (= 1 / rate).
    var clicksPerSecond: Double {
        get { interval > 0 ? 1.0 / interval : Self.rateRange.upperBound }
        set {
            let clamped = min(max(newValue, Self.rateRange.lowerBound), Self.rateRange.upperBound)
            interval = 1.0 / clamped
        }
    }

    /// Click rate rounded to a whole number, for display and text entry.
    var roundedRate: Int { Int(clicksPerSecond.rounded()) }

    var intervalDescription: String { String(format: "%.3f s", interval) }

    var hotKeyDescription: String {
        let modifiers = ModifierCombo.combo(forMask: modifierMask)?.title ?? "?"
        return "\(modifiers)+\(keyLetter)"
    }

    // MARK: - Accessibility

    func refreshAccessibility() {
        accessibilityTrusted = AXIsProcessTrusted()
    }

    /// Prompts for Accessibility permission and opens the relevant settings pane.
    func requestAccessibility() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        accessibilityTrusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Hotkey plumbing

    private func persistAndRegisterHotKey() {
        defaults.set(Int(modifierMask), forKey: Keys.modifiers)
        defaults.set(keyLetter, forKey: Keys.key)
        registerHotKey()
    }

    private func registerHotKey() {
        guard let keyCode = KeyCodes.code(for: keyLetter) else { return }
        hotKey.register(modifiers: modifierMask, keyCode: keyCode)
    }
}
