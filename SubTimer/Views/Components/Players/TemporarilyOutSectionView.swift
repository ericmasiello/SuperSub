//
//  TemporarilyOutSectionView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying the temporarily out players section
struct TemporarilyOutSectionView: View {
    // MARK: - Properties

    let players: [Player]
    let totalPlayTime: (Player) -> TimeInterval
    let onReturnToBench: (Player) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Label("Temporarily Out", systemImage: "exclamationmark.triangle")
                .font(.title3)
                .bold()

            // Content

            LazyVStack(spacing: 8) {
                ForEach(players) { player in
                    TemporarilyOutPlayerRowView(
                        player: player,
                        totalPlayTime: totalPlayTime(player),
                        onReturnToBench: { onReturnToBench(player) }
                    )
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.1))
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Temporarily Out Players") {
    let totals: [String: TimeInterval] = ["John Doe": 300, "Jane Smith": 450, "Mike Johnson": 180]
    TemporarilyOutSectionView(
        players: [
            Player(name: "John Doe", status: .temporarilyOut),
            Player(name: "Jane Smith", status: .temporarilyOut),
            Player(name: "Mike Johnson", status: .temporarilyOut)
        ],
        totalPlayTime: { totals[$0.name] ?? 0 },
        onReturnToBench: { player in print("Return: \(player.name)") }
    )
    .padding()
}

#Preview("Single Player") {
    TemporarilyOutSectionView(
        players: [
            Player(name: "Solo Out", status: .temporarilyOut)
        ],
        totalPlayTime: { _ in 200 },
        onReturnToBench: { _ in }
    )
    .padding()
}

#Preview("Multiple Players") {
    let totals: [String: TimeInterval] = ["Player 1": 100, "Player 2": 500, "Player 3": 250, "Player 4": 75]
    TemporarilyOutSectionView(
        players: [
            Player(name: "Player 1", status: .temporarilyOut),
            Player(name: "Player 2", status: .temporarilyOut),
            Player(name: "Player 3", status: .temporarilyOut),
            Player(name: "Player 4", status: .temporarilyOut)
        ],
        totalPlayTime: { totals[$0.name] ?? 0 },
        onReturnToBench: { _ in }
    )
    .padding()
}

#Preview("Zero Play Time") {
    TemporarilyOutSectionView(
        players: [
            Player(name: "New Player Out", status: .temporarilyOut)
        ],
        totalPlayTime: { _ in 0 },
        onReturnToBench: { _ in }
    )
    .padding()
}
