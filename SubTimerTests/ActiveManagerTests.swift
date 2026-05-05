//
//  ActiveManagerTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 5/5/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct ActiveManagerTests {
    @Test func initialState() {
        let manager = ActiveManager()
        #expect(manager.count == 0)
        #expect(manager.nextPlayer == nil)
        #expect(manager.playerOrder.isEmpty)
    }

    @Test func addPlayer() {
        let manager = ActiveManager()
        let id1 = UUID()
        let id2 = UUID()

        manager.addPlayer(id1)
        #expect(manager.count == 1)
        #expect(manager.playerOrder == [id1])

        manager.addPlayer(id2)
        #expect(manager.count == 2)
        #expect(manager.playerOrder == [id1, id2])
    }

    @Test func addPlayerIgnoresDuplicates() {
        let manager = ActiveManager()
        let id1 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id1)
        #expect(manager.count == 1)
    }

    @Test func removePlayer() {
        let manager = ActiveManager()
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

    @Test func removePlayerNotPresent() {
        let manager = ActiveManager()
        let id1 = UUID()

        manager.addPlayer(id1)
        manager.removePlayer(UUID())
        #expect(manager.count == 1)
    }

    @Test func movePlayer() {
        let manager = ActiveManager()
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)
        manager.addPlayer(id3)

        manager.movePlayer(id3, to: 0)
        #expect(manager.playerOrder == [id3, id1, id2])
    }

    @Test func movePlayerToEnd() {
        let manager = ActiveManager()
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)
        manager.addPlayer(id3)

        manager.movePlayer(id1, to: 2)
        #expect(manager.playerOrder == [id2, id3, id1])
    }

    @Test func movePlayerNotPresent() {
        let manager = ActiveManager()
        let id1 = UUID()

        manager.addPlayer(id1)
        manager.movePlayer(UUID(), to: 0)
        #expect(manager.playerOrder == [id1])
    }

    @Test func insertPlayer() {
        let manager = ActiveManager()
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)

        manager.insertPlayer(id3, at: 1)
        #expect(manager.playerOrder == [id1, id3, id2])
    }

    @Test func insertPlayerIgnoresDuplicates() {
        let manager = ActiveManager()
        let id1 = UUID()

        manager.addPlayer(id1)
        manager.insertPlayer(id1, at: 0)
        #expect(manager.count == 1)
    }

    @Test func insertPlayerClampsIndex() {
        let manager = ActiveManager()
        let id1 = UUID()
        let id2 = UUID()

        manager.addPlayer(id1)
        manager.insertPlayer(id2, at: 100)
        #expect(manager.playerOrder == [id1, id2])
    }

    @Test func position() {
        let manager = ActiveManager()
        let id1 = UUID()
        let id2 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)

        #expect(manager.position(of: id1) == 0)
        #expect(manager.position(of: id2) == 1)
        #expect(manager.position(of: UUID()) == nil)
    }

    @Test func nextPlayerReturnsFirstInOrder() {
        let manager = ActiveManager()
        let id1 = UUID()
        let id2 = UUID()

        manager.addPlayer(id1)
        manager.addPlayer(id2)
        #expect(manager.nextPlayer == id1)

        manager.movePlayer(id2, to: 0)
        #expect(manager.nextPlayer == id2)
    }

    @Test func clear() {
        let manager = ActiveManager()
        manager.addPlayer(UUID())
        manager.addPlayer(UUID())
        manager.addPlayer(UUID())

        manager.clear()
        #expect(manager.count == 0)
        #expect(manager.playerOrder.isEmpty)
    }
}
