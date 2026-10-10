//
//  KeyCapView.swift
//  FocusTimer
//

import SwiftUI

/// Renders a single keyboard key as a small physical-looking cap, the way
/// macOS shortcut hints (Raycast, CleanShot, etc.) display key combos.
struct KeyCapView: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.quaternary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.25), lineWidth: 0.5)
            )
    }
}

#Preview {
    HStack(spacing: 4) {
        KeyCapView(symbol: "⌃")
        KeyCapView(symbol: "⌥")
        KeyCapView(symbol: "Space")
    }
    .padding()
}
