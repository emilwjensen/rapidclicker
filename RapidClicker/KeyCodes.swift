//
//  KeyCodes.swift
//  RapidClicker
//
//  Shared definitions for the global hotkey: the bindable letters and their
//  Carbon virtual key codes, the offered modifier combinations, and the
//  FourCharCode helper used to tag our hotkey in the Carbon event stream.
//

import Carbon

/// The A–Z keys the app lets you bind, and their Carbon virtual key codes.
enum KeyCodes {
    /// Uppercase letters A–Z, in order.
    static let letters: [String] = (UnicodeScalar("A").value...UnicodeScalar("Z").value)
        .map { String(UnicodeScalar($0)!) }

    /// Maps an uppercase letter ("A"–"Z") to its Carbon ANSI virtual key code.
    static let byLetter: [String: UInt32] = [
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
        "Y": UInt32(kVK_ANSI_Y), "Z": UInt32(kVK_ANSI_Z),
    ]

    /// Carbon virtual key code for an uppercase letter, or `nil` if unsupported.
    static func code(for letter: String) -> UInt32? { byLetter[letter] }
}

/// A modifier-key combination the user can pair with a letter to form the hotkey.
struct ModifierCombo {
    let title: String
    let mask: UInt32

    /// The combos offered in the UI. Shift is always included so the hotkey
    /// is unlikely to collide with a plain ⌘-letter system shortcut.
    static let all: [ModifierCombo] = [
        ModifierCombo(title: "⌘+⇧",   mask: UInt32(cmdKey)    | UInt32(shiftKey)),
        ModifierCombo(title: "⌥+⇧",   mask: UInt32(optionKey) | UInt32(shiftKey)),
        ModifierCombo(title: "⌘+⌥+⇧", mask: UInt32(cmdKey)    | UInt32(optionKey) | UInt32(shiftKey)),
    ]

    /// The combo whose mask matches `mask`, if any.
    static func combo(forMask mask: UInt32) -> ModifierCombo? {
        all.first { $0.mask == mask }
    }
}

extension String {
    /// Packs the string's UTF-16 code units into a Carbon `FourCharCode`.
    var fourCharCodeValue: FourCharCode {
        utf16.reduce(0) { ($0 << 8) + FourCharCode($1) }
    }
}
