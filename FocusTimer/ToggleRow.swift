//
//  ToggleRow.swift
//  FocusTimer
//

import SwiftUI

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
    }
}

#Preview {
    ToggleRow(title: "Play sound", isOn: .constant(true))
        .padding()
        .frame(width: 320)
}
