//
//  FocusTimerApp.swift
//  FocusTimer
//
//  Created by Dominykas Cernovas on 09/10/2026.
//

import SwiftUI

@main
struct FocusTimerApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var viewModel: TimerViewModel

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: TimerViewModel(settings: settings))
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            if let text = viewModel.menuBarText {
                Text(text)
                    .font(.system(.body, design: .monospaced))
            } else {
                Image(systemName: "timer")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings)
        }
    }
}
