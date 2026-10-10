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
    @StateObject private var stats: FocusStatsStore
    @StateObject private var viewModel: TimerViewModel

    init() {
        let settings = AppSettings()
        let stats = FocusStatsStore()
        _settings = StateObject(wrappedValue: settings)
        _stats = StateObject(wrappedValue: stats)
        _viewModel = StateObject(wrappedValue: TimerViewModel(settings: settings, stats: stats))
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel, stats: stats)
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
