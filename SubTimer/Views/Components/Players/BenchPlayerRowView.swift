//
//  BenchPlayerRowView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying a single benched player row
struct BenchPlayerRowView: View {
    // MARK: - Properties

    let player: Player
    let totalPlayTime: TimeInterval
    let isNextUp: Bool
    let canActivate: Bool
    let onTap: () -> Void
    let onActivate: () -> Void

    // MARK: - Body

    var body: some View {
        rowContent
            .accessibilityIdentifier("player.row.bench")
    }

    // MARK: - Row Content

    private var rowContent: some View {
        HStack {
            playerInfo
            Spacer()
            moreButton
            if canActivate {
                activateButton
            }
        }
        .padding()
        .cornerRadius(8)
    }

    private var playerInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(player.name)
                    .font(.headline)
                if isNextUp && !canActivate {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                        .accessibilityLabel("Next Up")
                }
            }
            Text("Total: \(TimeFormatter.format(totalPlayTime))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var moreButton: some View {
        Button(action: onTap) {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundStyle(.appPurple)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More")
    }

    private var activateButton: some View {
        Button(action: onActivate) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Activate")
    }
}

// MARK: - Preview

#Preview("Normal Bench Player") {
    BenchPlayerRowView(
        player: Player(name: "John Doe"),
        totalPlayTime: 180,
        isNextUp: false,
        canActivate: false,
        onTap: { print("Player tapped") },
        onActivate: { print("Activate tapped") }
    )
    .padding()
}

#Preview("Next Up Player") {
    BenchPlayerRowView(
        player: Player(name: "Jane Smith"),
        totalPlayTime: 240,
        isNextUp: true,
        canActivate: false,
        onTap: { print("Player tapped") },
        onActivate: { print("Activate tapped") }
    )
    .padding()
}

#Preview("Can Activate") {
    BenchPlayerRowView(
        player: Player(name: "Mike Johnson"),
        totalPlayTime: 120,
        isNextUp: false,
        canActivate: true,
        onTap: { print("Player tapped") },
        onActivate: { print("Activate tapped") }
    )
    .padding()
}

#Preview("Next Up & Can Activate") {
    BenchPlayerRowView(
        player: Player(name: "Sarah Williams"),
        totalPlayTime: 60,
        isNextUp: true,
        canActivate: true,
        onTap: { print("Player tapped") },
        onActivate: { print("Activate tapped") }
    )
    .padding()
}

#Preview("Zero Play Time") {
    BenchPlayerRowView(
        player: Player(name: "New Player"),
        totalPlayTime: 0,
        isNextUp: false,
        canActivate: true,
        onTap: { print("Player tapped") },
        onActivate: { print("Activate tapped") }
    )
    .padding()
}
