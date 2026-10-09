//
//  FocusTimerApp.swift
//  FocusTimer
//
//  Created by Dominykas Cernovas on 09/10/2026.
//

import SwiftUI

@main
struct FocusTimerApp: App {
    @StateObject private var viewModel = TimerViewModel()

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
    }
}
