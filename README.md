# RapidClicker

A lightweight native **macOS auto-clicker**. Set a click speed, pick a global
hotkey, and RapidClicker will repeatedly click the left mouse button wherever
your cursor is — until you toggle it off with the same hotkey.

<p align="center">
  <img src="RapidClicker/Assets.xcassets/AppIcon.appiconset/256-mac.png" width="128" alt="RapidClicker icon">
</p>

## Features

- **Adjustable click rate** — from 0.001 s to 0.1 s between clicks (≈10–1000 clicks/sec).
- **Global hotkey toggle** — start/stop without switching to the app. Pick a
  modifier combo (`⌘+⇧`, `⌥+⇧`, or `⌘+⌥+⇧`) plus a letter `A`–`Z`.
- **Menu-bar item** — quick start/stop and a glance at your settings from the
  menu bar, in addition to the main window.
- **Live Accessibility status** — the UI shows whether permission is granted and
  offers a one-click way to open the right settings pane.
- **Remembers your settings** — hotkey and interval persist between launches
  (default hotkey: `⌘+⇧+A`).
- **Clicks at the cursor** — each click is posted at the pointer's current location.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16 or later (to build from source)

Built with **SwiftUI** (window + `MenuBarExtra`) and the Observation framework.

## Building & running

1. Open `RapidClicker.xcodeproj` in Xcode.
2. Select the **RapidClicker** scheme and press **⌘R**.

> **Note on code signing:** the project is set to *Automatic* signing with a
> development team. To build under your own account, change the Team in
> *Signing & Capabilities* (or set it to "None" for a local-only build).

### Accessibility permission (required)

RapidClicker synthesizes mouse events into other apps, which macOS gates behind
the **Accessibility** privacy permission. On first launch the app prompts you to
grant it. If clicks don't seem to register:

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Enable **RapidClicker** (add it with **+** if it isn't listed).
3. Relaunch the app.

> Because it posts system-wide events, the app runs **without the App Sandbox**
> and is therefore not distributable via the Mac App Store. See
> [`RapidClicker.entitlements`](RapidClicker/RapidClicker.entitlements).

## Usage

1. Launch RapidClicker and grant Accessibility permission when prompted (a banner
   in the window also offers a **Grant…** button).
2. Choose a **modifier + key** from the two menus — the global hotkey updates
   immediately.
3. Drag the slider to set your click **interval**.
4. Click **Start** (or press your hotkey) to begin; **Stop** (or the hotkey
   again) to end. The hotkey and the menu-bar item work even when the window
   isn't focused — close the window and the app keeps living in the menu bar.

## Project structure

```
RapidClicker/
├── RapidClickerApp.swift   @main entry point; Window + MenuBarExtra scenes
├── ContentView.swift       Main window UI (speed, hotkey, start/stop)
├── MenuBarView.swift        Menu-bar popover UI
├── ClickerModel.swift       @Observable state: settings, engine, permissions
├── AutoClicker.swift        Timer that posts the synthetic mouse clicks
├── HotKeyManager.swift      Carbon global-hotkey registration
├── KeyCodes.swift           Letter↔key-code map, modifier combos, FourCharCode
├── Assets.xcassets/         App icon & accent color
├── Info.plist               Bundle configuration
└── RapidClicker.entitlements
RapidClickerTests/           Unit tests (Swift Testing)
RapidClickerUITests/         UI test stubs (XCTest)
```

### How it works

- **State** — `ClickerModel` is an `@Observable` single source of truth. SwiftUI
  views bind to it directly; it owns the engine, the hotkey, and persistence.
- **Hotkey** — `HotKeyManager` wraps the Carbon `RegisterEventHotKey` API, tagging
  the hotkey with a four-char signature (`"Rcik"`). Its event handler calls back
  into the model to toggle clicking.
- **Clicking** — `AutoClicker` schedules a repeating `Timer`; each tick posts a
  `.leftMouseDown` + `.leftMouseUp` pair via `CGEvent` at the cursor's location.
- **Permissions** — the model checks `AXIsProcessTrusted()` and refreshes when the
  app becomes active, so the UI reflects Accessibility status live.

## Tests

Run the unit tests from Xcode with **⌘U**. They cover the key-code map, the
modifier combinations, and the `FourCharCode` packing helper.

## License

No license has been specified yet. All rights reserved by the author unless a
`LICENSE` file is added.

---

Built by **Emil Wirén Jensen (EWJ)**.
