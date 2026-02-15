//
//  AppConfiguration.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import Foundation
import SwiftData

@Model
final class AppConfiguration {
    var id: UUID
    var preferredPlayTimeSeconds: Int
    var activePlayersCount: Int
    var lastModifiedDate: Date

    init(
        id: UUID = UUID(),
        preferredPlayTimeSeconds: Int = 180, // Default 3:00 minutes
        activePlayersCount: Int = 4,
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.preferredPlayTimeSeconds = preferredPlayTimeSeconds
        self.activePlayersCount = activePlayersCount
        self.lastModifiedDate = lastModifiedDate
    }

    var preferredPlayTimeFormatted: String {
        let minutes = preferredPlayTimeSeconds / 60
        let seconds = preferredPlayTimeSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func isValid(playerCount: Int) -> Bool {
        return activePlayersCount <= playerCount && activePlayersCount > 0
    }
}
