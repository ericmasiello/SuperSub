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
            // Header
            HStack {
                Label("Bench", systemImage: "person.2")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("\(players.count)")
                    .foregroundStyle(.secondary)
            }

            // Content
            if players.isEmpty {
                emptyStateView
            } else if onReorder != nil {
                List {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        BenchPlayerRowView(
                            player: player,
                            isNextUp: index == 0,
                            canActivate: canActivate,
                            onTap: { onPlayerTap(player) },
                            onActivate: { onActivatePlayer(player) }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(
                            index == 0
                                ? RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.1))
                                : RoundedRectangle(cornerRadius: 12).fill(
                                    Color(uiColor: .secondarySystemBackground)
                                )
                        )
                    }
                    .onMove(perform: movePlayer)
                }
                .listStyle(.plain)
                .listRowSpacing(8)
                .environment(\.editMode, .constant(.active))
                .frame(height: CGFloat(players.count) * 80)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        BenchPlayerRowView(
                            player: player,
                            isNextUp: index == 0,
                            canActivate: canActivate,
                            onTap: { onPlayerTap(player) },
                            onActivate: { onActivatePlayer(player) }
                        )
                        .padding(.horizontal, 4)
                        .background(
                            index == 0
                                ? RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.1))
                                : RoundedRectangle(cornerRadius: 12).fill(
                                    Color(uiColor: .secondarySystemBackground)
                                )
                        )
                    }
                }
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
    BenchSectionView(
        players: [
            Player(name: "John Doe", totalPlayTime: 180, status: .benched),
            Player(name: "Jane Smith", totalPlayTime: 240, status: .benched),
            Player(name: "Mike Johnson", totalPlayTime: 120, status: .benched),
        ],
        activePlayersCount: 4,
        maxActiveCount: 4,
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
        onPlayerTap: { _ in },
        onActivatePlayer: { _ in },
        onReorder: nil
    )
    .padding()
}

#Preview("Can Activate") {
    BenchSectionView(
        players: [
            Player(name: "John Doe", totalPlayTime: 180, status: .benched),
            Player(name: "Jane Smith", totalPlayTime: 240, status: .benched),
        ],
        activePlayersCount: 2,
        maxActiveCount: 4,
        onPlayerTap: { _ in },
        onActivatePlayer: { _ in },
        onReorder: { _ in print("Reordered") }
    )
    .padding()
}

#Preview("Cannot Activate") {
    BenchSectionView(
        players: [
            Player(name: "John Doe", totalPlayTime: 180, status: .benched),
            Player(name: "Jane Smith", totalPlayTime: 240, status: .benched),
        ],
        activePlayersCount: 4,
        maxActiveCount: 4,
        onPlayerTap: { _ in },
        onActivatePlayer: { _ in },
        onReorder: nil
    )
    .padding()
}

#Preview("Single Bench Player") {
    BenchSectionView(
        players: [
            Player(name: "Solo Benched", totalPlayTime: 60, status: .benched),
        ],
        activePlayersCount: 3,
        maxActiveCount: 4,
        onPlayerTap: { _ in },
        onActivatePlayer: { _ in },
        onReorder: nil
    )
    .padding()
}
