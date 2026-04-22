//
//  ActiveBenchLiveActivity.swift
//  ActiveBench
//
//  Created by Eric Masiello on 3/1/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

// Note: ActiveBenchAttributes is defined in ActiveBenchAttributes.swift in this same directory.
// That file should be added to BOTH the main app and widget extension targets in Xcode.

struct ActiveBenchLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ActiveBenchAttributes.self) { context in
      // Lock screen/banner UI goes here
      VStack(spacing: 12) {
        // Session name
        Text(context.attributes.sessionName)
          .font(.headline)
          .foregroundStyle(.secondary)

        // Timer display
        VStack(spacing: 4) {
          Text("Current Play Time")
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(formatTime(context.state.elapsedTime))
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(isOvertime(context.state) ? .red : .primary)

          if context.state.preferredPlayTimeSeconds > 0 {
            HStack(spacing: 4) {
              Image(
                systemName: isOvertime(context.state) ? "exclamationmark.triangle.fill" : "clock"
              )
              Text(timeRemainingText(context.state))
            }
            .font(.caption2)
            .foregroundStyle(isOvertime(context.state) ? .red : .secondary)
          }
        }

        // Timer status
        HStack(spacing: 16) {
          HStack(spacing: 4) {
            Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
            Text(context.state.isRunning ? "Running" : "Paused")
          }
          .font(.caption)

          HStack(spacing: 4) {
            Image(systemName: "person.3.fill")
            Text("\(context.state.activePlayersCount) Active")
          }
          .font(.caption)

          HStack(spacing: 4) {
            Image(systemName: "figure.seated")
            Text("\(context.state.benchedPlayersCount) Bench")
          }
          .font(.caption)
        }
        .foregroundStyle(.secondary)
      }
      .padding()
      .activityBackgroundTint(Color(uiColor: .systemBackground))
      .activitySystemActionForegroundColor(Color.primary)

    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded UI goes here
        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Play Time")
              .font(.caption2)
              .foregroundStyle(.secondary)
            Text(formatTime(context.state.elapsedTime))
              .font(.title3)
              .fontWeight(.semibold)
              .monospacedDigit()
          }
        }

        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 2) {
            Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
              .font(.title2)
              .foregroundStyle(context.state.isRunning ? .green : Color("AppOrange"))
          }
        }

        DynamicIslandExpandedRegion(.bottom) {
          HStack {
            HStack(spacing: 4) {
              Image(systemName: "person.3.fill")
              Text("\(context.state.activePlayersCount)")
            }
            .font(.caption)

            Spacer()

            HStack(spacing: 4) {
              Image(systemName: "figure.seated")
              Text("\(context.state.benchedPlayersCount)")
            }
            .font(.caption)

            if context.state.preferredPlayTimeSeconds > 0 {
              Spacer()

              Text(timeRemainingText(context.state))
                .font(.caption)
                .foregroundStyle(isOvertime(context.state) ? .red : .secondary)
            }
          }
        }
      } compactLeading: {
        HStack(spacing: 2) {
          Image(systemName: context.state.isRunning ? "play.fill" : "pause.fill")
            .font(.caption2)
          Text(formatTimeCompact(context.state.elapsedTime))
            .font(.caption2)
            .monospacedDigit()
        }
      } compactTrailing: {
        HStack(spacing: 4) {
          Image(systemName: "person.3.fill")
            .font(.caption2)
          Text("\(context.state.activePlayersCount)")
            .font(.caption2)
        }
      } minimal: {
        Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
          .foregroundStyle(context.state.isRunning ? .green : Color("AppOrange"))
      }
      .keylineTint(context.state.isRunning ? .green : Color("AppOrange"))
    }
  }

  // MARK: - Helper Functions

  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let totalSeconds = Int(timeInterval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }

  private func formatTimeCompact(_ timeInterval: TimeInterval) -> String {
    let totalSeconds = Int(timeInterval)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  private func isOvertime(_ state: ActiveBenchAttributes.ContentState) -> Bool {
    guard state.preferredPlayTimeSeconds > 0 else { return false }
    return state.elapsedTime > TimeInterval(state.preferredPlayTimeSeconds)
  }

  private func timeRemainingText(_ state: ActiveBenchAttributes.ContentState) -> String {
    let timeRemaining = TimeInterval(state.preferredPlayTimeSeconds) - state.elapsedTime

    if timeRemaining < 0 {
      return "Over by \(formatTimeCompact(abs(timeRemaining)))"
    } else {
      return "Preferred: \(formatTimeCompact(TimeInterval(state.preferredPlayTimeSeconds)))"
    }
  }
}

// MARK: - Previews

extension ActiveBenchAttributes {
  fileprivate static var preview: ActiveBenchAttributes {
    ActiveBenchAttributes(sessionName: "Practice Session")
  }
}

extension ActiveBenchAttributes.ContentState {
  fileprivate static var running: ActiveBenchAttributes.ContentState {
    ActiveBenchAttributes.ContentState(
      isRunning: true,
      elapsedTime: 120,  // 2:00
      preferredPlayTimeSeconds: 180,  // 3:00 preferred
      activePlayersCount: 5,
      benchedPlayersCount: 3
    )
  }

  fileprivate static var paused: ActiveBenchAttributes.ContentState {
    ActiveBenchAttributes.ContentState(
      isRunning: false,
      elapsedTime: 90,  // 1:30
      preferredPlayTimeSeconds: 180,  // 3:00 preferred
      activePlayersCount: 5,
      benchedPlayersCount: 3
    )
  }

  fileprivate static var overtime: ActiveBenchAttributes.ContentState {
    ActiveBenchAttributes.ContentState(
      isRunning: true,
      elapsedTime: 240,  // 4:00
      preferredPlayTimeSeconds: 180,  // 3:00 preferred (1 minute over)
      activePlayersCount: 4,
      benchedPlayersCount: 4
    )
  }
}

#Preview("Notification", as: .content, using: ActiveBenchAttributes.preview) {
  ActiveBenchLiveActivity()
} contentStates: {
  ActiveBenchAttributes.ContentState.running
  ActiveBenchAttributes.ContentState.paused
  ActiveBenchAttributes.ContentState.overtime
}
