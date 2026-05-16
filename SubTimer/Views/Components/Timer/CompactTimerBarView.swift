//
//  CompactTimerBarView.swift
//  SubTimer
//
//  Created by SubTimer on 5/16/26.
//
//  Compact timer bar that pins below the navigation bar when the user
//  scrolls past the full-size timer display, keeping the current play
//  time always visible during player list management.
//

import SwiftUI

/// Compact sticky timer bar shown when the full-size timer scrolls out of view
struct CompactTimerBarView: View {
    // MARK: - Properties

    let currentPlayDuration: TimeInterval
    let preferredPlayTimeSeconds: Int
    let onTap: () -> Void

    // MARK: - Computed Properties

    private var isOverTime: Bool {
        guard preferredPlayTimeSeconds > 0 else { return false }
        return currentPlayDuration > TimeInterval(preferredPlayTimeSeconds)
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack {
                Spacer()
                Text(TimeFormatter.format(currentPlayDuration))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isOverTime ? .red : .primary)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 0))
        .accessibilityLabel("Current play time: \(TimeFormatter.format(currentPlayDuration))")
        .accessibilityHint("Tap to scroll back to the full timer")
    }
}

// MARK: - Preview

#Preview("Normal Time") {
    CompactTimerBarView(
        currentPlayDuration: 120,
        preferredPlayTimeSeconds: 180,
        onTap: {}
    )
}

#Preview("Overtime") {
    CompactTimerBarView(
        currentPlayDuration: 240,
        preferredPlayTimeSeconds: 180,
        onTap: {}
    )
}

#Preview("Zero Time") {
    CompactTimerBarView(
        currentPlayDuration: 0,
        preferredPlayTimeSeconds: 180,
        onTap: {}
    )
}

#Preview("No Preferred Time") {
    CompactTimerBarView(
        currentPlayDuration: 150,
        preferredPlayTimeSeconds: 0,
        onTap: {}
    )
}
