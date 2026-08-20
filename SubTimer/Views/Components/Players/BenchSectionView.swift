//
//  BenchSectionView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying the bench players section
struct BenchSectionView: View {
    // MARK: - Properties

    let players: [Player]
    let activePlayersCount: Int
    let maxActiveCount: Int
    let totalPlayTime: (Player) -> TimeInterval
    let onPlayerTap: (Player) -> Void
    let onActivatePlayer: (Player) -> Void
    let onReorder: (([Player]) -> Void)?

    // MARK: - Computed Properties

    private var canActivate: Bool {
        activePlayersCount < maxActiveCount
    }

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

    // MARK: - Helper Methods

    private func movePlayer(from source: IndexSet, to destination: Int) {
        var reorderedPlayers = players
        reorderedPlayers.move(fromOffsets: source, toOffset: destination)
        onReorder?(reorderedPlayers)
    }

    // MARK: - Helper Views

    private var headerView: some View {
        HStack {
            Label("Bench", systemImage: "person.2")
                .font(.title3)
                .bold()
            Spacer()
            Text("\(players.count)")
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
        BenchPlayerRowView(
            player: player,
            totalPlayTime: totalPlayTime(player),
            isNextUp: index == 0,
            canActivate: canActivate,
            onTap: { onPlayerTap(player) },
            onActivate: { onActivatePlayer(player) }
        )
    }

    private func rowBackground(index: Int) -> some View {
        index == 0
            ? RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.1))
            : RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground))
    }

    private var emptyStateView: some View {
        Text("No players on bench")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview("With Bench Players") {
    let totals: [String: TimeInterval] = ["John Doe": 180, "Jane Smith": 240, "Mike Johnson": 120]
    BenchSectionView(
        players: [
            Player(name: "John Doe", status: .benched),
            Player(name: "Jane Smith", status: .benched),
            Player(name: "Mike Johnson", status: .benched)
        ],
        activePlayersCount: 4,
        maxActiveCount: 4,
        totalPlayTime: { totals[$0.name] ?? 0 },
        onPlayerTap: { player in print("Tapped: \(player.name)") },
        onActivatePlayer: { player in print("Activate: \(player.name)") },
        onReorder: { players in print("Reordered: \(players.map { $0.name })") }
    )
    .padding()
}

#Preview("Empty Bench") {
    BenchSectionView(
        players: [],
        activePlayersCount: 4,
        maxActiveCount: 4,
        totalPlayTime: { _ in 0 },
        onPlayerTap: { _ in },
        onActivatePlayer: { _ in },
        onReorder: nil
    )
    .padding()
}

#Preview("Can Activate") {
    let totals: [String: TimeInterval] = ["John Doe": 180, "Jane Smith": 240]
    BenchSectionView(
        players: [
            Player(name: "John Doe", status: .benched),
            Player(name: "Jane Smith", status: .benched)
        ],
        activePlayersCount: 2,
        maxActiveCount: 4,
        totalPlayTime: { totals[$0.name] ?? 0 },
        onPlayerTap: { _ in },
        onActivatePlayer: { _ in },
        onReorder: { _ in print("Reordered") }
    )
    .padding()
}

#Preview("Cannot Activate") {
    let totals: [String: TimeInterval] = ["John Doe": 180, "Jane Smith": 240]
    BenchSectionView(
        players: [
            Player(name: "John Doe", status: .benched),
            Player(name: "Jane Smith", status: .benched)
        ],
        activePlayersCount: 4,
        maxActiveCount: 4,
        totalPlayTime: { totals[$0.name] ?? 0 },
        onPlayerTap: { _ in },
        onActivatePlayer: { _ in },
        onReorder: nil
    )
    .padding()
}

#Preview("Single Bench Player") {
    BenchSectionView(
        players: [
            Player(name: "Solo Benched", status: .benched)
        ],
        activePlayersCount: 3,
        maxActiveCount: 4,
        totalPlayTime: { _ in 60 },
        onPlayerTap: { _ in },
        onActivatePlayer: { _ in },
        onReorder: nil
    )
    .padding()
}
