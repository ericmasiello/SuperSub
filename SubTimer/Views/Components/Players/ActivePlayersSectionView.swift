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
    let onReorder: (([Player]) -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            if players.isEmpty {
                emptyStateView
            } else if onReorder != nil {
                reorderableListView
            } else {
                staticListView
            }
        }
    }

    // MARK: - Helper Views

    private var headerView: some View {
        HStack {
            Label("Active Players", systemImage: "figure.run")
                .font(.title3)
                .bold()
            Spacer()
            Text("\(players.count)/\(maxActiveCount)")
                .foregroundStyle(.secondary)
        }
    }

    private var reorderableListView: some View {
        List {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                playerRow(player: player, index: index)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(rowBackground(index: index))
            }
            .onMove(perform: movePlayer)
        }
        .listStyle(.plain)
        .listRowSpacing(8)
        .environment(\.editMode, .constant(.active))
        .frame(height: CGFloat(players.count) * 80)
    }

    private var staticListView: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                playerRow(player: player, index: index)
                    .padding(.horizontal, 4)
                    .background(rowBackground(index: index))
            }
        }
    }

    private func playerRow(player: Player, index: Int) -> some View {
        ActivePlayerRowView(
            player: player,
            isNextToSubOut: isNextToSubOut(index),
            onTap: { onPlayerTap(player) }
        )
    }

    private func rowBackground(index: Int) -> some View {
        isNextToSubOut(index)
            ? RoundedRectangle(cornerRadius: 12).fill(Color.appOrange.opacity(0.1))
            : RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground))
    }

    private var emptyStateView: some View {
        Text("No active players. Tap a player on the bench to activate.")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
    }

    // MARK: - Helper Methods

    private func isNextToSubOut(_ index: Int) -> Bool {
        guard players.count > 1 else { return false }
        return index == 0
    }

    private func movePlayer(from source: IndexSet, to destination: Int) {
        var reorderedPlayers = players
        reorderedPlayers.move(fromOffsets: source, toOffset: destination)
        onReorder?(reorderedPlayers)
    }
}

// MARK: - Preview

#Preview("With Active Players") {
    ActivePlayersSectionView(
        players: [
            Player(name: "John Doe", currentPlayDuration: 120, status: .active),
            Player(name: "Jane Smith", currentPlayDuration: 180, status: .active),
            Player(name: "Mike Johnson", currentPlayDuration: 90, status: .active),
            Player(name: "Sarah Williams", currentPlayDuration: 150, status: .active)
        ],
        maxActiveCount: 4,
        onPlayerTap: { player in print("Tapped: \(player.name)") },
        onReorder: { players in print("Reordered: \(players.map { $0.name })") }
    )
    .padding()
}

#Preview("Empty State") {
    ActivePlayersSectionView(
        players: [],
        maxActiveCount: 4,
        onPlayerTap: { _ in },
        onReorder: nil
    )
    .padding()
}

#Preview("Single Player") {
    ActivePlayersSectionView(
        players: [
            Player(name: "Solo Player", currentPlayDuration: 200, status: .active)
        ],
        maxActiveCount: 4,
        onPlayerTap: { _ in },
        onReorder: nil
    )
    .padding()
}

#Preview("At Capacity") {
    ActivePlayersSectionView(
        players: [
            Player(name: "Player 1", currentPlayDuration: 120, status: .active),
            Player(name: "Player 2", currentPlayDuration: 180, status: .active),
            Player(name: "Player 3", currentPlayDuration: 90, status: .active)
        ],
        maxActiveCount: 3,
        onPlayerTap: { _ in },
        onReorder: { _ in print("Reordered") }
    )
    .padding()
}

#Preview("Under Capacity") {
    ActivePlayersSectionView(
        players: [
            Player(name: "Player 1", currentPlayDuration: 120, status: .active),
            Player(name: "Player 2", currentPlayDuration: 180, status: .active)
        ],
        maxActiveCount: 5,
        onPlayerTap: { _ in },
        onReorder: nil
    )
    .padding()
}
