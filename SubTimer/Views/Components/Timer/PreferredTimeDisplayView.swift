//
//  PreferredTimeDisplayView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for displaying the current play time with preferred time and overtime indicator
struct PreferredTimeDisplayView: View {
    // MARK: - Properties

    let currentPlayDuration: TimeInterval
    let preferredPlayTimeSeconds: Int

    // MARK: - Computed Properties

    private var timeRemaining: TimeInterval {
        TimeInterval(preferredPlayTimeSeconds) - currentPlayDuration
    }

    private var isOverTime: Bool {
        timeRemaining < 0
    }

    private var hasPreferredTime: Bool {
        preferredPlayTimeSeconds > 0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            Text("Current Play Time")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Main time display
            Text(TimeFormatter.format(currentPlayDuration))
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isOverTime ? .red : .primary)

            // Preferred time indicator
            if hasPreferredTime {
                HStack(spacing: 4) {
                    Image(systemName: isOverTime ? "exclamationmark.triangle.fill" : "clock")
                        .accessibilityHidden(true)
                    Text(timeRemainingText)
                }
                .font(.subheadline)
                .foregroundStyle(isOverTime ? .red : .secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Helper Views

    private var timeRemainingText: String {
        if isOverTime {
            return "Over by \(TimeFormatter.format(abs(timeRemaining)))"
        } else {
            return "Preferred: \(TimeFormatter.format(TimeInterval(preferredPlayTimeSeconds)))"
        }
    }
}

// MARK: - Preview

#Preview("Normal Time") {
    PreferredTimeDisplayView(
        currentPlayDuration: 120, // 2:00
        preferredPlayTimeSeconds: 180 // 3:00 preferred
    )
    .padding()
}

#Preview("Overtime") {
    PreferredTimeDisplayView(
        currentPlayDuration: 240, // 4:00
        preferredPlayTimeSeconds: 180 // 3:00 preferred (1 minute over)
    )
    .padding()
}

#Preview("Zero Time") {
    PreferredTimeDisplayView(
        currentPlayDuration: 0,
        preferredPlayTimeSeconds: 180
    )
    .padding()
}

#Preview("No Preferred Time") {
    PreferredTimeDisplayView(
        currentPlayDuration: 150,
        preferredPlayTimeSeconds: 0
    )
    .padding()
}

#Preview("Near Limit") {
    PreferredTimeDisplayView(
        currentPlayDuration: 175, // 2:55
        preferredPlayTimeSeconds: 180 // 3:00 (5 seconds left)
    )
    .padding()
}
