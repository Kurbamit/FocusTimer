//
//  StatRow.swift
//  FocusTimer
//

import SwiftUI

struct StatRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

#Preview {
    StatRow(icon: "calendar", title: "Today", value: "1h 15m · 3 sessions")
        .padding()
        .frame(width: 320)
}
