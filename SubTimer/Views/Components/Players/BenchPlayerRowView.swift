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
  let isNextUp: Bool
  let canActivate: Bool
  let onTap: () -> Void
  let onActivate: () -> Void

  // MARK: - Body

  var body: some View {
    Button(action: onTap) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(player.name)
              .font(.headline)
            if isNextUp && !canActivate {
              Image(systemName: "arrow.up.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
            }
          }
          Text("Total: \(TimeFormatter.format(player.totalPlayTime))")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }

        Spacer()

        if canActivate {
          Button(action: onActivate) {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
              .foregroundStyle(.green)
          }
        }
      }
      .padding()
      .background(isNextUp ? Color.green.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Preview

#Preview("Normal Bench Player") {
  BenchPlayerRowView(
    player: Player(name: "John Doe", totalPlayTime: 180),
    isNextUp: false,
    canActivate: false,
    onTap: { print("Player tapped") },
    onActivate: { print("Activate tapped") }
  )
  .padding()
}

#Preview("Next Up Player") {
  BenchPlayerRowView(
    player: Player(name: "Jane Smith", totalPlayTime: 240),
    isNextUp: true,
    canActivate: false,
    onTap: { print("Player tapped") },
    onActivate: { print("Activate tapped") }
  )
  .padding()
}

#Preview("Can Activate") {
  BenchPlayerRowView(
    player: Player(name: "Mike Johnson", totalPlayTime: 120),
    isNextUp: false,
    canActivate: true,
    onTap: { print("Player tapped") },
    onActivate: { print("Activate tapped") }
  )
  .padding()
}

#Preview("Next Up & Can Activate") {
  BenchPlayerRowView(
    player: Player(name: "Sarah Williams", totalPlayTime: 60),
    isNextUp: true,
    canActivate: true,
    onTap: { print("Player tapped") },
    onActivate: { print("Activate tapped") }
  )
  .padding()
}

#Preview("Zero Play Time") {
  BenchPlayerRowView(
    player: Player(name: "New Player", totalPlayTime: 0),
    isNextUp: false,
    canActivate: true,
    onTap: { print("Player tapped") },
    onActivate: { print("Activate tapped") }
  )
  .padding()
}
