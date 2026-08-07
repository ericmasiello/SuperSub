//
//  GameTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct GameTests {
    @Test func gameInitialization() {
        let game = Game()

        #expect(game.endDate == nil)
        #expect(game.substitutionCount == 0)
        #expect(game.preferredPlayTimeSeconds == 180)
        #expect(game.activePlayersCount == 4)
        #expect(game.activeOrder.isEmpty)
        #expect(game.benchOrder.isEmpty)
        #expect(game.temporarilyOut.isEmpty)
        #expect(game.team == nil)
        #expect(game.stints == nil)
    }

    @Test func gameOrderTracking() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let game = Game(activeOrder: [id1, id2], benchOrder: [id3], temporarilyOut: [id2])

        #expect(game.activeOrder == [id1, id2])
        #expect(game.benchOrder == [id3])
        #expect(game.temporarilyOut == [id2])
    }

    @Test func gameTeamAssociation() {
        let team = Team(name: "Warriors", sport: "Soccer")
        let game = Game(team: team)

        #expect(game.team === team)
    }
}
