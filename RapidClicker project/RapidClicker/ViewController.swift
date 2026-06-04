import Cocoa
import Carbon

class ViewController: NSViewController {
    // Only ⌘+⇧, ⌥+⇧, or ⌘+⌥+⇧ combos
    let modifierCombos: [(title: String, mask: UInt32)] = [
      ("⌘+⇧",    UInt32(cmdKey)    | UInt32(shiftKey)),
      ("⌥+⇧",    UInt32(optionKey) | UInt32(shiftKey)),
      ("⌘+⌥+⇧", UInt32(cmdKey)    | UInt32(optionKey) | UInt32(shiftKey))
    ]

    // Letters A–Z
    let letters: [String] = (65...90).map { String(UnicodeScalar($0)!) }

    // MARK: – IBOutlets
    @IBOutlet weak var modifiersMenu:    NSPopUpButton!
    @IBOutlet weak var keyMenu:          NSPopUpButton!
    @IBOutlet weak var setShortcutButton:NSButton!
    @IBOutlet weak var toggleButton:     NSButton!
    @IBOutlet weak var intervalSlider:   NSSlider!
    @IBOutlet weak var intervalLabel:    NSTextField!
    @IBOutlet weak var feedbackLabel:    NSTextField!  // must wire

    override func viewDidLoad() {
        super.viewDidLoad()

        // Populate the two pop‑ups
        modifiersMenu.removeAllItems()
        modifiersMenu.addItems(withTitles: modifierCombos.map { $0.title })
        keyMenu.removeAllItems()
        keyMenu.addItems(withTitles: letters)

        // Restore saved selection (or default was set in AppDelegate)
        let d = UserDefaults.standard
        let sm = d.integer(forKey: "savedModifiers")
        let sk = d.string(forKey: "savedKey") ?? "A"
        if let mi = modifierCombos.firstIndex(where: { Int($0.mask) == sm }) {
            modifiersMenu.selectItem(at: mi)
        }
        if let ki = letters.firstIndex(of: sk) {
            keyMenu.selectItem(at: ki)
        }

        // Initial UI
        toggleButton.title    = "Start"
        feedbackLabel.isHidden = true
        intervalSlider.minValue    = 0.001
        intervalSlider.maxValue    = 0.1
        intervalSlider.doubleValue = ClickSettings.shared.interval
        updateIntervalLabel(nil)

        // Observe the toggle event so we can flip the button title
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleToggle(_:)),
            name: .didToggleClick,
            object: nil
        )
        // Observe interval changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateIntervalLabel(_:)),
            name: .didChangeInterval,
            object: nil
        )
    }

    // MARK: – IBActions

    @IBAction func setShortcut(_ sender: Any) {
        let mi = modifiersMenu.indexOfSelectedItem
        guard mi >= 0 && mi < modifierCombos.count else { return }
        let mask = modifierCombos[mi].mask

        let ki = keyMenu.indexOfSelectedItem
        guard ki >= 0 && ki < letters.count else { return }
        let ch = letters[ki]

        // Map letter to Carbon keyCode
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
        guard let keyCode = keyMap[ch] else { return }

        // Persist
        let d = UserDefaults.standard
        d.set(Int(mask), forKey: "savedModifiers")
        d.set(ch,        forKey: "savedKey")

        // Register
        (NSApp.delegate as! AppDelegate)
          .registerShortcut(modifiers: mask, keyCode: keyCode)

        // Show feedback
        feedbackLabel.stringValue = "Key binding changed"
        feedbackLabel.isHidden    = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.feedbackLabel.isHidden = true
        }
    }

    @IBAction func toggleClicked(_ sender: NSButton) {
        (NSApp.delegate as! AppDelegate).toggleClick()
    }

    @IBAction func sliderChanged(_ sender: NSSlider) {
        ClickSettings.shared.interval = sender.doubleValue
    }

    // MARK: – Notification handlers

    @objc private func handleToggle(_ note: Notification) {
        let on = (note.object as? Bool) ?? false
        toggleButton.title = on ? "Stop" : "Start"
    }

    @objc private func updateIntervalLabel(_ note: Notification?) {
        intervalLabel.stringValue =
          String(format: "Interval: %.3f s",
                 ClickSettings.shared.interval)
    }
}
