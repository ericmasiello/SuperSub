//
//  GameManagerTransitionTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/7/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

private func makeGameManagerTestContext() throws -> ModelContext {
    let schema = Schema([Player.self, Team.self, RosterMembership.self, Game.self, Stint.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return ModelContext(container)
}

struct GameManagerTransitionTests {
    @Test func transitionMovesPlayerIntoActiveAndOpensStint() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game()
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        try manager.transition(playerId: player.id, to: .active, in: game)

        #expect(game.activeOrder == [player.id])
        #expect(game.benchOrder.isEmpty)
        #expect(game.temporarilyOut.isEmpty)

        let openStints = game.stints?.filter { $0.endDate == nil } ?? []
        #expect(openStints.count == 1)
        #expect(openStints.first?.player?.id == player.id)
    }

    @Test func transitionOutOfActiveClosesOpenStint() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game()
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        try manager.transition(playerId: player.id, to: .active, in: game)
        try manager.transition(playerId: player.id, to: .benched, in: game)

        #expect(game.activeOrder.isEmpty)
        #expect(game.benchOrder == [player.id])

        let stints = game.stints ?? []
        #expect(stints.count == 1)
        #expect(stints.first?.endDate != nil)
    }

    @Test func transitionNeverLeavesPlayerInTwoBuckets() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game(benchOrder: [player.id])
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        try manager.transition(playerId: player.id, to: .temporarilyOut, in: game)

        #expect(game.activeOrder.isEmpty)
        #expect(game.benchOrder.isEmpty)
        #expect(game.temporarilyOut == [player.id])
    }

    @Test func transitionBetweenNonActiveBucketsDoesNotTouchStints() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game(benchOrder: [player.id])
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        try manager.transition(playerId: player.id, to: .temporarilyOut, in: game)

        #expect((game.stints ?? []).isEmpty)
    }

    @Test func transitionThrowsWhenEnteringActiveForUnknownPlayer() throws {
        let context = try makeGameManagerTestContext()
        let game = Game()
        context.insert(game)
        let manager = GameManager(context: context)
        let unknownPlayerId = UUID()

        #expect(throws: GameManagerError.playerNotFound) {
            try manager.transition(playerId: unknownPlayerId, to: .active, in: game)
        }
    }

    @Test func transitionLeavesBucketsUntouchedWhenOpeningStintFails() throws {
        let context = try makeGameManagerTestContext()
        let game = Game(benchOrder: [])
        context.insert(game)
        let manager = GameManager(context: context)
        let unknownPlayerId = UUID()

        #expect(throws: GameManagerError.playerNotFound) {
            try manager.transition(playerId: unknownPlayerId, to: .active, in: game)
        }

        #expect(game.activeOrder.isEmpty)
        #expect((game.stints ?? []).isEmpty)
    }

    @Test func redundantTransitionToActiveDoesNotCloseTheOpenStint() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game()
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        try manager.transition(playerId: player.id, to: .active, in: game)
        try manager.transition(playerId: player.id, to: .active, in: game)

        #expect(game.activeOrder == [player.id])
        let stints = game.stints ?? []
        #expect(stints.count == 1)
        #expect(stints.first?.endDate == nil)
    }
}
