//
//  MenuBarView.swift
//  RapidClicker
//
//  Compact controls shown from the menu-bar item: quick start/stop, a glance
//  at the current settings, and shortcuts to the window and quitting.
//

import SwiftUI

struct MenuBarView: View {
    @Environment(ClickerModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "cursorarrow.click.2").foregroundStyle(.tint)
                Text("RapidClicker").font(.headline)
                Spacer()
                Circle()
                    .fill(model.isRunning ? .green : .secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
            }

            Divider()

            Button {
                model.toggle()
            } label: {
                Label(model.isRunning ? "Stop Clicking" : "Start Clicking",
                      systemImage: model.isRunning ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
            .tint(model.isRunning ? .red : .green)
            .disabled(!model.accessibilityTrusted)
            .help(model.accessibilityTrusted
                  ? "Start or stop clicking."
                  : "Grant Accessibility permission first — clicks can't be sent without it.")

            VStack(spacing: 4) {
                row("Rate", "\(model.roundedRate)/sec")
                row("Hotkey", model.shortcut.description)
                if model.autoStopEnabled {
                    row("Auto-stop", model.autoStopDescription)
                }
                if model.isRunning, let remaining = model.secondsRemaining {
                    row("Time left", "\(remaining)s")
                }
                if model.clicksSent > 0 {
                    row("Sent", "\(model.clicksSent)")
                }
            }
            .font(.callout)

            if !model.accessibilityTrusted {
                Label("Accessibility permission needed", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Divider()

            Button("Open Window…") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Quit RapidClicker") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 240)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).monospacedDigit().foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MenuBarView()
        .environment(ClickerModel())
}
