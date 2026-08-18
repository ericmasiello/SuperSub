//
//  Game.swift
//  SubTimer
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
import SwiftData

@Model
final class Game {
    static let defaultDuration: TimeInterval = 0
    static let defaultSubstitutionCount = 0
    static let defaultPreferredPlayTimeSeconds = 180
    static let defaultActivePlayersCount = 4
    static let defaultActiveOrder: [UUID] = []
    static let defaultBenchOrder: [UUID] = []
    static let defaultTemporarilyOut: Set<UUID> = []

    var id = UUID()
    var startDate = Date()
    var endDate: Date?
    var duration = Game.defaultDuration
    var substitutionCount = Game.defaultSubstitutionCount
    var preferredPlayTimeSeconds = Game.defaultPreferredPlayTimeSeconds
    var activePlayersCount = Game.defaultActivePlayersCount
    var activeOrder = Game.defaultActiveOrder
    var benchOrder = Game.defaultBenchOrder
    var temporarilyOut = Game.defaultTemporarilyOut

    @Relationship(deleteRule: .nullify)
    var team: Team?

    @Relationship(deleteRule: .nullify, inverse: \Stint.game)
    var stints: [Stint]?

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        duration: TimeInterval = Game.defaultDuration,
        substitutionCount: Int = Game.defaultSubstitutionCount,
        preferredPlayTimeSeconds: Int = Game.defaultPreferredPlayTimeSeconds,
        activePlayersCount: Int = Game.defaultActivePlayersCount,
        activeOrder: [UUID] = Game.defaultActiveOrder,
        benchOrder: [UUID] = Game.defaultBenchOrder,
        temporarilyOut: Set<UUID> = Game.defaultTemporarilyOut,
        team: Team? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.substitutionCount = substitutionCount
        self.preferredPlayTimeSeconds = preferredPlayTimeSeconds
        self.activePlayersCount = activePlayersCount
        self.activeOrder = activeOrder
        self.benchOrder = benchOrder
        self.temporarilyOut = temporarilyOut
        self.team = team
    }
}
