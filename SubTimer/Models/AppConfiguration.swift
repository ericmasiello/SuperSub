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
    static let defaultPreferredPlayTimeSeconds = 180 // Default 3:00 minutes
    static let defaultActivePlayersCount = 4

    var id = UUID()
    var preferredPlayTimeSeconds = AppConfiguration.defaultPreferredPlayTimeSeconds
    var activePlayersCount = AppConfiguration.defaultActivePlayersCount
    var lastModifiedDate = Date()

    init(
        id: UUID = UUID(),
        preferredPlayTimeSeconds: Int = AppConfiguration.defaultPreferredPlayTimeSeconds,
        activePlayersCount: Int = AppConfiguration.defaultActivePlayersCount,
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
