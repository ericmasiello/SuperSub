//
//  ActiveBenchAttributes.swift
//  SubTimer
//
//  Created by SubTimer on 3/1/26.
//
//  Shared Activity Attributes for Live Activity
//  This file is included in both the main app and widget extension targets

import ActivityKit
import Foundation

/// Activity attributes for the SubTimer Live Activity
/// Defines the structure for timer state displayed on lock screen and Dynamic Island
struct ActiveBenchAttributes: ActivityAttributes {
  /// Dynamic state that changes during the activity
  public struct ContentState: Codable, Hashable {
    // Timer state properties
    var isRunning: Bool
    var elapsedTime: TimeInterval
    var preferredPlayTimeSeconds: Int

    /// Virtual start date (timerStartDate - accumulatedTime) enabling Text(date, style: .timer) auto-updates in background.
    var timerRefDate: Date

    // Player counts
    var activePlayersCount: Int
    var benchedPlayersCount: Int
  }

  // Fixed non-changing properties about your activity
  var sessionName: String
}
