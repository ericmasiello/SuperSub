//
//  SettingsPlayerRowView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying a single player row in settings
struct SettingsPlayerRowView: View {
  // MARK: - Properties

  let player: Player
  let onEdit: () -> Void

  // MARK: - Body

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(player.name)
          .font(.body)
        Text(statusText(for: player.status))
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button {
        onEdit()
      } label: {
        Image(systemName: "pencil")
          .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Helper Methods

  private func statusText(for status: PlayerStatus) -> String {
    switch status {
    case .active:
      return "Currently Playing"
    case .benched:
      return "On Bench"
    case .temporarilyOut:
      return "Temporarily Out"
    }
  }
}

// MARK: - Preview

#Preview("Active Player") {
  List {
    SettingsPlayerRowView(
      player: Player(name: "Alice", status: .active, sortOrder: 0),
      onEdit: { print("Edit tapped") }
    )
  }
}

#Preview("Benched Player") {
  List {
    SettingsPlayerRowView(
      player: Player(name: "Bob", status: .benched, sortOrder: 1),
      onEdit: { print("Edit tapped") }
    )
  }
}

#Preview("Temporarily Out Player") {
  List {
    SettingsPlayerRowView(
      player: Player(name: "Charlie", status: .temporarilyOut, sortOrder: 2),
      onEdit: { print("Edit tapped") }
    )
  }
}

#Preview("Multiple Players") {
  List {
    SettingsPlayerRowView(
      player: Player(name: "Alice", status: .active, sortOrder: 0),
      onEdit: { print("Edit Alice") }
    )
    SettingsPlayerRowView(
      player: Player(name: "Bob", status: .benched, sortOrder: 1),
      onEdit: { print("Edit Bob") }
    )
    SettingsPlayerRowView(
      player: Player(name: "Charlie", status: .temporarilyOut, sortOrder: 2),
      onEdit: { print("Edit Charlie") }
    )
  }
}
