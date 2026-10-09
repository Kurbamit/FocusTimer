//
//  SettingsView.swift
//  FocusTimer
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection(title: "Durations") {
                StepperRow(title: "Focus", value: $settings.focusMinutes, range: 1...180, unit: "min")
                Divider().padding(.leading, 12)
                StepperRow(title: "Short Break", value: $settings.shortBreakMinutes, range: 1...180, unit: "min")
                Divider().padding(.leading, 12)
                StepperRow(title: "Long Break", value: $settings.longBreakMinutes, range: 1...180, unit: "min")
            }

            SettingsSection(title: "Cycle") {
                StepperRow(title: "Sessions before long break", value: $settings.sessionsBeforeLongBreak, range: 1...12, unit: "sessions")
            }

            SettingsSection(title: "Alerts") {
                ToggleRow(title: "Play sound", isOn: $settings.soundEnabled)
                Divider().padding(.leading, 12)
                ToggleRow(title: "Show notification", isOn: $settings.notificationsEnabled)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
