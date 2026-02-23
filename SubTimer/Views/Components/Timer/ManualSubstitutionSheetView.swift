//
//  ManualSubstitutionSheetView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the manual substitution sheet where user selects which bench player to sub in
struct ManualSubstitutionSheetView: View {
    // MARK: - Properties

    let playerToSubOut: Player
    let benchPlayers: [Player]
    let onSubstitute: (Player) -> Void
    let onCancel: () -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                ForEach(benchPlayers) { benchPlayer in
                    Button {
                        onSubstitute(benchPlayer)
                    } label: {
                        HStack {
                            Text(benchPlayer.name)
                            Spacer()
                            Text("Total: \(TimeFormatter.format(benchPlayer.totalPlayTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Player to Sub In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Multiple Players") {
    ManualSubstitutionSheetView(
        playerToSubOut: Player(name: "Alice", status: .active, sortOrder: 0),
        benchPlayers: [
            Player(name: "Bob", status: .benched, sortOrder: 1),
            Player(name: "Charlie", status: .benched, sortOrder: 2),
            Player(name: "Diana", status: .benched, sortOrder: 3),
        ],
        onSubstitute: { player in print("Substituting in: \(player.name)") },
        onCancel: { print("Cancelled") }
    )
}

#Preview("With Single Player") {
    ManualSubstitutionSheetView(
        playerToSubOut: Player(name: "Alice", status: .active, sortOrder: 0),
        benchPlayers: [
            Player(name: "Bob", status: .benched, sortOrder: 1),
        ],
        onSubstitute: { player in print("Substituting in: \(player.name)") },
        onCancel: { print("Cancelled") }
    )
}

#Preview("With Play Time Data") {
    ManualSubstitutionSheetView(
        playerToSubOut: Player(name: "Alice", status: .active, sortOrder: 0),
        benchPlayers: [
            Player(name: "Bob", totalPlayTime: 300, status: .benched, sortOrder: 1),
            Player(name: "Charlie", totalPlayTime: 180, status: .benched, sortOrder: 2),
            Player(name: "Diana", totalPlayTime: 420, status: .benched, sortOrder: 3),
        ],
        onSubstitute: { player in print("Substituting in: \(player.name)") },
        onCancel: { print("Cancelled") }
    )
}

#Preview("Empty Bench (Edge Case)") {
    ManualSubstitutionSheetView(
        playerToSubOut: Player(name: "Alice", status: .active, sortOrder: 0),
        benchPlayers: [],
        onSubstitute: { player in print("Substituting in: \(player.name)") },
        onCancel: { print("Cancelled") }
    )
}
