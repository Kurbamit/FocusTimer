//
//  StatRow.swift
//  FocusTimer
//

import SwiftUI

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
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
    StatRow(title: "Today", value: "1h 15m · 3 sessions")
        .padding()
        .frame(width: 320)
}
