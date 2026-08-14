//
//  GameManagerSubstitutionTests.swift
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

struct GameManagerSubstitutionTests {
    @Test func automaticSubstitutionSwapsLongestServingActiveForNextUpBench() throws {
        let context = try makeGameManagerTestContext()
        let playerA = Player(name: "A")
        let playerB = Player(name: "B")
        let bench1 = Player(name: "Bench1")
        let bench2 = Player(name: "Bench2")
        let game = Game(activeOrder: [playerA.id, playerB.id], benchOrder: [bench1.id, bench2.id])
        context.insert(playerA)
        context.insert(playerB)
        context.insert(bench1)
        context.insert(bench2)
        context.insert(game)

        let stintA = Stint(startDate: Date().addingTimeInterval(-600), player: playerA, game: game)
        let stintB = Stint(startDate: Date().addingTimeInterval(-60), player: playerB, game: game)
        context.insert(stintA)
        context.insert(stintB)
        game.stints = [stintA, stintB]

        let manager = GameManager(context: context)
        let result = try manager.automaticSubstitution(game: game)

        #expect(result == Substitution(outgoingPlayerId: playerA.id, incomingPlayerId: bench1.id))
        #expect(game.activeOrder == [playerB.id, bench1.id])
        #expect(game.benchOrder == [bench2.id, playerA.id])
        #expect(game.substitutionCount == 1)
        #expect(stintA.endDate != nil)
        #expect(game.stints?.contains { $0.player?.id == bench1.id && $0.endDate == nil } == true)
    }

    @Test func automaticSubstitutionReturnsNilWhenBenchIsEmpty() throws {
        let context = try makeGameManagerTestContext()
        let playerA = Player(name: "A")
        let game = Game(activeOrder: [playerA.id])
        context.insert(playerA)
        context.insert(game)

        let stintA = Stint(startDate: Date(), player: playerA, game: game)
        context.insert(stintA)
        game.stints = [stintA]

        let manager = GameManager(context: context)
        let result = try manager.automaticSubstitution(game: game)

        #expect(result == nil)
        #expect(game.activeOrder == [playerA.id])
        #expect(stintA.endDate == nil)
        #expect(game.substitutionCount == 0)
    }

    @Test func manualSubstitutionSwapsSpecifiedPlayers() throws {
        let context = try makeGameManagerTestContext()
        let outgoing = Player(name: "Out")
        let incoming = Player(name: "In")
        let game = Game(activeOrder: [outgoing.id], benchOrder: [incoming.id])
        context.insert(outgoing)
        context.insert(incoming)
        context.insert(game)

        let openStint = Stint(startDate: Date(), player: outgoing, game: game)
        context.insert(openStint)
        game.stints = [openStint]

        let manager = GameManager(context: context)
        try manager.manualSubstitution(outgoing: outgoing.id, incoming: incoming.id, game: game)

        #expect(game.activeOrder == [incoming.id])
        #expect(game.benchOrder == [outgoing.id])
        #expect(game.substitutionCount == 1)
        #expect(openStint.endDate != nil)
    }

    @Test func manualSubstitutionThrowsWhenOutgoingNotActive() throws {
        let context = try makeGameManagerTestContext()
        let outgoing = Player(name: "Out")
        let incoming = Player(name: "In")
        let game = Game(benchOrder: [outgoing.id, incoming.id])
        context.insert(outgoing)
        context.insert(incoming)
        context.insert(game)
        let manager = GameManager(context: context)

        #expect(throws: GameManagerError.outgoingPlayerNotActive) {
            try manager.manualSubstitution(outgoing: outgoing.id, incoming: incoming.id, game: game)
        }
    }

    @Test func manualSubstitutionThrowsWhenIncomingAlreadyActive() throws {
        let context = try makeGameManagerTestContext()
        let outgoing = Player(name: "Out")
        let incoming = Player(name: "In")
        let game = Game(activeOrder: [outgoing.id, incoming.id])
        context.insert(outgoing)
        context.insert(incoming)
        context.insert(game)
        let manager = GameManager(context: context)

        #expect(throws: GameManagerError.incomingPlayerAlreadyActive) {
            try manager.manualSubstitution(outgoing: outgoing.id, incoming: incoming.id, game: game)
        }
    }

    @Test func automaticSubstitutionLeavesStateUntouchedWhenIncomingPlayerIsUnknown() throws {
        let context = try makeGameManagerTestContext()
        let outgoing = Player(name: "Out")
        let unknownIncomingId = UUID()
        let game = Game(activeOrder: [outgoing.id], benchOrder: [unknownIncomingId])
        context.insert(outgoing)
        context.insert(game)

        let openStint = Stint(startDate: Date(), player: outgoing, game: game)
        context.insert(openStint)
        game.stints = [openStint]

        let manager = GameManager(context: context)

        #expect(throws: GameManagerError.playerNotFound) {
            try manager.automaticSubstitution(game: game)
        }

        #expect(game.activeOrder == [outgoing.id])
        #expect(game.benchOrder == [unknownIncomingId])
        #expect(game.substitutionCount == 0)
        #expect(openStint.endDate == nil)
    }

    @Test func manualSubstitutionLeavesStateUntouchedWhenIncomingPlayerIsUnknown() throws {
        let context = try makeGameManagerTestContext()
        let outgoing = Player(name: "Out")
        let unknownIncomingId = UUID()
        let game = Game(activeOrder: [outgoing.id])
        context.insert(outgoing)
        context.insert(game)

        let openStint = Stint(startDate: Date(), player: outgoing, game: game)
        context.insert(openStint)
        game.stints = [openStint]

        let manager = GameManager(context: context)

        #expect(throws: GameManagerError.playerNotFound) {
            try manager.manualSubstitution(outgoing: outgoing.id, incoming: unknownIncomingId, game: game)
        }

        #expect(game.activeOrder == [outgoing.id])
        #expect(game.benchOrder.isEmpty)
        #expect(game.substitutionCount == 0)
        #expect(openStint.endDate == nil)
    }
}
