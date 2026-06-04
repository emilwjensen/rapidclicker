//
//  RapidClickerTests.swift
//  RapidClickerTests
//
//  Created by Emil Wirén Jensen on 2025-05-06.
//

import Testing
import Carbon
@testable import RapidClicker

struct RapidClickerTests {

    @Test func letterListCoversAToZ() {
        #expect(KeyCodes.letters.count == 26)
        #expect(KeyCodes.letters.first == "A")
        #expect(KeyCodes.letters.last == "Z")
    }

    @Test func everyOfferedLetterHasAKeyCode() {
        for letter in KeyCodes.letters {
            #expect(KeyCodes.code(for: letter) != nil)
        }
    }

    @Test func unsupportedLetterHasNoKeyCode() {
        #expect(KeyCodes.code(for: "1") == nil)
        #expect(KeyCodes.code(for: "a") == nil) // lowercase isn't in the map
    }

    @Test func fourCharCodePacksBytesBigEndian() {
        // 'R'=0x52, 'c'=0x63, 'i'=0x69, 'k'=0x6B
        #expect("Rcik".fourCharCodeValue == 0x5263_696B)
    }

    @Test func everyModifierComboIncludesShift() {
        #expect(!ModifierCombo.all.isEmpty)
        for combo in ModifierCombo.all {
            #expect(combo.mask & UInt32(shiftKey) != 0)
        }
    }

    @Test func comboLookupByMaskRoundTrips() {
        for combo in ModifierCombo.all {
            #expect(ModifierCombo.combo(forMask: combo.mask)?.title == combo.title)
        }
    }
}
