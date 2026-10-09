//
//  StepperRow.swift
//  FocusTimer
//

import SwiftUI

struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var unit: String?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(unit.map { "\(value) \($0)" } ?? "\(value)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Stepper(title, value: $value, in: range)
                .labelsHidden()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

#Preview {
    StepperRow(title: "Focus", value: .constant(25), range: 1...180, unit: "min")
        .padding()
        .frame(width: 320)
}
