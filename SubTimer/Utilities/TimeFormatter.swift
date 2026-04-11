//
//  TimeFormatter.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import Foundation

/// Utility for consistent time formatting across the app
enum TimeFormatter {
    /// Formats a TimeInterval into a readable string (M:SS or H:MM:SS)
    /// - Parameter timeInterval: The time interval in seconds
    /// - Returns: Formatted string like "3:45" or "1:23:45"
    static func format(_ timeInterval: TimeInterval) -> String {
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

    /// Formats a TimeInterval into a detailed string with labels
    /// - Parameter timeInterval: The time interval in seconds
    /// - Returns: Formatted string like "3m 45s" or "1h 23m 45s"
    static func formatWithLabels(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var components: [String] = []

        if hours > 0 {
            components.append("\(hours)h")
        }
        if minutes > 0 || hours > 0 {
            components.append("\(minutes)m")
        }
        components.append("\(seconds)s")

        return components.joined(separator: " ")
    }

    /// Formats seconds into minutes:seconds format
    /// - Parameter seconds: The number of seconds
    /// - Returns: Formatted string like "3:30"
    static func formatMinutesSeconds(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Converts a formatted time string (M:SS) back to seconds
    /// - Parameter formattedTime: String in format "3:30"
    /// - Returns: Total seconds, or nil if format is invalid
    static func parseMinutesSeconds(_ formattedTime: String) -> Int? {
        let components = formattedTime.split(separator: ":")
        guard components.count == 2,
              let minutes = Int(components[0]),
              let seconds = Int(components[1]),
              seconds < 60
        else {
            return nil
        }
        return (minutes * 60) + seconds
    }

    /// Returns a human-readable relative time description
    /// - Parameter timeInterval: The time interval in seconds
    /// - Returns: String like "Just now", "2 minutes ago", etc.
    static func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Formats time remaining until a target time
    /// - Parameters:
    ///   - current: Current time in seconds
    ///   - target: Target time in seconds
    /// - Returns: Tuple of (formatted string, isOvertime boolean)
    static func formatRemaining(current: TimeInterval, target: TimeInterval) -> (formatted: String, isOvertime: Bool) {
        let remaining = target - current
        let isOvertime = remaining < 0
        let displayTime = abs(remaining)

        return (format(displayTime), isOvertime)
    }

    /// Validates if a time interval is within acceptable bounds
    /// - Parameters:
    ///   - timeInterval: Time to validate
    ///   - min: Minimum acceptable time
    ///   - max: Maximum acceptable time
    /// - Returns: True if within bounds
    static func isValid(_ timeInterval: TimeInterval, min: TimeInterval = 30, max: TimeInterval = 1800) -> Bool {
        return timeInterval >= min && timeInterval <= max
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Convenience property to format TimeInterval directly
    var formatted: String {
        TimeFormatter.format(self)
    }

    /// Convenience property to format TimeInterval with labels
    var formattedWithLabels: String {
        TimeFormatter.formatWithLabels(self)
    }

    /// Returns true if this time interval is valid for SubTimer (30s - 30min)
    var isValidPlayTime: Bool {
        TimeFormatter.isValid(self)
    }
}

// MARK: - Int Extensions for Seconds

extension Int {
    /// Convenience property to format seconds as M:SS
    var asTimeString: String {
        TimeFormatter.formatMinutesSeconds(seconds: self)
    }

    /// Converts seconds to TimeInterval
    var asTimeInterval: TimeInterval {
        TimeInterval(self)
    }
}
