# Installing RapidClicker on macOS

A step-by-step guide to downloading and installing RapidClicker from GitHub.

> **Requirements:** macOS 14 (Sonoma) or later, on Apple Silicon or Intel.

---

## Step 1 — Download the installer

1. Open the **[latest release](https://github.com/emilwjensen/rapidclicker/releases/latest)**.
2. Under **Assets**, click **`RapidClicker.dmg`** to download it.

Or download it directly:

```
https://github.com/emilwjensen/rapidclicker/releases/latest/download/RapidClicker.dmg
```

## Step 2 — Install the app

1. In your **Downloads** folder, double-click **`RapidClicker.dmg`** to open it.
2. A window appears with the **RapidClicker** icon and an **Applications** shortcut.
3. **Drag RapidClicker onto the Applications folder.**
4. Eject the disk image (click the ⏏ next to "RapidClicker" in Finder's sidebar),
   and feel free to delete the `.dmg`.

## Step 3 — Open it the first time (important)

RapidClicker is signed but **not notarized by Apple**, so the first launch needs
one extra step. You only have to do this **once**.

1. Open your **Applications** folder.
2. **Right-click** (or Control-click) **RapidClicker** → **Open**.
3. In the dialog that warns it "cannot be opened because Apple cannot check it…",
   click **Open**.

> If you just double-click instead, macOS blocks it. In that case go to
> **System Settings → Privacy & Security**, scroll down, and click
> **"Open Anyway"** next to the RapidClicker message, then confirm.

## Step 4 — Grant Accessibility permission (required)

RapidClicker sends clicks to other apps, which macOS protects behind the
**Accessibility** permission. The **Start** button stays disabled until you grant it.

1. On first launch the app prompts you — click through to System Settings.
   (Or open **System Settings → Privacy & Security → Accessibility** yourself.)
2. Turn **RapidClicker** **ON** in the list. If it isn't listed, click **+**,
   choose RapidClicker from Applications, and enable it.
3. **Quit RapidClicker and reopen it** so it picks up the new permission.

When granted, the warning banner disappears and **Start** becomes available.

## Step 5 — Use it

1. Set the **clicks per second** with the slider or the text field (1–200).
2. (Optional) Adjust **Auto-stop** — it stops after a set number of clicks
   (default 1000), or uncheck it to run until you stop.
3. Press **Start** (or your global hotkey, default **⌘ + ⇧ + A**) to begin.
   Press it again to stop.

The app also lives in your **menu bar** (the cursor icon) — you can start/stop
and reopen the window from there, even after closing it.

---

## Troubleshooting

**"RapidClicker is damaged and can't be opened."**
macOS sometimes shows this for downloaded, un-notarized apps. Remove the
quarantine flag in Terminal, then open normally:

```bash
xattr -dr com.apple.quarantine /Applications/RapidClicker.app
```

**Clicking does nothing / Start is greyed out.**
Accessibility permission isn't active. Re-check Step 4. If you had an older copy
listed, remove it with **–**, re-add the current app, and **quit & reopen**.

**It clicks in normal apps but not in a game.**
Many games (especially those with anti-cheat) deliberately ignore synthetic
clicks. That's a system/game restriction, not something RapidClicker can change.

**Updating to a newer version.**
Download the new `.dmg` from the latest release and drag it over the old app in
Applications. Your settings are preserved.

## Uninstall

1. Quit RapidClicker.
2. Drag **RapidClicker** from Applications to the Trash.
3. (Optional) Remove its Accessibility entry in
   **System Settings → Privacy & Security → Accessibility**.
