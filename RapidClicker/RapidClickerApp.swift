//
//  RapidClickerApp.swift
//  RapidClicker
//
//  SwiftUI entry point. Provides both a main settings window and a menu-bar
//  item, sharing one `ClickerModel`.
//

import SwiftUI

@main
struct RapidClickerApp: App {
    @State private var model = ClickerModel()

    var body: some Scene {
        Window("RapidClicker", id: "main") {
            ContentView()
                .environment(model)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            // Replace the default "New" item; this app has no documents.
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarView()
                .environment(model)
        } label: {
            Image(systemName: model.isRunning ? "cursorarrow.click.2" : "cursorarrow.click")
        }
        .menuBarExtraStyle(.window)
    }
}
