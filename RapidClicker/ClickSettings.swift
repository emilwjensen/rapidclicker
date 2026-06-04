//
//  ClickSettings.swift
//  RapidClicker
//
//  Shared, observable settings plus the notification names the UI listens on.
//

import Foundation

extension Notification.Name {
    /// Posted when clicking is toggled. `object` is a `Bool` (true == running).
    static let didToggleClick = Notification.Name("didToggleClick")
    /// Posted when the click interval changes. `object` is the new `TimeInterval`.
    static let didChangeInterval = Notification.Name("didChangeInterval")
}

/// Keys used to persist the chosen shortcut in `UserDefaults`.
enum DefaultsKey {
    static let modifiers = "savedModifiers"
    static let key = "savedKey"
}

/// Shared, observable settings for the auto-clicker.
final class ClickSettings {
    static let shared = ClickSettings()
    private init() {}

    /// Smallest and largest interval (seconds) the UI exposes.
    static let minInterval: TimeInterval = 0.001
    static let maxInterval: TimeInterval = 0.1

    /// Seconds between synthesized clicks. Posts `.didChangeInterval` on change.
    var interval: TimeInterval = 0.01 {
        didSet {
            NotificationCenter.default.post(name: .didChangeInterval, object: interval)
        }
    }
}
