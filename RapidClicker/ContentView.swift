//
//  ContentView.swift
//  RapidClicker
//
//  The main settings window: Accessibility status, click speed, the global
//  hotkey, and the Start/Stop control.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(ClickerModel.self) private var model
    @State private var pulse = false

    private enum Field { case rate, limit }
    @FocusState private var focusedField: Field?

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

        // Whole-number auto-stop duration value for its text field.
        let stopValue = Binding<Int>(
            get: { model.autoStopValue },
            set: { model.autoStopValue = $0 }
        )

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
                            .focused($focusedField, equals: .rate)
                            .onSubmit { focusedField = nil }
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
                HStack(spacing: 8) {
                    Toggle("Stop after", isOn: $model.autoStopEnabled)
                        .toggleStyle(.checkbox)
                    TextField("", value: stopValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 56)
                        .focused($focusedField, equals: .limit)
                        .onSubmit { focusedField = nil }
                        .disabled(!model.autoStopEnabled)
                    Picker("", selection: $model.autoStopUnit) {
                        ForEach(AutoStopUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 104)
                    .disabled(!model.autoStopEnabled)
                    Spacer()
                }
                .padding(4)
            } label: {
                Label("Auto-stop", systemImage: "timer")
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Shortcut")
                        Spacer()
                        ShortcutRecorderView(current: model.shortcut.description) { keyCode, modifiers in
                            model.setShortcut(keyCode: keyCode, modifiers: modifiers)
                        }
                    }

                    if let error = model.shortcutError {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Press \(Text(model.shortcut.description).bold()) anywhere to start or stop.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
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
        .background(
            // Tapping anywhere outside the controls drops the rate field's focus.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
        )
        .onAppear {
            // Don't let the rate field grab focus (and a highlight) on launch.
            DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) }
        }
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
            Text(statusText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: model.clicksSent)
        }
        .onChange(of: model.isRunning) { _, running in
            pulse = running
        }
    }

    /// Status text: live count (and countdown) while running, last total once stopped.
    private var statusText: String {
        if model.isRunning {
            var text = "Clicking — \(model.clicksSent) sent"
            if let remaining = model.secondsRemaining {
                text += " · \(remaining)s left"
            }
            return text
        }
        if model.clicksSent > 0 { return "Stopped — \(model.clicksSent) sent" }
        return "Idle"
    }

    private var header: some View {
        HStack {
            Text("RapidClicker")
                .font(.title2.bold())
            Spacer()
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
