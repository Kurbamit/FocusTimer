//
//  TimerControlsView.swift
//  FocusTimer
//

import AppKit
import SwiftUI

struct TimerControlsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var stats: FocusStatsStore
    @Environment(\.openSettings) private var openSettings
    let onShowStats: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onShowStats) {
                    Image(systemName: "chart.bar")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show Stats")

                Spacer()

                Button(action: openSettingsWindow) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
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

            Text("⌃⌥Space to start/pause anywhere")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text("Today: \(FocusStatsStore.formatted(minutes: stats.todayMinutes)) · \(stats.todaySessionCount) session\(stats.todaySessionCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit", action: quit)
        }
        .padding(20)
        .frame(width: 220)
    }

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        openSettings()
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    let settings = AppSettings()
    let stats = FocusStatsStore()
    TimerControlsView(viewModel: TimerViewModel(settings: settings, stats: stats), stats: stats, onShowStats: {})
}
