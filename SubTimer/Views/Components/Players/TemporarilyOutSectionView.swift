//
//  TemporarilyOutSectionView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying the temporarily out players section
struct TemporarilyOutSectionView: View {
  // MARK: - Properties

  let players: [Player]
  let onReturnToBench: (Player) -> Void

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      Label("Temporarily Out", systemImage: "exclamationmark.triangle")
        .font(.title3)
        .bold()

      // Content

      LazyVStack(spacing: 8) {
        ForEach(players) { player in
          TemporarilyOutPlayerRowView(
            player: player,
            onReturnToBench: { onReturnToBench(player) }
          )
          .padding(.horizontal, 4)
          .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.1)))
        }
      }

    }
  }
}

// MARK: - Preview

#Preview("With Temporarily Out Players") {
  TemporarilyOutSectionView(
    players: [
      Player(name: "John Doe", totalPlayTime: 300, status: .temporarilyOut),
      Player(name: "Jane Smith", totalPlayTime: 450, status: .temporarilyOut),
      Player(name: "Mike Johnson", totalPlayTime: 180, status: .temporarilyOut),
    ],
    onReturnToBench: { player in print("Return: \(player.name)") }
  )
  .padding()
}

#Preview("Single Player") {
  TemporarilyOutSectionView(
    players: [
      Player(name: "Solo Out", totalPlayTime: 200, status: .temporarilyOut)
    ],
    onReturnToBench: { _ in }
  )
  .padding()
}

#Preview("Multiple Players") {
  TemporarilyOutSectionView(
    players: [
      Player(name: "Player 1", totalPlayTime: 100, status: .temporarilyOut),
      Player(name: "Player 2", totalPlayTime: 500, status: .temporarilyOut),
      Player(name: "Player 3", totalPlayTime: 250, status: .temporarilyOut),
      Player(name: "Player 4", totalPlayTime: 75, status: .temporarilyOut),
    ],
    onReturnToBench: { _ in }
  )
  .padding()
}

#Preview("Zero Play Time") {
  TemporarilyOutSectionView(
    players: [
      Player(name: "New Player Out", totalPlayTime: 0, status: .temporarilyOut)
    ],
    onReturnToBench: { _ in }
  )
  .padding()
}
