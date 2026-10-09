//
//  ContentView.swift
//  FocusTimer
//
//  Created by Dominykas Cernovas on 09/10/2026.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }

            Text(viewModel.phase.label)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(viewModel.timeRemainingText)
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button(viewModel.isRunning ? "Pause" : "Start") {
                    viewModel.toggleStartPause()
                }
                .keyboardShortcut(.defaultAction)

                Button("Reset") {
                    viewModel.reset()
                }
            }

            Text(viewModel.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(20)
        .frame(width: 220)
    }
}

#Preview {
    ContentView(viewModel: TimerViewModel(settings: AppSettings()))
}
