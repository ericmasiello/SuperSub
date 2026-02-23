//
//  PreferredTimePickerView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the preferred play time picker
struct PreferredTimePickerView: View {
    // MARK: - Properties

    let preferredTimeSeconds: Int
    let onChange: (Int) -> Void

    // MARK: - Body

    var body: some View {
        Picker(
            "Preferred Play Time",
            selection: Binding(
                get: { preferredTimeSeconds },
                set: { newValue in onChange(newValue) }
            )
        ) {
            Text("0:30").tag(30)
            Text("1:00").tag(60)
            Text("1:30").tag(90)
            Text("2:00").tag(120)
            Text("2:30").tag(150)
            Text("3:00").tag(180)
            Text("3:30").tag(210)
            Text("4:00").tag(240)
            Text("4:30").tag(270)
            Text("5:00").tag(300)
            Text("7:30").tag(450)
            Text("10:00").tag(600)
            Text("15:00").tag(900)
            Text("20:00").tag(1200)
            Text("30:00").tag(1800)
        }
    }
}

// MARK: - Preview

#Preview("30 Seconds") {
    Form {
        PreferredTimePickerView(
            preferredTimeSeconds: 30,
            onChange: { newValue in print("Changed to: \(newValue)") }
        )
    }
}

#Preview("2 Minutes") {
    Form {
        PreferredTimePickerView(
            preferredTimeSeconds: 120,
            onChange: { newValue in print("Changed to: \(newValue)") }
        )
    }
}

#Preview("5 Minutes") {
    Form {
        PreferredTimePickerView(
            preferredTimeSeconds: 300,
            onChange: { newValue in print("Changed to: \(newValue)") }
        )
    }
}

#Preview("15 Minutes") {
    Form {
        PreferredTimePickerView(
            preferredTimeSeconds: 900,
            onChange: { newValue in print("Changed to: \(newValue)") }
        )
    }
}

#Preview("30 Minutes") {
    Form {
        PreferredTimePickerView(
            preferredTimeSeconds: 1800,
            onChange: { newValue in print("Changed to: \(newValue)") }
        )
    }
}
