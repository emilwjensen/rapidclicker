//
//  ContentView.swift
//  RapidClicker
//
//  The main settings window: Accessibility status, click speed, the global
//  hotkey, and the Start/Stop control.
//

import SwiftUI

struct ContentView: View {
    @Environment(ClickerModel.self) private var model
    @State private var pulse = false

    /// While permission is missing, re-check periodically so the banner clears
    /// as soon as the user enables it in System Settings.
    private let permissionTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        @Bindable var model = model

        // Whole-number clicks-per-second, for the text field and stepper.
        let rate = Binding<Int>(
            get: { model.roundedRate },
            set: { model.clicksPerSecond = Double($0) }
        )
        let rateBounds = Int(ClickerModel.rateRange.lowerBound)...Int(ClickerModel.rateRange.upperBound)

        VStack(spacing: 18) {
            header

            if !model.accessibilityTrusted {
                accessibilityBanner
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("Clicks per second")
                        Spacer()
                        TextField("CPS", value: rate, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 64)
                        Stepper("", value: rate, in: rateBounds).labelsHidden()
                    }
                    Slider(value: $model.clicksPerSecond, in: ClickerModel.rateRange)
                    HStack {
                        Text("Interval")
                        Spacer()
                        Text(model.intervalDescription).monospacedDigit().foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .padding(4)
            } label: {
                Label("Click Speed", systemImage: "speedometer")
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Picker("Modifiers", selection: $model.modifierMask) {
                            ForEach(ModifierCombo.all, id: \.mask) { combo in
                                Text(combo.title).tag(combo.mask)
                            }
                        }
                        Picker("Key", selection: $model.keyLetter) {
                            ForEach(KeyCodes.letters, id: \.self) { letter in
                                Text(letter).tag(letter)
                            }
                        }
                    }
                    .labelsHidden()

                    Text("Press \(Text(model.hotKeyDescription).bold()) anywhere to start or stop.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(4)
            } label: {
                Label("Global Hotkey", systemImage: "command")
            }

            Button(action: model.toggle) {
                Label(model.isRunning ? "Stop" : "Start",
                      systemImage: model.isRunning ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(model.isRunning ? .red : .green)
            .keyboardShortcut(.defaultAction)
            .disabled(!model.accessibilityTrusted)
            .help(model.accessibilityTrusted
                  ? "Start or stop clicking (or use your hotkey)."
                  : "Grant Accessibility permission first — clicks can't be sent without it.")

            statusLine

            Text("built by EWJ")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(22)
        .frame(width: 360)
        .onReceive(permissionTimer) { _ in
            if !model.accessibilityTrusted { model.refreshAccessibility() }
        }
    }

    /// Live status under the Start button: pulses and counts while running.
    private var statusLine: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(model.isRunning ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 7, height: 7)
                .opacity(model.isRunning && pulse ? 0.3 : 1)
                .animation(model.isRunning
                           ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                           : .default,
                           value: pulse)
            Text(model.isRunning ? "Clicking — \(model.clicksSent) sent" : "Idle")
                .font(.callout)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: model.clicksSent)
        }
        .onChange(of: model.isRunning) { _, running in
            pulse = running
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("RapidClicker")
                .font(.title2.bold())
            Spacer()
            Circle()
                .fill(model.isRunning ? .green : .secondary.opacity(0.4))
                .frame(width: 10, height: 10)
        }
    }

    private var accessibilityBanner: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Accessibility permission required")
                        .fontWeight(.semibold)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }

                Text("RapidClicker can't click in other apps until you enable it under Privacy & Security → Accessibility. Turn it on there, then come back — this banner clears automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    model.requestAccessibility()
                } label: {
                    Text("Open Accessibility Settings…")
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }
}

#Preview {
    ContentView()
        .environment(ClickerModel())
}
