//
//  PlayerActionsSheetView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the player actions sheet showing available actions based on player status
struct PlayerActionsSheetView: View {
    // MARK: - Properties

    let player: Player
    let canActivate: Bool
    let onSubstituteOut: () -> Void
    let onActivatePlayer: () -> Void
    let onMarkTemporarilyOut: () -> Void
    let onReturnToBench: () -> Void
    let onClose: () -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Actions section based on player status
                Section {
                    if player.status == .active {
                        activePlayerActions
                    } else if player.status == .benched {
                        benchedPlayerActions
                    } else if player.status == .temporarilyOut {
                        temporarilyOutPlayerActions
                    }
                }

                // Stats section (always shown)
                statsSection
            }
            .navigationTitle(player.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onClose()
                    }
                }
            }
        }
    }

    // MARK: - Action Views

    @ViewBuilder
    private var activePlayerActions: some View {
        Button {
            onSubstituteOut()
        } label: {
            Label("Substitute Out", systemImage: "arrow.down.circle")
        }

        Button(role: .destructive) {
            onMarkTemporarilyOut()
        } label: {
            Label("Mark Temporarily Out", systemImage: "exclamationmark.triangle")
        }
    }

    @ViewBuilder
    private var benchedPlayerActions: some View {
        if canActivate {
            Button {
                onActivatePlayer()
            } label: {
                Label("Activate Player", systemImage: "arrow.up.circle")
            }
        }

        Button(role: .destructive) {
            onMarkTemporarilyOut()
        } label: {
            Label("Mark Temporarily Out", systemImage: "exclamationmark.triangle")
        }
    }

    private var temporarilyOutPlayerActions: some View {
        Button {
            onReturnToBench()
        } label: {
            Label("Return to Bench", systemImage: "arrow.counterclockwise")
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        Section {
            HStack {
                Text("Current Play Duration")
                Spacer()
                Text(TimeFormatter.format(player.currentPlayDuration))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Total Play Time")
                Spacer()
                Text(TimeFormatter.format(player.totalPlayTime))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Active Player") {
    PlayerActionsSheetView(
        player: Player(
            name: "Alice",
            currentPlayDuration: 120, // 2 minutes
            totalPlayTime: 600, // 10 minutes
            status: .active,
            sortOrder: 0
        ),
        canActivate: true,
        onSubstituteOut: { print("Substitute out") },
        onActivatePlayer: { print("Activate") },
        onMarkTemporarilyOut: { print("Mark temporarily out") },
        onReturnToBench: { print("Return to bench") },
        onClose: { print("Close") }
    )
}

#Preview("Benched Player - Can Activate") {
    PlayerActionsSheetView(
        player: Player(
            name: "Bob",
            currentPlayDuration: 0,
            totalPlayTime: 450, // 7.5 minutes
            status: .benched,
            sortOrder: 1
        ),
        canActivate: true,
        onSubstituteOut: { print("Substitute out") },
        onActivatePlayer: { print("Activate") },
        onMarkTemporarilyOut: { print("Mark temporarily out") },
        onReturnToBench: { print("Return to bench") },
        onClose: { print("Close") }
    )
}

#Preview("Benched Player - Cannot Activate") {
    PlayerActionsSheetView(
        player: Player(
            name: "Charlie",
            currentPlayDuration: 0,
            totalPlayTime: 300, // 5 minutes
            status: .benched,
            sortOrder: 2
        ),
        canActivate: false,
        onSubstituteOut: { print("Substitute out") },
        onActivatePlayer: { print("Activate") },
        onMarkTemporarilyOut: { print("Mark temporarily out") },
        onReturnToBench: { print("Return to bench") },
        onClose: { print("Close") }
    )
}

#Preview("Temporarily Out Player") {
    PlayerActionsSheetView(
        player: Player(
            name: "Diana",
            currentPlayDuration: 0,
            totalPlayTime: 800, // 13.3 minutes
            status: .temporarilyOut,
            sortOrder: 3
        ),
        canActivate: false,
        onSubstituteOut: { print("Substitute out") },
        onActivatePlayer: { print("Activate") },
        onMarkTemporarilyOut: { print("Mark temporarily out") },
        onReturnToBench: { print("Return to bench") },
        onClose: { print("Close") }
    )
}

#Preview("Player with No Play Time") {
    PlayerActionsSheetView(
        player: Player(
            name: "Eve",
            currentPlayDuration: 0,
            totalPlayTime: 0,
            status: .benched,
            sortOrder: 4
        ),
        canActivate: true,
        onSubstituteOut: { print("Substitute out") },
        onActivatePlayer: { print("Activate") },
        onMarkTemporarilyOut: { print("Mark temporarily out") },
        onReturnToBench: { print("Return to bench") },
        onClose: { print("Close") }
    )
}
