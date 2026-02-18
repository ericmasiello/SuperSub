//
//  AddPlayerSheetView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the add player sheet
struct AddPlayerSheetView: View {
  // MARK: - Properties

  @Binding var playerName: String
  let onCancel: () -> Void
  let onAdd: () -> Void

  // MARK: - Computed Properties

  private var isNameValid: Bool {
    !playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      Form {
        TextField("Player Name", text: $playerName)
          .textInputAutocapitalization(.words)
      }
      .navigationTitle("Add Player")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onCancel()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            onAdd()
          }
          .disabled(!isNameValid)
        }
      }
    }
  }
}

// MARK: - Preview

#Preview("Empty Name") {
  AddPlayerSheetView(
    playerName: .constant(""),
    onCancel: { print("Cancelled") },
    onAdd: { print("Add player") }
  )
}

#Preview("With Name") {
  AddPlayerSheetView(
    playerName: .constant("Alice"),
    onCancel: { print("Cancelled") },
    onAdd: { print("Add player") }
  )
}

#Preview("With Whitespace Only") {
  AddPlayerSheetView(
    playerName: .constant("   "),
    onCancel: { print("Cancelled") },
    onAdd: { print("Add player") }
  )
}

#Preview("Long Name") {
  AddPlayerSheetView(
    playerName: .constant("Alexander Christopher Johnson"),
    onCancel: { print("Cancelled") },
    onAdd: { print("Add player") }
  )
}
