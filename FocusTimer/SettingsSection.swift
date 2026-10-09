//
//  SettingsSection.swift
//  FocusTimer
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .background(.quaternary, in: .rect(cornerRadius: 10))
        }
    }
}

#Preview {
    SettingsSection(title: "Alerts") {
        ToggleRow(title: "Play sound", isOn: .constant(true))
    }
    .padding()
    .frame(width: 320)
}
