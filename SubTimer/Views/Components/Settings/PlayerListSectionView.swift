//
//  PlayerListSectionView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the player management section in settings
struct PlayerListSectionView: View {
    // MARK: - Properties

    let players: [Player]
    let onEdit: (Player) -> Void
    let onDelete: (IndexSet) -> Void
    let onMove: (IndexSet, Int) -> Void
    let onAdd: () -> Void

    // MARK: - Body

    var body: some View {
        Section {
            ForEach(players) { player in
                SettingsPlayerRowView(
                    player: player,
                    onEdit: { onEdit(player) }
                )
            }
            .onDelete(perform: onDelete)
            .onMove(perform: onMove)

            Button {
                onAdd()
            } label: {
                Label("Add Player", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Players")
        } footer: {
            Text("\(players.count) player(s) in roster")
        }
    }
}

// MARK: - Preview

#Preview("With Players") {
    Form {
        PlayerListSectionView(
            players: [
                Player(name: "Alice", status: .active, sortOrder: 0),
                Player(name: "Bob", status: .benched, sortOrder: 1),
                Player(name: "Charlie", status: .temporarilyOut, sortOrder: 2),
                Player(name: "Diana", status: .benched, sortOrder: 3),
            ],
            onEdit: { player in print("Edit: \(player.name)") },
            onDelete: { indices in print("Delete: \(indices)") },
            onMove: { source, dest in print("Move from \(source) to \(dest)") },
            onAdd: { print("Add player") }
        )
    }
}

#Preview("Empty List") {
    Form {
        PlayerListSectionView(
            players: [],
            onEdit: { _ in print("Edit") },
            onDelete: { _ in print("Delete") },
            onMove: { _, _ in print("Move") },
            onAdd: { print("Add player") }
        )
    }
}

#Preview("Single Player") {
    Form {
        PlayerListSectionView(
            players: [
                Player(name: "Alice", status: .active, sortOrder: 0),
            ],
            onEdit: { player in print("Edit: \(player.name)") },
            onDelete: { indices in print("Delete: \(indices)") },
            onMove: { source, dest in print("Move from \(source) to \(dest)") },
            onAdd: { print("Add player") }
        )
    }
}

#Preview("Many Players") {
    Form {
        PlayerListSectionView(
            players: [
                Player(name: "Alice", status: .active, sortOrder: 0),
                Player(name: "Bob", status: .benched, sortOrder: 1),
                Player(name: "Charlie", status: .active, sortOrder: 2),
                Player(name: "Diana", status: .benched, sortOrder: 3),
                Player(name: "Eve", status: .benched, sortOrder: 4),
                Player(name: "Frank", status: .temporarilyOut, sortOrder: 5),
                Player(name: "Grace", status: .benched, sortOrder: 6),
            ],
            onEdit: { player in print("Edit: \(player.name)") },
            onDelete: { indices in print("Delete: \(indices)") },
            onMove: { source, dest in print("Move from \(source) to \(dest)") },
            onAdd: { print("Add player") }
        )
    }
}
