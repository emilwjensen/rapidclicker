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

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 18) {
            header

            if !model.accessibilityTrusted {
                accessibilityBanner
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $model.interval, in: ClickerModel.intervalRange)
                    HStack {
                        Text("Interval")
                        Spacer()
                        Text(model.intervalDescription).monospacedDigit().foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Rate")
                        Spacer()
                        Text("\(model.clicksPerSecond) clicks/sec").foregroundStyle(.secondary)
                    }
                    .font(.callout)
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

            Text("built by EWJ")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(22)
        .frame(width: 340)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "cursorarrow.click.2")
                .font(.title)
                .foregroundStyle(.tint)
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
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility permission required").bold()
                    Text("RapidClicker needs permission to send clicks to other apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Grant…") { model.requestAccessibility() }
            }
            .padding(4)
        }
    }
}

#Preview {
    ContentView()
        .environment(ClickerModel())
}
