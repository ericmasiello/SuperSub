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

    // Mirrors ActivityKit's own `ActivityContent`/attribute shape; bundling
    // these into a struct would just move the same 7 fields one level over.
    // swiftlint:disable:next function_parameter_count
    func startActivity(
        sessionName: String,
        isRunning: Bool,
        timerStartDate: Date,
        accumulatedTime: TimeInterval,
        preferredPlayTimeSeconds: Int,
        activePlayersCount: Int,
        benchedPlayersCount: Int,
        subOutPlayerName: String? = nil,
        subInPlayerName: String? = nil
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities are not enabled")
            return
        }

        if currentActivity != nil {
            updateActivity(
                isRunning: isRunning,
                timerStartDate: timerStartDate,
                accumulatedTime: accumulatedTime,
                preferredPlayTimeSeconds: preferredPlayTimeSeconds,
                activePlayersCount: activePlayersCount,
                benchedPlayersCount: benchedPlayersCount,
                subOutPlayerName: subOutPlayerName,
                subInPlayerName: subInPlayerName
            )
            return
        }

        let contentState = ActiveBenchAttributes.ContentState(
            isRunning: isRunning,
            timerStartDate: timerStartDate,
            accumulatedTime: accumulatedTime,
            preferredPlayTimeSeconds: preferredPlayTimeSeconds,
            activePlayersCount: activePlayersCount,
            benchedPlayersCount: benchedPlayersCount,
            subOutPlayerName: subOutPlayerName,
            subInPlayerName: subInPlayerName
        )

        do {
            let staleDate = computeStaleDate(
                isRunning: isRunning, timerRefDate: contentState.timerRefDate,
                preferredPlayTimeSeconds: preferredPlayTimeSeconds)
            currentActivity = try Activity.request(
                attributes: ActiveBenchAttributes(sessionName: sessionName),
                content: ActivityContent(state: contentState, staleDate: staleDate)
            )
        } catch {
            print("❌ Error starting Live Activity: \(error.localizedDescription)")
        }
    }

    // Same state shape as `startActivity`, minus `sessionName` (set once at
    // start and immutable for the Live Activity's lifetime).
    // swiftlint:disable:next function_parameter_count
    func updateActivity(
        isRunning: Bool,
        timerStartDate: Date,
        accumulatedTime: TimeInterval,
        preferredPlayTimeSeconds: Int,
        activePlayersCount: Int,
        benchedPlayersCount: Int,
        subOutPlayerName: String? = nil,
        subInPlayerName: String? = nil
    ) {
        guard let activity = currentActivity else { return }

        let contentState = ActiveBenchAttributes.ContentState(
            isRunning: isRunning,
            timerStartDate: timerStartDate,
            accumulatedTime: accumulatedTime,
            preferredPlayTimeSeconds: preferredPlayTimeSeconds,
            activePlayersCount: activePlayersCount,
            benchedPlayersCount: benchedPlayersCount,
            subOutPlayerName: subOutPlayerName,
            subInPlayerName: subInPlayerName
        )

        Task {
            let staleDate = computeStaleDate(
                isRunning: isRunning, timerRefDate: contentState.timerRefDate,
                preferredPlayTimeSeconds: preferredPlayTimeSeconds)
            await activity.update(
                ActivityContent(
                    state: contentState,
                    staleDate: staleDate
                )
            )
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
            let endState = activity.content.state
            let endContent = ActivityContent(state: endState, staleDate: nil)
            await activity.end(endContent, dismissalPolicy: .immediate)
            currentActivity = nil
            print("✅ Live Activity ended successfully")
        }
    }

    /// Check if there's an active Live Activity
    var hasActiveActivity: Bool {
        return currentActivity != nil
    }

    private func computeStaleDate(
        isRunning: Bool, timerRefDate: Date, preferredPlayTimeSeconds: Int
    ) -> Date? {
        guard isRunning, preferredPlayTimeSeconds > 0 else { return nil }
        let overtime = timerRefDate.addingTimeInterval(TimeInterval(preferredPlayTimeSeconds))
        return overtime > Date() ? overtime : nil
    }
}
