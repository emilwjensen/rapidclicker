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

    /// Seconds between synthesized clicks (clamped to `intervalRange`).
    var interval: TimeInterval {
        didSet {
            interval = min(max(interval, Self.intervalRange.lowerBound), Self.intervalRange.upperBound)
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

    static let intervalRange: ClosedRange<TimeInterval> = 0.001...0.1

    // MARK: - Collaborators

    @ObservationIgnored private let clicker = AutoClicker()
    @ObservationIgnored private let hotKey = HotKeyManager()
    @ObservationIgnored private let defaults = UserDefaults.standard

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

        let savedInterval = defaults.object(forKey: Keys.interval) as? TimeInterval ?? 0.01
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
        } else {
            clicker.start(interval: interval)
        }
        isRunning = clicker.isRunning
    }

    // MARK: - Derived display values

    var intervalDescription: String { String(format: "%.3f s", interval) }

    var clicksPerSecond: Int { interval > 0 ? Int((1.0 / interval).rounded()) : 0 }

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
