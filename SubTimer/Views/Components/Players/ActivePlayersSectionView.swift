//
//  ActivePlayersSectionView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying the active players section
struct ActivePlayersSectionView: View {
    // MARK: - Properties

    let players: [Player]
    let maxActiveCount: Int
    let onPlayerTap: (Player) -> Void

    // MARK: - Computed Properties

    private var longestPlayingPlayer: Player? {
        players.max(by: { $0.currentPlayDuration < $1.currentPlayDuration })
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Active Players", systemImage: "figure.run")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("\(players.count)/\(maxActiveCount)")
                    .foregroundStyle(.secondary)
            }

            // Content
            if players.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(players) { player in
                        ActivePlayerRowView(
                            player: player,
                            isNextToSubOut: isNextToSubOut(player),
                            onTap: { onPlayerTap(player) }
                        )
                        .padding(.horizontal, 4)
                        .background(
                            isNextToSubOut(player)
                                ? RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1))
                                : RoundedRectangle(cornerRadius: 12).fill(
                                    Color(uiColor: .secondarySystemBackground)
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private var emptyStateView: some View {
        Text("No active players. Tap a player on the bench to activate.")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
    }

    // MARK: - Helper Methods

    private func isNextToSubOut(_ player: Player) -> Bool {
        guard players.count > 1 else { return false }
        return longestPlayingPlayer?.id == player.id
    }
}

// MARK: - Preview

#Preview("With Active Players") {
    ActivePlayersSectionView(
        players: [
            Player(name: "John Doe", currentPlayDuration: 120, status: .active),
            Player(name: "Jane Smith", currentPlayDuration: 180, status: .active),
            Player(name: "Mike Johnson", currentPlayDuration: 90, status: .active),
            Player(name: "Sarah Williams", currentPlayDuration: 150, status: .active),
        ],
        maxActiveCount: 4,
        onPlayerTap: { player in print("Tapped: \(player.name)") }
    )
    .padding()
}

#Preview("Empty State") {
    ActivePlayersSectionView(
        players: [],
        maxActiveCount: 4,
        onPlayerTap: { _ in }
    )
    .padding()
}

#Preview("Single Player") {
    ActivePlayersSectionView(
        players: [
            Player(name: "Solo Player", currentPlayDuration: 200, status: .active),
        ],
        maxActiveCount: 4,
        onPlayerTap: { _ in }
    )
    .padding()
}

#Preview("At Capacity") {
    ActivePlayersSectionView(
        players: [
            Player(name: "Player 1", currentPlayDuration: 120, status: .active),
            Player(name: "Player 2", currentPlayDuration: 180, status: .active),
            Player(name: "Player 3", currentPlayDuration: 90, status: .active),
        ],
        maxActiveCount: 3,
        onPlayerTap: { _ in }
    )
    .padding()
}

#Preview("Under Capacity") {
    ActivePlayersSectionView(
        players: [
            Player(name: "Player 1", currentPlayDuration: 120, status: .active),
            Player(name: "Player 2", currentPlayDuration: 180, status: .active),
        ],
        maxActiveCount: 5,
        onPlayerTap: { _ in }
    )
    .padding()
}
