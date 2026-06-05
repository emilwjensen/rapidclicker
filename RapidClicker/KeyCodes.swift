//
//  KeyCodes.swift
//  RapidClicker
//
//  The global hotkey model: a `Shortcut` (Carbon key code + modifier mask) with
//  a human-readable description, plus the key-name / modifier-symbol helpers and
//  the FourCharCode helper used to tag our hotkey in the Carbon event stream.
//

import Carbon

/// Helpers for translating Carbon virtual key codes to display names.
enum KeyCodes {
    /// Uppercase letters A–Z, in order. (Kept for migrating older saved keys.)
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

    /// Display names for non-letter keys we want to show nicely.
    private static let specialNames: [UInt32: String] = [
        UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_Space): "Space", UInt32(kVK_Return): "Return", UInt32(kVK_Tab): "Tab",
        UInt32(kVK_Escape): "Esc", UInt32(kVK_Delete): "Delete", UInt32(kVK_ForwardDelete): "⌦",
        UInt32(kVK_LeftArrow): "←", UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑", UInt32(kVK_DownArrow): "↓",
        UInt32(kVK_Home): "Home", UInt32(kVK_End): "End",
        UInt32(kVK_PageUp): "Page Up", UInt32(kVK_PageDown): "Page Down",
        UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12",
        UInt32(kVK_ANSI_Minus): "-", UInt32(kVK_ANSI_Equal): "=",
        UInt32(kVK_ANSI_LeftBracket): "[", UInt32(kVK_ANSI_RightBracket): "]",
        UInt32(kVK_ANSI_Semicolon): ";", UInt32(kVK_ANSI_Quote): "'",
        UInt32(kVK_ANSI_Comma): ",", UInt32(kVK_ANSI_Period): ".",
        UInt32(kVK_ANSI_Slash): "/", UInt32(kVK_ANSI_Backslash): "\\",
        UInt32(kVK_ANSI_Grave): "`",
    ]

    private static let byCode: [UInt32: String] = {
        var map = specialNames
        for (letter, code) in byLetter { map[code] = letter }
        return map
    }()

    /// A display name for a Carbon virtual key code.
    static func name(for keyCode: UInt32) -> String {
        byCode[keyCode] ?? "Key \(keyCode)"
    }

    /// Carbon modifier mask rendered as "⌃⌥⇧⌘" symbols (Apple's display order).
    static func symbols(for modifiers: UInt32) -> String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        return s
    }
}

/// A global keyboard shortcut: a Carbon virtual key code plus a Carbon modifier mask.
struct Shortcut: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    /// e.g. "⌘⇧A" or "⌃⌥Space".
    var description: String {
        KeyCodes.symbols(for: modifiers) + KeyCodes.name(for: keyCode)
    }

    /// The seeded default: ⌘⇧A.
    static let `default` = Shortcut(keyCode: UInt32(kVK_ANSI_A),
                                    modifiers: UInt32(cmdKey) | UInt32(shiftKey))
}

extension String {
    /// Packs the string's UTF-16 code units into a Carbon `FourCharCode`.
    var fourCharCodeValue: FourCharCode {
        utf16.reduce(0) { ($0 << 8) + FourCharCode($1) }
    }
}
