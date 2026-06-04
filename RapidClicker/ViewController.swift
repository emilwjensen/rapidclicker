//
//  ViewController.swift
//  RapidClicker
//
//  The single settings window: pick a modifier + letter for the global hotkey,
//  set the click interval, and start/stop clicking.
//

import Cocoa

final class ViewController: NSViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var modifiersMenu: NSPopUpButton!
    @IBOutlet weak var keyMenu: NSPopUpButton!
    @IBOutlet weak var setShortcutButton: NSButton!
    @IBOutlet weak var toggleButton: NSButton!
    @IBOutlet weak var intervalSlider: NSSlider!
    @IBOutlet weak var intervalLabel: NSTextField!
    @IBOutlet weak var feedbackLabel: NSTextField!

    private var appDelegate: AppDelegate? { NSApp.delegate as? AppDelegate }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMenus()
        restoreSavedSelection()
        configureControls()
        observeNotifications()
    }

    private func configureMenus() {
        modifiersMenu.removeAllItems()
        modifiersMenu.addItems(withTitles: ModifierCombo.all.map(\.title))
        keyMenu.removeAllItems()
        keyMenu.addItems(withTitles: KeyCodes.letters)
    }

    private func restoreSavedSelection() {
        let defaults = UserDefaults.standard
        let savedMask = UInt32(defaults.integer(forKey: DefaultsKey.modifiers))
        let savedKey = defaults.string(forKey: DefaultsKey.key) ?? "A"

        if let index = ModifierCombo.all.firstIndex(where: { $0.mask == savedMask }) {
            modifiersMenu.selectItem(at: index)
        }
        if let index = KeyCodes.letters.firstIndex(of: savedKey) {
            keyMenu.selectItem(at: index)
        }
    }

    private func configureControls() {
        toggleButton.title = "Start"
        feedbackLabel.isHidden = true
        intervalSlider.minValue = ClickSettings.minInterval
        intervalSlider.maxValue = ClickSettings.maxInterval
        intervalSlider.doubleValue = ClickSettings.shared.interval
        updateIntervalLabel()
    }

    private func observeNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleToggle(_:)),
                           name: .didToggleClick, object: nil)
        center.addObserver(self, selector: #selector(handleIntervalChange),
                           name: .didChangeInterval, object: nil)
    }

    // MARK: - IBActions

    @IBAction func setShortcut(_ sender: Any) {
        let modifierIndex = modifiersMenu.indexOfSelectedItem
        let keyIndex = keyMenu.indexOfSelectedItem
        guard ModifierCombo.all.indices.contains(modifierIndex),
              KeyCodes.letters.indices.contains(keyIndex) else { return }

        let mask = ModifierCombo.all[modifierIndex].mask
        let letter = KeyCodes.letters[keyIndex]
        guard let keyCode = KeyCodes.code(for: letter) else { return }

        let defaults = UserDefaults.standard
        defaults.set(Int(mask), forKey: DefaultsKey.modifiers)
        defaults.set(letter, forKey: DefaultsKey.key)

        appDelegate?.registerShortcut(modifiers: mask, keyCode: keyCode)
        showFeedback("Key binding changed")
    }

    @IBAction func toggleClicked(_ sender: NSButton) {
        appDelegate?.toggleClick()
    }

    @IBAction func sliderChanged(_ sender: NSSlider) {
        ClickSettings.shared.interval = sender.doubleValue
    }

    // MARK: - Notification handlers

    @objc private func handleToggle(_ note: Notification) {
        let running = (note.object as? Bool) ?? false
        toggleButton.title = running ? "Stop" : "Start"
    }

    @objc private func handleIntervalChange() {
        updateIntervalLabel()
    }

    // MARK: - Helpers

    private func updateIntervalLabel() {
        intervalLabel.stringValue = String(format: "Interval: %.3f s", ClickSettings.shared.interval)
    }

    private func showFeedback(_ message: String) {
        feedbackLabel.stringValue = message
        feedbackLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.feedbackLabel.isHidden = true
        }
    }
}
