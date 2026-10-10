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
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
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
