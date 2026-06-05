# RapidClicker

A lightweight native **macOS auto-clicker**. Set a click rate, pick a global
hotkey, and RapidClicker repeatedly clicks the left mouse button at your cursor —
until you stop it, or until your auto-stop timer runs out.

<p align="center">
  <img src="RapidClicker/Assets.xcassets/AppIcon.appiconset/256-mac.png" width="128" alt="RapidClicker icon">
</p>

<p align="center">
  <a href="https://github.com/emilwjensen/rapidclicker/actions/workflows/ci.yml">
    <img src="https://github.com/emilwjensen/rapidclicker/actions/workflows/ci.yml/badge.svg" alt="CI status">
  </a>
</p>

## Download & install

1. Download `RapidClicker.dmg` from the
   [latest release](https://github.com/emilwjensen/rapidclicker/releases/latest).
2. Open the `.dmg` and drag **RapidClicker** into your **Applications** folder.
3. **First launch:** because the app isn't notarized, right-click it →
   **Open** → **Open** (you only need to do this once). Or use **System Settings
   → Privacy & Security → Open Anyway**.
4. **Grant Accessibility permission** when prompted (System Settings → Privacy &
   Security → Accessibility), then quit and reopen the app.

For a detailed walkthrough and troubleshooting, see [INSTALL.md](INSTALL.md).

> ⚠️ **Why the warning?** Distributing a Mac app with no Gatekeeper friction
> requires an Apple Developer ID and notarization (a paid Apple Developer
> Program). RapidClicker is signed but not notarized, so the one-time
> right-click-Open step above is expected and safe.

## Requirements

- **macOS 14 (Sonoma)** or later
- Apple Silicon or Intel Mac
- Xcode 16 or later (only to build from source)

## Features

- **Set the speed in clicks per second** — drag the slider (1–200 CPS) or type an
  exact value. The interval in seconds is shown as a secondary readout.
- **Time-based auto-stop** — stop automatically after a set duration in seconds or
  minutes (on by default), with a live countdown, or turn it off to run until you stop it.
- **Recordable global hotkey** — click *record* and press any combination (using
  `⌘`, `⌥`, or `⌃`) to toggle start/stop from anywhere. Warns if the combo is taken.
- **Window + menu bar** — a main window and a menu-bar item, sharing one state.
  Close the window and the app keeps living in the menu bar.
- **Live feedback** — a pulsing indicator and a running "clicks sent" count while
  active; the last run's total stays visible after you stop.
- **Accessibility-aware** — shows whether permission is granted, with a one-click
  way to open the right settings pane; **Start** is disabled until it's granted.
- **Remembers your settings** — speed, hotkey, and auto-stop persist between
  launches (default hotkey: `⌘+⇧+A`).

## Usage

1. Launch RapidClicker and grant Accessibility permission when prompted.
2. Set the **clicks per second** (slider, text field, or stepper).
3. (Optional) Set the **Auto-stop** duration, or uncheck it to click indefinitely.
4. (Optional) Click **record** next to *Shortcut* and press the key combination
   you want for the global hotkey.
5. Click **Start** (or press your hotkey) to begin; **Stop** (or the hotkey
   again) to end.

## Building from source

1. Open `RapidClicker.xcodeproj` in Xcode.
2. Select the **RapidClicker** scheme and press **⌘R**.

> **Code signing:** the project uses Automatic signing. To build under your own
> account, set your Team in *Signing & Capabilities*. The app runs **without the
> App Sandbox** (it posts system-wide events), so it is not eligible for the Mac
> App Store — see [`RapidClicker.entitlements`](RapidClicker/RapidClicker.entitlements).

Run the unit tests with **⌘U** (or `xcodebuild test`). They cover the shortcut
descriptions, key-name lookup, the `FourCharCode` helper, and the speed /
auto-stop clamping. CI runs the same tests on every push.

## Project structure

```
RapidClicker/
├── RapidClickerApp.swift     @main entry point; Window + MenuBarExtra scenes
├── ContentView.swift         Main window UI (speed, auto-stop, hotkey, start/stop)
├── MenuBarView.swift         Menu-bar popover UI
├── ShortcutRecorderView.swift  Records a global hotkey from a key press
├── ClickerModel.swift        @Observable state: settings, engine, permissions
├── AutoClicker.swift         Dispatch-timer click engine
├── HotKeyManager.swift       Carbon global-hotkey registration
├── KeyCodes.swift            Shortcut model + key-name / modifier-symbol helpers
├── Assets.xcassets/          App icon & accent color
├── Info.plist                Bundle configuration
└── RapidClicker.entitlements
RapidClickerTests/            Unit tests (Swift Testing)
scripts/                      DMG build tooling (background + create-dmg)
.github/workflows/            CI (build + test) and Release (DMG on tag)
```

### How it works

- **State** — `ClickerModel` is an `@Observable` single source of truth. SwiftUI
  views bind to it directly; it owns the engine, the hotkey, and persistence.
- **Clicking** — `AutoClicker` runs a high-priority `DispatchSourceTimer`; each
  tick posts a `.leftMouseDown` + `.leftMouseUp` pair via `CGEvent` at the
  cursor's location, and stops precisely when the auto-stop limit is reached.
- **Hotkey** — `HotKeyManager` wraps the Carbon `RegisterEventHotKey` API, tagged
  with a four-char signature (`"Rcik"`), and calls back to toggle clicking.
- **Permissions** — the model checks `AXIsProcessTrusted()` and re-checks while
  the app is active, so the UI reflects Accessibility status live.

## License

Released under the [MIT License](LICENSE).

---

Built by **Emil Wirén Jensen (EWJ)**.
