//
//  ContentView.swift
//  FocusTimer
//
//  Created by Dominykas Cernovas on 09/10/2026.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var stats: FocusStatsStore
    @State private var isShowingStats = false

    var body: some View {
        if isShowingStats {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: showTimer) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                StatsView(stats: stats)
            }
            .padding(24)
            .frame(width: 360)
        } else {
            TimerControlsView(viewModel: viewModel, stats: stats, onShowStats: showStats)
        }
    }

    private func showStats() {
        isShowingStats = true
    }

    private func showTimer() {
        isShowingStats = false
    }
}

#Preview {
    let settings = AppSettings()
    let stats = FocusStatsStore()
    ContentView(viewModel: TimerViewModel(settings: settings, stats: stats), stats: stats)
}
