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

    @MainActor
    @Test func settingIntervalClampsWithoutRecursing() {
        let model = ClickerModel()

        model.interval = 0.05
        #expect(model.interval == 0.05)

        // Out-of-range values must be clamped (and must not infinitely recurse).
        model.interval = 1.0
        #expect(model.interval == ClickerModel.intervalRange.upperBound)

        model.interval = 0.0
        #expect(model.interval == ClickerModel.intervalRange.lowerBound)
    }

    @MainActor
    @Test func clicksPerSecondMapsToIntervalAndClamps() {
        let model = ClickerModel()

        model.clicksPerSecond = 50
        #expect(abs(model.interval - 0.02) < 1e-9)
        #expect(model.roundedRate == 50)

        // Above the maximum rate clamps to the fastest allowed.
        model.clicksPerSecond = 100_000
        #expect(model.roundedRate == Int(ClickerModel.rateRange.upperBound))

        // Below the minimum clamps to the slowest allowed.
        model.clicksPerSecond = 0
        #expect(model.roundedRate == Int(ClickerModel.rateRange.lowerBound))
    }

    @MainActor
    @Test func autoStopCountClampsToRange() {
        let model = ClickerModel()

        model.autoStopCount = 1000
        #expect(model.autoStopCount == 1000)

        model.autoStopCount = 0
        #expect(model.autoStopCount == ClickerModel.autoStopRange.lowerBound)

        model.autoStopCount = 9_999_999
        #expect(model.autoStopCount == ClickerModel.autoStopRange.upperBound)
    }
}
