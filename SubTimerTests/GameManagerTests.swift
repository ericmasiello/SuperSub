//
//  GameManagerTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/7/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

/// Shared by every `GameManager*Tests` suite below, split by concern to stay under
/// SwiftLint's `type_body_length`.
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

        try? manager.transition(playerId: unknownPlayerId, to: .active, in: game)

        #expect(game.activeOrder.isEmpty)
        #expect((game.stints ?? []).isEmpty)
    }
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
}

struct GameManagerAdHocAndDurationTests {
    @Test func addAdHocPlayerAddsToBenchWithoutRosterMembership() throws {
        let context = try makeGameManagerTestContext()
        let team = Team(name: "Warriors", sport: "Soccer")
        let adHocPlayer = Player(name: "Walk-on")
        let game = Game(team: team)
        context.insert(team)
        context.insert(adHocPlayer)
        context.insert(game)
        let manager = GameManager(context: context)

        try manager.addAdHocPlayer(adHocPlayer, to: game)

        #expect(game.benchOrder == [adHocPlayer.id])
        #expect(game.activeOrder.isEmpty)
        #expect(adHocPlayer.rosterMemberships?.isEmpty ?? true)
    }

    @Test func addAdHocPlayerCanBeTransitionedToActiveAndAccrueAStint() throws {
        let context = try makeGameManagerTestContext()
        let adHocPlayer = Player(name: "Walk-on")
        let game = Game()
        context.insert(adHocPlayer)
        context.insert(game)
        let manager = GameManager(context: context)

        try manager.addAdHocPlayer(adHocPlayer, to: game)
        try manager.transition(playerId: adHocPlayer.id, to: .active, in: game)

        #expect(game.activeOrder == [adHocPlayer.id])
        #expect(game.stints?.contains { $0.player?.id == adHocPlayer.id && $0.endDate == nil } == true)
    }

    @Test func currentPlayDurationReflectsOnlyTheOpenStint() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game()
        context.insert(player)
        context.insert(game)

        let closedStint = Stint(
            startDate: Date().addingTimeInterval(-500),
            endDate: Date().addingTimeInterval(-400),
            player: player,
            game: game
        )
        let openStint = Stint(startDate: Date().addingTimeInterval(-30), player: player, game: game)
        context.insert(closedStint)
        context.insert(openStint)
        game.stints = [closedStint, openStint]

        let manager = GameManager(context: context)
        let duration = manager.currentPlayDuration(playerId: player.id, in: game, now: Date())

        #expect(abs(duration - 30) < 0.01)
    }

    @Test func currentPlayDurationIsZeroWhenNoOpenStint() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game()
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        #expect(manager.currentPlayDuration(playerId: player.id, in: game) == 0)
    }

    @Test func totalPlayTimeSumsAllStintsForThePlayer() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let otherPlayer = Player(name: "Sam")
        let game = Game()
        context.insert(player)
        context.insert(otherPlayer)
        context.insert(game)

        let now = Date()
        let firstStint = Stint(
            startDate: now.addingTimeInterval(-500),
            endDate: now.addingTimeInterval(-400),
            player: player,
            game: game
        )
        let secondStint = Stint(
            startDate: now.addingTimeInterval(-200),
            endDate: now.addingTimeInterval(-150),
            player: player,
            game: game
        )
        let openStint = Stint(startDate: now.addingTimeInterval(-30), player: player, game: game)
        let unrelatedStint = Stint(
            startDate: now.addingTimeInterval(-1000),
            endDate: now,
            player: otherPlayer,
            game: game
        )
        context.insert(firstStint)
        context.insert(secondStint)
        context.insert(openStint)
        context.insert(unrelatedStint)
        game.stints = [firstStint, secondStint, openStint, unrelatedStint]

        let manager = GameManager(context: context)
        let total = manager.totalPlayTime(playerId: player.id, in: game, now: now)

        // 100 (closed) + 50 (closed) + 30 (still-open, measured to `now`) = 180
        #expect(abs(total - 180) < 0.01)
    }

    @Test func gameManagerNeverWritesToPlayersCachedDurationFields() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let bench = Player(name: "Bench")
        let game = Game(benchOrder: [bench.id])
        context.insert(player)
        context.insert(bench)
        context.insert(game)
        let manager = GameManager(context: context)

        try manager.transition(playerId: player.id, to: .active, in: game)
        _ = try manager.automaticSubstitution(game: game)

        #expect(player.currentPlayDuration == Player.defaultCurrentPlayDuration)
        #expect(player.totalPlayTime == Player.defaultTotalPlayTime)
        #expect(bench.currentPlayDuration == Player.defaultCurrentPlayDuration)
        #expect(bench.totalPlayTime == Player.defaultTotalPlayTime)
    }
}
