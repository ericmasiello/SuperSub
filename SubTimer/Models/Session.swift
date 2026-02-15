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
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var duration: TimeInterval
    var substitutionCount: Int
    var preferredPlayTimeSeconds: Int
    var activePlayersCount: Int
    var playerNames: [String]

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        duration: TimeInterval = 0,
        substitutionCount: Int = 0,
        preferredPlayTimeSeconds: Int = 180,
        activePlayersCount: Int = 4,
        playerNames: [String] = []
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
