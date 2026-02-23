//
//  SessionRowView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying a single session row in history
struct SessionRowView: View {
    // MARK: - Properties

    let session: Session

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startDate, format: .dateTime.month().day().year().hour().minute())
                .font(.headline)

            HStack {
                Label("\(session.formattedDuration)", systemImage: "clock")
                Label("\(session.substitutionCount) subs", systemImage: "arrow.left.arrow.right")
                Label("\(session.playerNames.count) players", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Recent Session") {
    List {
        SessionRowView(
            session: Session(
                preferredPlayTimeSeconds: 180,
                activePlayersCount: 4,
                playerNames: ["Alice", "Bob", "Charlie", "Diana"]
            )
        )
    }
}

#Preview("Long Session") {
    let session = Session(
        preferredPlayTimeSeconds: 300,
        activePlayersCount: 5,
        playerNames: ["Alice", "Bob", "Charlie", "Diana", "Eve"]
    )
    session.duration = 3600 // 1 hour
    session.substitutionCount = 12

    return List {
        SessionRowView(session: session)
    }
}

#Preview("Short Session") {
    let session = Session(
        preferredPlayTimeSeconds: 60,
        activePlayersCount: 3,
        playerNames: ["Alice", "Bob", "Charlie"]
    )
    session.duration = 300 // 5 minutes
    session.substitutionCount = 2

    return List {
        SessionRowView(session: session)
    }
}

#Preview("Many Players") {
    let session = Session(
        preferredPlayTimeSeconds: 180,
        activePlayersCount: 6,
        playerNames: ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]
    )
    session.duration = 1800 // 30 minutes
    session.substitutionCount = 8

    return List {
        SessionRowView(session: session)
    }
}

#Preview("Multiple Sessions") {
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

    return List {
        SessionRowView(session: session1)
        SessionRowView(session: session2)
        SessionRowView(session: session3)
    }
}
