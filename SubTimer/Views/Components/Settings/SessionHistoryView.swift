//
//  SessionHistoryView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the session history list view
struct SessionHistoryView: View {
    // MARK: - Properties

    let sessions: [Session]
    let onDelete: (IndexSet) -> Void

    // MARK: - Body

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Start a session from the Timer tab to see history here.")
                )
            } else {
                ForEach(sessions) { session in
                    SessionRowView(session: session)
                }
                .onDelete(perform: onDelete)
            }
        }
        .navigationTitle("Session History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Empty History") {
    NavigationStack {
        SessionHistoryView(
            sessions: [],
            onDelete: { indices in print("Delete: \(indices)") }
        )
    }
}

#Preview("With Sessions") {
    let session1 = Session(
        preferredPlayTimeSeconds: 180,
        activePlayersCount: 4,
        playerNames: ["Alice", "Bob", "Charlie", "Diana"]
    )
    session1.duration = 1200
    session1.substitutionCount = 5

    let session2 = Session(
        preferredPlayTimeSeconds: 300,
        activePlayersCount: 5,
        playerNames: ["Alice", "Bob", "Charlie", "Diana", "Eve"]
    )
    session2.duration = 2400
    session2.substitutionCount = 8

    let session3 = Session(
        preferredPlayTimeSeconds: 120,
        activePlayersCount: 3,
        playerNames: ["Alice", "Bob", "Charlie"]
    )
    session3.duration = 600
    session3.substitutionCount = 3

    return NavigationStack {
        SessionHistoryView(
            sessions: [session1, session2, session3],
            onDelete: { indices in print("Delete: \(indices)") }
        )
    }
}

#Preview("Single Session") {
    let session = Session(
        preferredPlayTimeSeconds: 180,
        activePlayersCount: 4,
        playerNames: ["Alice", "Bob", "Charlie", "Diana"]
    )
    session.duration = 900
    session.substitutionCount = 4

    return NavigationStack {
        SessionHistoryView(
            sessions: [session],
            onDelete: { indices in print("Delete: \(indices)") }
        )
    }
}

#Preview("Many Sessions") {
    var sessions: [Session] = []

    for sessionNumber in 1 ... 10 {
        let session = Session(
            preferredPlayTimeSeconds: 180,
            activePlayersCount: 4,
            playerNames: ["Player 1", "Player 2", "Player 3", "Player 4"]
        )
        session.duration = TimeInterval(600 * sessionNumber)
        session.substitutionCount = sessionNumber * 2
        sessions.append(session)
    }

    return NavigationStack {
        SessionHistoryView(
            sessions: sessions,
            onDelete: { indices in print("Delete: \(indices)") }
        )
    }
}
