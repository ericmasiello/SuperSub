//
//  GameManagerStatusAndOrderTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/18/26.
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

struct GameManagerStatusAndOrderTests {
    @Test func statusReturnsActiveForPlayerInActiveOrder() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game(activeOrder: [player.id])
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        #expect(manager.status(playerId: player.id, in: game) == .active)
    }

    @Test func statusReturnsTemporarilyOutForPlayerInTemporarilyOutSet() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game(temporarilyOut: [player.id])
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        #expect(manager.status(playerId: player.id, in: game) == .temporarilyOut)
    }

    @Test func statusReturnsBenchedForPlayerInBenchOrder() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game(benchOrder: [player.id])
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        #expect(manager.status(playerId: player.id, in: game) == .benched)
    }

    @Test func statusDefaultsToBenchedForPlayerInNoBucket() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game()
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        #expect(manager.status(playerId: player.id, in: game) == .benched)
    }

    @Test func setOrderReplacesActiveOrderWithoutChangingMembership() throws {
        let context = try makeGameManagerTestContext()
        let playerA = Player(name: "A")
        let playerB = Player(name: "B")
        let game = Game(activeOrder: [playerA.id, playerB.id])
        context.insert(playerA)
        context.insert(playerB)
        context.insert(game)
        let manager = GameManager(context: context)

        manager.setOrder([playerB.id, playerA.id], for: .active, in: game)

        #expect(game.activeOrder == [playerB.id, playerA.id])
    }

    @Test func setOrderReplacesBenchOrderWithoutChangingMembership() throws {
        let context = try makeGameManagerTestContext()
        let playerA = Player(name: "A")
        let playerB = Player(name: "B")
        let game = Game(benchOrder: [playerA.id, playerB.id])
        context.insert(playerA)
        context.insert(playerB)
        context.insert(game)
        let manager = GameManager(context: context)

        manager.setOrder([playerB.id, playerA.id], for: .benched, in: game)

        #expect(game.benchOrder == [playerB.id, playerA.id])
    }

    @Test func setOrderIsNoOpForTemporarilyOut() throws {
        let context = try makeGameManagerTestContext()
        let player = Player(name: "Alex")
        let game = Game(temporarilyOut: [player.id])
        context.insert(player)
        context.insert(game)
        let manager = GameManager(context: context)

        manager.setOrder([player.id], for: .temporarilyOut, in: game)

        #expect(game.temporarilyOut == [player.id])
    }

    @Test func seedFromLegacyStatusSeedsBucketMembership() throws {
        let context = try makeGameManagerTestContext()
        let active = Player(name: "Active")
        let benched = Player(name: "Benched")
        let tempOut = Player(name: "TempOut")
        let game = Game()
        context.insert(active)
        context.insert(benched)
        context.insert(tempOut)
        context.insert(game)
        let manager = GameManager(context: context)

        manager.seedFromLegacyStatus(
            LegacyRotationSnapshot(
                activePlayers: [active],
                benchedPlayers: [benched],
                temporarilyOutPlayers: [tempOut],
                existingActiveOrder: [],
                existingBenchOrder: []
            ),
            in: game
        )

        #expect(game.activeOrder == [active.id])
        #expect(game.benchOrder == [benched.id])
        #expect(game.temporarilyOut == [tempOut.id])
    }

    @Test func seedFromLegacyStatusPreservesExistingOrderManagerOrder() throws {
        let context = try makeGameManagerTestContext()
        let playerA = Player(name: "A")
        let playerB = Player(name: "B")
        let game = Game()
        context.insert(playerA)
        context.insert(playerB)
        context.insert(game)
        let manager = GameManager(context: context)

        manager.seedFromLegacyStatus(
            LegacyRotationSnapshot(
                activePlayers: [playerA, playerB],
                benchedPlayers: [],
                temporarilyOutPlayers: [],
                existingActiveOrder: [playerB.id, playerA.id],
                existingBenchOrder: []
            ),
            in: game
        )

        #expect(game.activeOrder == [playerB.id, playerA.id])
    }

    @Test func seedFromLegacyStatusCarriesOverTotalPlayTimeForBenchedPlayer() throws {
        let context = try makeGameManagerTestContext()
        let benched = Player(name: "Benched", totalPlayTime: 180)
        let game = Game()
        context.insert(benched)
        context.insert(game)
        let manager = GameManager(context: context)

        manager.seedFromLegacyStatus(
            LegacyRotationSnapshot(
                activePlayers: [],
                benchedPlayers: [benched],
                temporarilyOutPlayers: [],
                existingActiveOrder: [],
                existingBenchOrder: []
            ),
            in: game
        )

        let total = manager.totalPlayTime(playerId: benched.id, in: game)
        #expect(abs(total - 180) < 0.01)
    }

    @Test func seedFromLegacyStatusCarriesOverBothPriorTotalAndCurrentSegmentForActivePlayer() throws {
        let context = try makeGameManagerTestContext()
        let now = Date()
        let active = Player(name: "Active", totalPlayTime: 120, activatedAtDate: now.addingTimeInterval(-30))
        let game = Game()
        context.insert(active)
        context.insert(game)
        let manager = GameManager(context: context)

        manager.seedFromLegacyStatus(
            LegacyRotationSnapshot(
                activePlayers: [active],
                benchedPlayers: [],
                temporarilyOutPlayers: [],
                existingActiveOrder: [],
                existingBenchOrder: []
            ),
            in: game
        )

        let currentDuration = manager.currentPlayDuration(playerId: active.id, in: game, now: now)
        let total = manager.totalPlayTime(playerId: active.id, in: game, now: now)
        #expect(abs(currentDuration - 30) < 0.01)
        #expect(abs(total - 150) < 0.01)
    }

    @Test func seedFromLegacyStatusCreatesNoStintForPlayerWithNoPriorPlayTime() throws {
        let context = try makeGameManagerTestContext()
        let benched = Player(name: "Fresh")
        let game = Game()
        context.insert(benched)
        context.insert(game)
        let manager = GameManager(context: context)

        manager.seedFromLegacyStatus(
            LegacyRotationSnapshot(
                activePlayers: [],
                benchedPlayers: [benched],
                temporarilyOutPlayers: [],
                existingActiveOrder: [],
                existingBenchOrder: []
            ),
            in: game
        )

        #expect((game.stints ?? []).isEmpty)
    }
}
