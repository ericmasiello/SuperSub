//
//  TemporarilyOutPlayerRowView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying a single temporarily out player row
struct TemporarilyOutPlayerRowView: View {
    // MARK: - Properties

    let player: Player
    let totalPlayTime: TimeInterval
    let onReturnToBench: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.headline)
                Text("Total: \(TimeFormatter.format(totalPlayTime))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onReturnToBench) {
                Text("Return to Bench")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appPurple)
                    .foregroundStyle(.white)
                    .cornerRadius(6)
            }
            // Every temporarily-out row's button otherwise shares the same
            // visual "Return to Bench" text, so with 2+ players out at
            // once, VoiceOver (and anything else driven by accessibility
            // label alone) can't tell whose button it's landed on.
            .accessibilityLabel("Return \(player.name) to Bench")
        }
        .padding()
        .accessibilityIdentifier("player.row.tempout")
    }
}

// MARK: - Preview

#Preview("Temporarily Out Player") {
    TemporarilyOutPlayerRowView(
        player: Player(name: "John Doe"),
        totalPlayTime: 300,
        onReturnToBench: { print("Return to bench tapped") }
    )
    .padding()
}

#Preview("High Play Time") {
    TemporarilyOutPlayerRowView(
        player: Player(name: "Jane Smith"),
        totalPlayTime: 600,
        onReturnToBench: { print("Return to bench tapped") }
    )
    .padding()
}

#Preview("Low Play Time") {
    TemporarilyOutPlayerRowView(
        player: Player(name: "Mike Johnson"),
        totalPlayTime: 30,
        onReturnToBench: { print("Return to bench tapped") }
    )
    .padding()
}

#Preview("Zero Play Time") {
    TemporarilyOutPlayerRowView(
        player: Player(name: "New Player"),
        totalPlayTime: 0,
        onReturnToBench: { print("Return to bench tapped") }
    )
    .padding()
}
