//
//  ActivePlayersStepperView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the active players count stepper
struct ActivePlayersStepperView: View {
  // MARK: - Properties

  let activePlayersCount: Int
  let maxPlayers: Int
  let onChange: (Int) -> Void

  // MARK: - Body

  var body: some View {
    Stepper(
      value: Binding(
        get: { activePlayersCount },
        set: { newValue in
          let adjustedValue = min(newValue, maxPlayers > 0 ? maxPlayers : 1)
          onChange(adjustedValue)
        }
      ),
      in: 1...max(1, maxPlayers)
    ) {
      HStack {
        Text("Active Players")
        Spacer()
        Text("\(activePlayersCount)")
          .foregroundStyle(.secondary)
      }
    }
  }
}

// MARK: - Preview

#Preview("Normal Count") {
  Form {
    ActivePlayersStepperView(
      activePlayersCount: 4,
      maxPlayers: 8,
      onChange: { newValue in print("Changed to: \(newValue)") }
    )
  }
}

#Preview("At Minimum (1)") {
  Form {
    ActivePlayersStepperView(
      activePlayersCount: 1,
      maxPlayers: 6,
      onChange: { newValue in print("Changed to: \(newValue)") }
    )
  }
}

#Preview("At Maximum") {
  Form {
    ActivePlayersStepperView(
      activePlayersCount: 5,
      maxPlayers: 5,
      onChange: { newValue in print("Changed to: \(newValue)") }
    )
  }
}

#Preview("With Many Players") {
  Form {
    ActivePlayersStepperView(
      activePlayersCount: 8,
      maxPlayers: 15,
      onChange: { newValue in print("Changed to: \(newValue)") }
    )
  }
}

#Preview("With Few Players") {
  Form {
    ActivePlayersStepperView(
      activePlayersCount: 2,
      maxPlayers: 3,
      onChange: { newValue in print("Changed to: \(newValue)") }
    )
  }
}
