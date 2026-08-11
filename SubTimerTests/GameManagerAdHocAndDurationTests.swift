//
//  GameManagerAdHocAndDurationTests.swift
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
