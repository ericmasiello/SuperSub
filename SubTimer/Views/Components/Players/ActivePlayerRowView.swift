//
//  ActivePlayerRowView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying a single active player row
struct ActivePlayerRowView: View {
    // MARK: - Properties

    let player: Player
    let isNextToSubOut: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.name)
                        .font(.headline)
                    if isNextToSubOut {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.appOrange)
                            .font(.caption)
                    }
                }
                Text(TimeFormatter.format(player.currentPlayDuration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in onTap() }
        )
        .accessibilityIdentifier("player.row.active")
    }
}

// MARK: - Preview

#Preview("Normal Active Player") {
    ActivePlayerRowView(
        player: Player(name: "John Doe", currentPlayDuration: 120),
        isNextToSubOut: false,
        onTap: { print("Player tapped") }
    )
    .padding()
}

#Preview("Next to Sub Out") {
    ActivePlayerRowView(
        player: Player(name: "Jane Smith", currentPlayDuration: 180),
        isNextToSubOut: true,
        onTap: { print("Player tapped") }
    )
    .padding()
}

#Preview("Long Play Time") {
    ActivePlayerRowView(
        player: Player(name: "Mike Johnson", currentPlayDuration: 450),
        isNextToSubOut: true,
        onTap: { print("Player tapped") }
    )
    .padding()
}

#Preview("Zero Time") {
    ActivePlayerRowView(
        player: Player(name: "Sarah Williams", currentPlayDuration: 0),
        isNextToSubOut: false,
        onTap: { print("Player tapped") }
    )
    .padding()
}
