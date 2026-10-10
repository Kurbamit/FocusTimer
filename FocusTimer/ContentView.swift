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
        ZStack {
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
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                TimerControlsView(viewModel: viewModel, stats: stats, onShowStats: showStats)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
    }

    private func showStats() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isShowingStats = true
        }
    }

    private func showTimer() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isShowingStats = false
        }
    }
}

#Preview {
    let settings = AppSettings()
    let stats = FocusStatsStore()
    ContentView(viewModel: TimerViewModel(settings: settings, stats: stats), stats: stats)
}
