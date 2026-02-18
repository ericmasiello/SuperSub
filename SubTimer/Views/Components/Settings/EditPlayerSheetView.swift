//
//  EditPlayerSheetView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the edit player sheet
struct EditPlayerSheetView: View {
  // MARK: - Properties

  let player: Player
  let onSave: (String, PlayerStatus) -> Void
  let onCancel: () -> Void

  @State private var editedName: String
  @State private var editedStatus: PlayerStatus

  // MARK: - Initialization

  init(
    player: Player,
    onSave: @escaping (String, PlayerStatus) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.player = player
    self.onSave = onSave
    self.onCancel = onCancel
    _editedName = State(initialValue: player.name)
    _editedStatus = State(initialValue: player.status)
  }

  // MARK: - Computed Properties

  private var isNameValid: Bool {
    !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      Form {
        Section("Player Information") {
          TextField("Name", text: $editedName)
            .textInputAutocapitalization(.words)
        }

        Section("Status") {
          Picker("Status", selection: $editedStatus) {
            Text("On Bench").tag(PlayerStatus.benched)
            Text("Currently Playing").tag(PlayerStatus.active)
            Text("Temporarily Out").tag(PlayerStatus.temporarilyOut)
          }
          .pickerStyle(.inline)
        }

        Section {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Current Play Duration:")
              Spacer()
              Text(TimeFormatter.format(player.currentPlayDuration))
                .foregroundStyle(.secondary)
            }
            HStack {
              Text("Total Play Time:")
              Spacer()
              Text(TimeFormatter.format(player.totalPlayTime))
                .foregroundStyle(.secondary)
            }
            HStack {
              Text("Created:")
              Spacer()
              Text(player.createdDate, format: .dateTime.month().day().year())
                .foregroundStyle(.secondary)
            }
          }
        } header: {
          Text("Statistics")
        }
      }
      .navigationTitle("Edit Player")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onCancel()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveChanges()
          }
          .disabled(!isNameValid)
        }
      }
    }
  }

  // MARK: - Actions

  private func saveChanges() {
    let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
    onSave(trimmedName, editedStatus)
  }
}

// MARK: - Preview

#Preview("Active Player") {
  EditPlayerSheetView(
    player: Player(
      name: "Alice",
      currentPlayDuration: 120,
      totalPlayTime: 600,
      status: .active,
      sortOrder: 0
    ),
    onSave: { name, status in print("Save: \(name), \(status)") },
    onCancel: { print("Cancel") }
  )
}

#Preview("Benched Player") {
  EditPlayerSheetView(
    player: Player(
      name: "Bob",
      currentPlayDuration: 0,
      totalPlayTime: 450,
      status: .benched,
      sortOrder: 1
    ),
    onSave: { name, status in print("Save: \(name), \(status)") },
    onCancel: { print("Cancel") }
  )
}

#Preview("Temporarily Out Player") {
  EditPlayerSheetView(
    player: Player(
      name: "Charlie",
      currentPlayDuration: 0,
      totalPlayTime: 300,
      status: .temporarilyOut,
      sortOrder: 2
    ),
    onSave: { name, status in print("Save: \(name), \(status)") },
    onCancel: { print("Cancel") }
  )
}

#Preview("New Player - No Stats") {
  EditPlayerSheetView(
    player: Player(
      name: "Diana",
      currentPlayDuration: 0,
      totalPlayTime: 0,
      status: .benched,
      sortOrder: 3
    ),
    onSave: { name, status in print("Save: \(name), \(status)") },
    onCancel: { print("Cancel") }
  )
}
