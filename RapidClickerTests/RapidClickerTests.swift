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

    /// A model backed by an isolated UserDefaults suite, so tests never read or
    /// write the app's real settings.
    @MainActor private func makeModel() -> ClickerModel {
        let suite = UserDefaults(suiteName: "RapidClickerTests.\(UUID().uuidString)")!
        return ClickerModel(defaults: suite)
    }

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

    @Test func shortcutDescribesModifiersAndKey() {
        // Modifiers render in macOS's native order: ⌃⌥⇧⌘ (Command rightmost).
        let s = Shortcut(keyCode: UInt32(kVK_ANSI_F),
                         modifiers: UInt32(cmdKey) | UInt32(shiftKey))
        #expect(s.description == "⇧⌘F")

        let s2 = Shortcut(keyCode: UInt32(kVK_Space),
                          modifiers: UInt32(controlKey) | UInt32(optionKey))
        #expect(s2.description == "⌃⌥Space")
    }

    @Test func keyNameFallsBackForUnknownCodes() {
        #expect(KeyCodes.name(for: UInt32(kVK_ANSI_A)) == "A")
        #expect(KeyCodes.name(for: UInt32(kVK_F5)) == "F5")
        #expect(KeyCodes.name(for: 9999).hasPrefix("Key "))
    }

    @Test func defaultShortcutIsCommandShiftA() {
        #expect(Shortcut.default.description == "⇧⌘A")
    }

    @MainActor
    @Test func settingIntervalClampsWithoutRecursing() {
        let model = makeModel()

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
        let model = makeModel()

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
    @Test func autoStopValueClampsAndComputesDuration() {
        let model = makeModel()

        model.autoStopUnit = .seconds
        model.autoStopValue = 30
        #expect(model.autoStopValue == 30)
        #expect(model.autoStopDuration == 30)

        model.autoStopUnit = .minutes
        #expect(model.autoStopDuration == 30 * 60)

        // Out-of-range values clamp (without recursing).
        model.autoStopValue = 0
        #expect(model.autoStopValue == ClickerModel.autoStopValueRange.lowerBound)

        model.autoStopValue = 100_000
        #expect(model.autoStopValue == ClickerModel.autoStopValueRange.upperBound)
    }
}
