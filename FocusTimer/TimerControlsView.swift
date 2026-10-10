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

    private var phase: SessionPhase { viewModel.phase }

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

            Label(phase.label, systemImage: phase.symbolName)
                .font(.headline)
                .foregroundStyle(phase.tintColor)
                .contentTransition(.symbolEffect(.replace))
                .animation(.easeInOut, value: phase)

            Text(viewModel.timeRemainingText)
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: viewModel.timeRemainingText)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(phase.tintColor)
                .animation(.linear(duration: 1), value: viewModel.progress)

            HStack(spacing: 12) {
                Button {
                    viewModel.toggleStartPause()
                } label: {
                    Label(viewModel.isRunning ? "Pause" : "Start", systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(phase.tintColor)

                Button {
                    viewModel.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    KeyCapView(symbol: "⌃")
                    KeyCapView(symbol: "⌥")
                    KeyCapView(symbol: "Space")
                }
                Text("start/pause anywhere")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Today: \(FocusStatsStore.formatted(minutes: stats.todayMinutes)) · \(stats.todaySessionCount) session\(stats.todaySessionCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit FocusTimer", action: quit)
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 220)
        .animation(.easeInOut, value: phase)
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
