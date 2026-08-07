//
//  Team.swift
//  SubTimer
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
import SwiftData

@Model
final class Team {
    static let defaultPreferredPlayTimeSeconds = 180
    static let defaultActivePlayersCount = 4

    var id = UUID()
    var name: String = ""
    var sport: String = ""
    var preferredPlayTimeSeconds = Team.defaultPreferredPlayTimeSeconds
    var activePlayersCount = Team.defaultActivePlayersCount

    @Relationship(deleteRule: .nullify, inverse: \RosterMembership.team)
    var rosterMemberships: [RosterMembership]?

    @Relationship(deleteRule: .nullify, inverse: \Game.team)
    var games: [Game]?

    init(
        id: UUID = UUID(),
        name: String,
        sport: String,
        preferredPlayTimeSeconds: Int = Team.defaultPreferredPlayTimeSeconds,
        activePlayersCount: Int = Team.defaultActivePlayersCount
    ) {
        self.id = id
        self.name = name
        self.sport = sport
        self.preferredPlayTimeSeconds = preferredPlayTimeSeconds
        self.activePlayersCount = activePlayersCount
    }
}
