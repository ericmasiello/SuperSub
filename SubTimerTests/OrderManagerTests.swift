//
//  OrderManagerTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 7/29/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

/// Behavior shared by every role-scoped order-tracking instance (Bench, Active).
/// Parameterized over `PlayerOrderRole` so both roles stay covered by one suite,
/// per ADR-0004 (order lives in dedicated records, not on `Player`).
struct OrderManagerTests {
    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func initialState(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        #expect(manager.role == role)
        #expect(manager.isEmpty)
        #expect(manager.nextPlayer == nil)
        #expect(manager.playerOrder.isEmpty)
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func addPlayer(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()
        let id2 = UUID()

        manager.addPlayer(id1)
        #expect(manager.count == 1)
        #expect(manager.playerOrder == [id1])

        manager.addPlayer(id2)
        #expect(manager.count == 2)
        #expect(manager.playerOrder == [id1, id2])
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func addPlayerIgnoresDuplicates(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id1)
        #expect(manager.count == 1)
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func removePlayer(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)
        manager.addPlayer(id3)

        manager.removePlayer(id2)
        #expect(manager.count == 2)
        #expect(manager.playerOrder == [id1, id3])
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func removePlayerNotPresent(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()

        manager.addPlayer(id1)
        manager.removePlayer(UUID())
        #expect(manager.count == 1)
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func movePlayer(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)
        manager.addPlayer(id3)

        manager.movePlayer(id3, to: 0)
        #expect(manager.playerOrder == [id3, id1, id2])
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func movePlayerToEnd(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)
        manager.addPlayer(id3)

        manager.movePlayer(id1, to: 2)
        #expect(manager.playerOrder == [id2, id3, id1])
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func movePlayerNotPresent(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()

        manager.addPlayer(id1)
        manager.movePlayer(UUID(), to: 0)
        #expect(manager.playerOrder == [id1])
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func insertPlayer(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)

        manager.insertPlayer(id3, at: 1)
        #expect(manager.playerOrder == [id1, id3, id2])
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func insertPlayerIgnoresDuplicates(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()

        manager.addPlayer(id1)
        manager.insertPlayer(id1, at: 0)
        #expect(manager.count == 1)
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func insertPlayerClampsIndex(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()
        let id2 = UUID()

        manager.addPlayer(id1)
        manager.insertPlayer(id2, at: 100)
        #expect(manager.playerOrder == [id1, id2])
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func position(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()
        let id2 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)

        #expect(manager.position(of: id1) == 0)
        #expect(manager.position(of: id2) == 1)
        #expect(manager.position(of: UUID()) == nil)
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func nextPlayerReturnsFirstInOrder(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        let id1 = UUID()
        let id2 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)
        #expect(manager.nextPlayer == id1)

        manager.movePlayer(id2, to: 0)
        #expect(manager.nextPlayer == id2)
    }

    @Test(arguments: [PlayerOrderRole.bench, PlayerOrderRole.active])
    func clear(role: PlayerOrderRole) {
        let manager = OrderManager(role: role)
        manager.addPlayer(UUID())
        manager.addPlayer(UUID())
        manager.addPlayer(UUID())

        manager.clear()
        #expect(manager.isEmpty)
        #expect(manager.playerOrder.isEmpty)
    }

    @Test func roleDistinguishesInstances() {
        let bench = OrderManager(role: .bench)
        let active = OrderManager(role: .active)
        let id1 = UUID()

        bench.addPlayer(id1)

        #expect(bench.role == .bench)
        #expect(active.role == .active)
        #expect(bench.count == 1)
        #expect(active.isEmpty)
    }
}
