//
//  LiveActivityManager.swift
//  SubTimer
//
//  Created by SubTimer on 3/1/26.
//

import ActivityKit
import Foundation

// MARK: - Activity Attributes

/// Manages the Live Activity for displaying timer state on lock screen and Dynamic Island
@available(iOS 16.2, *)
class LiveActivityManager {
  static let shared = LiveActivityManager()

  private var currentActivity: Activity<ActiveBenchAttributes>?

  private init() {}

  /// Starts a new Live Activity with the current timer state
  /// - Parameters:
  ///   - sessionName: Name of the current session
  ///   - isRunning: Whether the timer is running
  ///   - elapsedTime: Current elapsed time
  ///   - preferredPlayTimeSeconds: Preferred play time in seconds
  ///   - activePlayersCount: Number of active players
  ///   - benchedPlayersCount: Number of benched players
  func startActivity(
    sessionName: String,
    isRunning: Bool,
    elapsedTime: TimeInterval,
    preferredPlayTimeSeconds: Int,
    activePlayersCount: Int,
    benchedPlayersCount: Int
  ) {
    // Check if activities are enabled
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      print("⚠️ Live Activities are not enabled")
      return
    }

    // Don't end existing activity - just update it if it exists
    if currentActivity != nil {
      print("ℹ️ Live Activity already exists, updating instead of recreating")
      updateActivity(
        isRunning: isRunning,
        elapsedTime: elapsedTime,
        preferredPlayTimeSeconds: preferredPlayTimeSeconds,
        activePlayersCount: activePlayersCount,
        benchedPlayersCount: benchedPlayersCount
      )
      return
    }

    let attributes = ActiveBenchAttributes(sessionName: sessionName)
    let contentState = ActiveBenchAttributes.ContentState(
      isRunning: isRunning,
      elapsedTime: elapsedTime,
      preferredPlayTimeSeconds: preferredPlayTimeSeconds,
      activePlayersCount: activePlayersCount,
      benchedPlayersCount: benchedPlayersCount
    )

    do {
      currentActivity = try Activity.request(
        attributes: attributes,
        content: ActivityContent(state: contentState, staleDate: nil)
      )
      print("✅ Live Activity started successfully - Time: \(Int(elapsedTime))s")
    } catch {
      print("❌ Error starting Live Activity: \(error.localizedDescription)")
    }
  }

  /// Updates the existing Live Activity with new timer state
  /// - Parameters:
  ///   - isRunning: Whether the timer is running
  ///   - elapsedTime: Current elapsed time
  ///   - preferredPlayTimeSeconds: Preferred play time in seconds
  ///   - activePlayersCount: Number of active players
  ///   - benchedPlayersCount: Number of benched players
  func updateActivity(
    isRunning: Bool,
    elapsedTime: TimeInterval,
    preferredPlayTimeSeconds: Int,
    activePlayersCount: Int,
    benchedPlayersCount: Int
  ) {
    guard let activity = currentActivity else {
      print("⚠️ No active Live Activity to update")
      return
    }

    print(
      "🔄 Updating Live Activity - Time: \(Int(elapsedTime))s, Running: \(isRunning), Active: \(activePlayersCount), Benched: \(benchedPlayersCount)"
    )

    let contentState = ActiveBenchAttributes.ContentState(
      isRunning: isRunning,
      elapsedTime: elapsedTime,
      preferredPlayTimeSeconds: preferredPlayTimeSeconds,
      activePlayersCount: activePlayersCount,
      benchedPlayersCount: benchedPlayersCount
    )

    Task {
      await activity.update(
        ActivityContent(
          state: contentState,
          staleDate: nil
        )
      )
      print("✅ Live Activity updated successfully")
    }
  }

  /// Ends the current Live Activity
  func endActivity() {
    guard let activity = currentActivity else {
      print("ℹ️ No Live Activity to end")
      return
    }

    print("🛑 Ending Live Activity")
    Task {
      await activity.end(dismissalPolicy: .immediate)
      currentActivity = nil
      print("✅ Live Activity ended successfully")
    }
  }

  /// Check if there's an active Live Activity
  var hasActiveActivity: Bool {
    return currentActivity != nil
  }
}
