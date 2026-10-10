//
//  StatsView.swift
//  FocusTimer
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var stats: FocusStatsStore

    var body: some View {
        SettingsSection(title: "Focus Time") {
            StatRow(icon: "sun.max", title: "Today", value: summary(minutes: stats.todayMinutes, sessions: stats.todaySessionCount))
            Divider().padding(.leading, 12)
            StatRow(icon: "calendar", title: "This Week", value: summary(minutes: stats.weekMinutes, sessions: stats.weekSessionCount))
            Divider().padding(.leading, 12)
            StatRow(icon: "infinity", title: "All Time", value: summary(minutes: stats.allTimeMinutes, sessions: stats.allTimeSessionCount))
        }
    }

    private func summary(minutes: Int, sessions: Int) -> String {
        "\(FocusStatsStore.formatted(minutes: minutes)) · \(sessions) session\(sessions == 1 ? "" : "s")"
    }
}

#Preview {
    StatsView(stats: FocusStatsStore())
        .padding(24)
        .frame(width: 360)
}
