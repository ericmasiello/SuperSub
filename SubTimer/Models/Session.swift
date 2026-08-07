//
//  Session.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import Foundation
import SwiftData

@Model
final class Session {
    static let defaultDuration: TimeInterval = 0
    static let defaultSubstitutionCount = 0
    static let defaultPreferredPlayTimeSeconds = 180 // Default 3:00 minutes
    static let defaultActivePlayersCount = 4
    static let defaultPlayerNames: [String] = []

    var id = UUID()
    var startDate = Date()
    var endDate: Date?
    var duration = Session.defaultDuration
    var substitutionCount = Session.defaultSubstitutionCount
    var preferredPlayTimeSeconds = Session.defaultPreferredPlayTimeSeconds
    var activePlayersCount = Session.defaultActivePlayersCount
    var playerNames = Session.defaultPlayerNames

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        duration: TimeInterval = Session.defaultDuration,
        substitutionCount: Int = Session.defaultSubstitutionCount,
        preferredPlayTimeSeconds: Int = Session.defaultPreferredPlayTimeSeconds,
        activePlayersCount: Int = Session.defaultActivePlayersCount,
        playerNames: [String] = Session.defaultPlayerNames
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.substitutionCount = substitutionCount
        self.preferredPlayTimeSeconds = preferredPlayTimeSeconds
        self.activePlayersCount = activePlayersCount
        self.playerNames = playerNames
    }

    var isActive: Bool {
        return endDate == nil
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
