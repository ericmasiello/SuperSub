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
      VStack(spacing: 12) {
        VStack(spacing: 4) {
          Text("Current Play Time")
            .font(.caption)
            .foregroundStyle(.secondary)

          HStack(alignment: .firstTextBaseline, spacing: 12) {
            if context.state.isRunning {
              Text(context.state.timerRefDate, style: .timer)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isOvertime(context.state) ? .red : .primary)
            } else {
              Text(formatTime(context.state.accumulatedTime))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isOvertime(context.state) ? .red : .primary)
            }

            if let subOut = context.state.subOutPlayerName,
              let subIn = context.state.subInPlayerName
            {
              Text("\(subOut) → \(subIn)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("AppOrange"))
                .lineLimit(1)
            }
          }
        }

        HStack(spacing: 16) {
          Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
            .foregroundStyle(context.state.isRunning ? .green : Color("AppOrange"))

          HStack(spacing: 4) {
            Image(systemName: "person.3.fill")
            Text("\(context.state.activePlayersCount) Active")
          }

          HStack(spacing: 4) {
            Image(systemName: "figure.seated")
            Text("\(context.state.benchedPlayersCount) Bench")
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      .padding()
      .activityBackgroundTint(Color(uiColor: .systemBackground))
      .activitySystemActionForegroundColor(Color.primary)

    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          if context.state.isRunning {
            Text(context.state.timerRefDate, style: .timer)
              .font(.title3)
              .fontWeight(.semibold)
              .monospacedDigit()
              .foregroundStyle(isOvertime(context.state) ? .red : .primary)
          } else {
            Text(formatTime(context.state.accumulatedTime))
              .font(.title3)
              .fontWeight(.semibold)
              .monospacedDigit()
              .foregroundStyle(isOvertime(context.state) ? .red : .primary)
          }
        }

        DynamicIslandExpandedRegion(.center) {
          if let subOut = context.state.subOutPlayerName,
            let subIn = context.state.subInPlayerName
          {
            Text("\(subOut) → \(subIn)")
              .font(.title3)
              .fontWeight(.semibold)
              .foregroundStyle(Color("AppOrange"))
              .lineLimit(1)
              .minimumScaleFactor(0.7)
          }
        }

        DynamicIslandExpandedRegion(.trailing) {
          Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
            .font(.title2)
            .foregroundStyle(context.state.isRunning ? .green : Color("AppOrange"))
        }

        DynamicIslandExpandedRegion(.bottom) {
          HStack(spacing: 16) {
            HStack(spacing: 4) {
              Image(systemName: "person.3.fill")
              Text("\(context.state.activePlayersCount)")
            }

            HStack(spacing: 4) {
              Image(systemName: "figure.seated")
              Text("\(context.state.benchedPlayersCount)")
            }
          }
          .font(.caption)
        }
      } compactLeading: {
        HStack(spacing: 2) {
          Image(systemName: context.state.isRunning ? "play.fill" : "pause.fill")
            .font(.caption2)
          if context.state.isRunning {
            Text(context.state.timerRefDate, style: .timer)
              .font(.caption2)
              .monospacedDigit()
              .foregroundStyle(isOvertime(context.state) ? .red : .primary)
          } else {
            Text(formatTimeCompact(context.state.accumulatedTime))
              .font(.caption2)
              .monospacedDigit()
              .foregroundStyle(isOvertime(context.state) ? .red : .primary)
          }
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

  private func overtimeDate(_ state: ActiveBenchAttributes.ContentState) -> Date {
    state.timerRefDate.addingTimeInterval(TimeInterval(state.preferredPlayTimeSeconds))
  }

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
    if state.isRunning {
      let elapsed = Date().timeIntervalSince(state.timerRefDate)
      return elapsed > TimeInterval(state.preferredPlayTimeSeconds)
    }
    return state.accumulatedTime > TimeInterval(state.preferredPlayTimeSeconds)
  }

  private func timeRemainingText(_ state: ActiveBenchAttributes.ContentState) -> String {
    let timeRemaining = TimeInterval(state.preferredPlayTimeSeconds) - state.accumulatedTime

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
      timerStartDate: Date().addingTimeInterval(-120),
      accumulatedTime: 0,
      preferredPlayTimeSeconds: 180,
      activePlayersCount: 5,
      benchedPlayersCount: 3,
      subOutPlayerName: "Alice",
      subInPlayerName: "Bob"
    )
  }

  fileprivate static var paused: ActiveBenchAttributes.ContentState {
    ActiveBenchAttributes.ContentState(
      isRunning: false,
      timerStartDate: Date(),
      accumulatedTime: 90,
      preferredPlayTimeSeconds: 180,
      activePlayersCount: 5,
      benchedPlayersCount: 3,
      subOutPlayerName: "Alice",
      subInPlayerName: "Bob"
    )
  }

  fileprivate static var overtime: ActiveBenchAttributes.ContentState {
    ActiveBenchAttributes.ContentState(
      isRunning: true,
      timerStartDate: Date().addingTimeInterval(-240),
      accumulatedTime: 0,
      preferredPlayTimeSeconds: 180,
      activePlayersCount: 4,
      benchedPlayersCount: 4,
      subOutPlayerName: "Charlie",
      subInPlayerName: "Diana"
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

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: ActiveBenchAttributes.preview) {
  ActiveBenchLiveActivity()
} contentStates: {
  ActiveBenchAttributes.ContentState.running
  ActiveBenchAttributes.ContentState.paused
  ActiveBenchAttributes.ContentState.overtime
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: ActiveBenchAttributes.preview) {
  ActiveBenchLiveActivity()
} contentStates: {
  ActiveBenchAttributes.ContentState.running
  ActiveBenchAttributes.ContentState.paused
  ActiveBenchAttributes.ContentState.overtime
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: ActiveBenchAttributes.preview) {
  ActiveBenchLiveActivity()
} contentStates: {
  ActiveBenchAttributes.ContentState.running
  ActiveBenchAttributes.ContentState.paused
  ActiveBenchAttributes.ContentState.overtime
}
