//
//  TemporarilyOutPlayerRowView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying a single temporarily out player row
struct TemporarilyOutPlayerRowView: View {
  // MARK: - Properties

  let player: Player
  let onReturnToBench: () -> Void

  // MARK: - Body

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(player.name)
          .font(.headline)
        Text("Total: \(TimeFormatter.format(player.totalPlayTime))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button(action: onReturnToBench) {
        Text("Return to Bench")
          .font(.subheadline)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.blue)
          .foregroundStyle(.white)
          .cornerRadius(6)
      }
    }
    .padding()
    .background(Color.yellow.opacity(0.1))
    .cornerRadius(8)
    .accessibilityIdentifier("player.row.tempout")
  }
}

// MARK: - Preview

#Preview("Temporarily Out Player") {
  TemporarilyOutPlayerRowView(
    player: Player(name: "John Doe", totalPlayTime: 300),
    onReturnToBench: { print("Return to bench tapped") }
  )
  .padding()
}

#Preview("High Play Time") {
  TemporarilyOutPlayerRowView(
    player: Player(name: "Jane Smith", totalPlayTime: 600),
    onReturnToBench: { print("Return to bench tapped") }
  )
  .padding()
}

#Preview("Low Play Time") {
  TemporarilyOutPlayerRowView(
    player: Player(name: "Mike Johnson", totalPlayTime: 30),
    onReturnToBench: { print("Return to bench tapped") }
  )
  .padding()
}

#Preview("Zero Play Time") {
  TemporarilyOutPlayerRowView(
    player: Player(name: "New Player", totalPlayTime: 0),
    onReturnToBench: { print("Return to bench tapped") }
  )
  .padding()
}
