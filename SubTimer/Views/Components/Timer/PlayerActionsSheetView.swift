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
    let status: RotationBucket
    let currentPlayDuration: TimeInterval
    let totalPlayTime: TimeInterval
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
                    if status == .active {
                        activePlayerActions
                    } else if status == .benched {
                        benchedPlayerActions
                    } else if status == .temporarilyOut {
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
                Text(TimeFormatter.format(currentPlayDuration))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Total Play Time")
                Spacer()
                Text(TimeFormatter.format(totalPlayTime))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Active Player") {
    PlayerActionsSheetView(
        player: Player(name: "Alice", sortOrder: 0),
        status: .active,
        currentPlayDuration: 120, // 2 minutes
        totalPlayTime: 600, // 10 minutes
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
        player: Player(name: "Bob", sortOrder: 1),
        status: .benched,
        currentPlayDuration: 0,
        totalPlayTime: 450, // 7.5 minutes
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
        player: Player(name: "Charlie", sortOrder: 2),
        status: .benched,
        currentPlayDuration: 0,
        totalPlayTime: 300, // 5 minutes
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
        player: Player(name: "Diana", sortOrder: 3),
        status: .temporarilyOut,
        currentPlayDuration: 0,
        totalPlayTime: 800, // 13.3 minutes
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
        player: Player(name: "Eve", sortOrder: 4),
        status: .benched,
        currentPlayDuration: 0,
        totalPlayTime: 0,
        canActivate: true,
        onSubstituteOut: { print("Substitute out") },
        onActivatePlayer: { print("Activate") },
        onMarkTemporarilyOut: { print("Mark temporarily out") },
        onReturnToBench: { print("Return to bench") },
        onClose: { print("Close") }
    )
}
