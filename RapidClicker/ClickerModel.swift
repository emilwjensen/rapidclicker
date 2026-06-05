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

/// Unit for the time-based auto-stop duration.
enum AutoStopUnit: String, CaseIterable, Identifiable {
    case seconds, minutes
    var id: String { rawValue }
    var label: String { self == .seconds ? "seconds" : "minutes" }
    var factor: Int { self == .seconds ? 1 : 60 }
}

@Observable
final class ClickerModel {

    // MARK: - Observable state

    /// Whether the auto-clicker is currently firing.
    private(set) var isRunning = false

    /// Clicks sent in the current run (live; resets each time clicking starts).
    private(set) var clicksSent = 0

    /// Seconds left before the time-based auto-stop fires (nil if not applicable).
    private(set) var secondsRemaining: Int?

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

    /// The global hotkey. Change it via `setShortcut(keyCode:modifiers:)`.
    private(set) var shortcut: Shortcut

    /// Set when a requested shortcut couldn't be registered (e.g. already in use).
    var shortcutError: String?

    /// Whether clicking should stop automatically after a set duration.
    var autoStopEnabled: Bool {
        didSet { defaults.set(autoStopEnabled, forKey: Keys.autoStopEnabled) }
    }

    /// The auto-stop duration value (paired with `autoStopUnit`).
    var autoStopValue: Int {
        didSet {
            let clamped = min(max(autoStopValue, Self.autoStopValueRange.lowerBound), Self.autoStopValueRange.upperBound)
            if autoStopValue != clamped {
                autoStopValue = clamped
                return
            }
            defaults.set(autoStopValue, forKey: Keys.autoStopValue)
        }
    }

    /// The unit for `autoStopValue` (seconds or minutes).
    var autoStopUnit: AutoStopUnit {
        didSet { defaults.set(autoStopUnit.rawValue, forKey: Keys.autoStopUnit) }
    }

    /// Whether the app has been granted Accessibility permission.
    private(set) var accessibilityTrusted = AXIsProcessTrusted()

    // MARK: - Constants

    /// User-facing click-rate range, in clicks per second.
    static let rateRange: ClosedRange<Double> = 1...200

    /// Allowed range for the auto-stop duration value.
    static let autoStopValueRange: ClosedRange<Int> = 1...999

    /// Allowed interval range (seconds), derived from `rateRange`.
    static let intervalRange: ClosedRange<TimeInterval> =
        (1.0 / rateRange.upperBound)...(1.0 / rateRange.lowerBound)

    /// The auto-stop duration in seconds.
    var autoStopDuration: TimeInterval { TimeInterval(autoStopValue * autoStopUnit.factor) }

    // MARK: - Collaborators

    @ObservationIgnored private let clicker = AutoClicker()
    @ObservationIgnored private let hotKey = HotKeyManager()
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var displayTimer: Timer?
    @ObservationIgnored private var autoStopTimer: Timer?
    @ObservationIgnored private var runEndDate: Date?

    private enum Keys {
        static let modifiers = "savedModifiers"
        static let key = "savedKey"          // legacy: A–Z letter
        static let keyCode = "savedKeyCode"
        static let interval = "savedInterval"
        static let autoStopEnabled = "autoStopEnabled"
        static let autoStopValue = "autoStopValue"
        static let autoStopUnit = "autoStopUnit"
    }

    // MARK: - Init

    /// `defaults` is injectable so tests can use an isolated store and never
    /// touch the user's real settings.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedInterval = defaults.object(forKey: Keys.interval) as? TimeInterval ?? 0.01
        interval = min(max(savedInterval, Self.intervalRange.lowerBound), Self.intervalRange.upperBound)

        // Load the saved shortcut, migrating from the old letter-based format.
        let savedMods = UInt32(defaults.integer(forKey: Keys.modifiers))
        if defaults.object(forKey: Keys.keyCode) != nil {
            shortcut = Shortcut(keyCode: UInt32(defaults.integer(forKey: Keys.keyCode)), modifiers: savedMods)
        } else if let letter = defaults.string(forKey: Keys.key),
                  let code = KeyCodes.code(for: letter), savedMods != 0 {
            shortcut = Shortcut(keyCode: code, modifiers: savedMods)
        } else {
            shortcut = .default
        }

        // Auto-stop defaults to on, after 5 minutes.
        autoStopEnabled = defaults.object(forKey: Keys.autoStopEnabled) as? Bool ?? true
        let savedValue = defaults.object(forKey: Keys.autoStopValue) as? Int ?? 5
        autoStopValue = min(max(savedValue, Self.autoStopValueRange.lowerBound), Self.autoStopValueRange.upperBound)
        autoStopUnit = AutoStopUnit(rawValue: defaults.string(forKey: Keys.autoStopUnit) ?? "") ?? .minutes

        hotKey.onTrigger = { [weak self] in self?.toggle() }
        _ = hotKey.register(modifiers: shortcut.modifiers, keyCode: shortcut.keyCode)
        persistShortcut()

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
        if isRunning { stopClicking() } else { startClicking() }
    }

    private func startClicking() {
        clicker.resetCount()
        clicksSent = 0
        clicker.start(interval: interval)

        if autoStopEnabled {
            let duration = autoStopDuration
            runEndDate = Date().addingTimeInterval(duration)
            secondsRemaining = Int(duration.rounded())
            autoStopTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.stopClicking()
            }
        } else {
            runEndDate = nil
            secondsRemaining = nil
        }

        startDisplayUpdates()
        isRunning = true
    }

    private func stopClicking() {
        clicker.stop()
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        runEndDate = nil
        secondsRemaining = nil
        stopDisplayUpdates()
        isRunning = false
    }

    /// Polls the engine a few times a second to surface a live click count and countdown.
    private func startDisplayUpdates() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.clicksSent = self.clicker.currentCount()
            if let end = self.runEndDate {
                self.secondsRemaining = max(0, Int(end.timeIntervalSinceNow.rounded(.up)))
            }
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

    /// e.g. "30 seconds" / "5 minutes".
    var autoStopDescription: String {
        "\(autoStopValue) \(autoStopValue == 1 ? String(autoStopUnit.label.dropLast()) : autoStopUnit.label)"
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

    // MARK: - Hotkey

    /// Tries to adopt a new global hotkey. If it can't be registered (e.g. the
    /// combo is already taken), keeps the existing one and reports an error.
    func setShortcut(keyCode: UInt32, modifiers: UInt32) {
        let candidate = Shortcut(keyCode: keyCode, modifiers: modifiers)
        guard candidate != shortcut else { shortcutError = nil; return }

        if hotKey.register(modifiers: modifiers, keyCode: keyCode) {
            shortcut = candidate
            persistShortcut()
            shortcutError = nil
        } else {
            // Re-register the previous shortcut so we still have a working hotkey.
            _ = hotKey.register(modifiers: shortcut.modifiers, keyCode: shortcut.keyCode)
            shortcutError = "“\(candidate.description)” is unavailable — it may already be in use."
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                self?.shortcutError = nil
            }
        }
    }

    private func persistShortcut() {
        defaults.set(Int(shortcut.modifiers), forKey: Keys.modifiers)
        defaults.set(Int(shortcut.keyCode), forKey: Keys.keyCode)
    }
}
