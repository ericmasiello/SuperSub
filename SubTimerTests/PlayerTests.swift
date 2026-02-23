//
//  PlayerTests.swift
//  SubTimerTests
//
//  Created by Eric Masiello on 2/13/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct PlayerTests {
    @Test func playerInitialization() {
        let player = Player(name: "John Doe")

        #expect(player.name == "John Doe")
        #expect(player.currentPlayDuration == 0)
        #expect(player.totalPlayTime == 0)
        #expect(player.status == .benched)
        #expect(player.sortOrder == 0)
    }

    @Test func playerStatusChanges() {
        let player = Player(name: "Jane Smith")

        player.status = .active
        #expect(player.status == .active)

        player.status = .temporarilyOut
        #expect(player.status == .temporarilyOut)

        player.status = .benched
        #expect(player.status == .benched)
    }

    @Test func playerTimeTracking() {
        let player = Player(name: "Test Player")

        player.currentPlayDuration = 180 // 3 minutes
        #expect(player.currentPlayDuration == 180)

        player.totalPlayTime = 600 // 10 minutes
        #expect(player.totalPlayTime == 600)
    }

    @Test func singlePlayer() {
        let config = AppConfiguration(activePlayersCount: 1)

        #expect(config.isValid(playerCount: 1) == true)

        let player = Player(name: "Solo Player")
        player.status = .active

        #expect(player.status == .active)
    }

    @Test func playerPlayTimeAccumulation() {
        let player = Player(name: "Test Player")

        // Simulate first shift: 3 minutes
        player.currentPlayDuration = 180
        player.totalPlayTime += player.currentPlayDuration
        player.currentPlayDuration = 0

        #expect(player.totalPlayTime == 180)
        #expect(player.currentPlayDuration == 0)

        // Simulate second shift: 2 minutes
        player.currentPlayDuration = 120
        player.totalPlayTime += player.currentPlayDuration
        player.currentPlayDuration = 0

        #expect(player.totalPlayTime == 300)
        #expect(player.currentPlayDuration == 0)
    }

    @Test func findLongestPlayingPlayer() {
        let player1 = Player(name: "Player 1")
        player1.currentPlayDuration = 120
        player1.status = .active

        let player2 = Player(name: "Player 2")
        player2.currentPlayDuration = 180
        player2.status = .active

        let player3 = Player(name: "Player 3")
        player3.currentPlayDuration = 90
        player3.status = .active

        let activePlayers = [player1, player2, player3]
        let longest = activePlayers.max(by: { $0.currentPlayDuration < $1.currentPlayDuration })

        #expect(longest?.name == "Player 2")
        #expect(longest?.currentPlayDuration == 180)
    }

    @Test func playerSortOrder() {
        let player1 = Player(name: "First", sortOrder: 0)
        let player2 = Player(name: "Second", sortOrder: 1)
        let player3 = Player(name: "Third", sortOrder: 2)

        let players = [player2, player3, player1]
        let sorted = players.sorted(by: { $0.sortOrder < $1.sortOrder })

        #expect(sorted[0].name == "First")
        #expect(sorted[1].name == "Second")
        #expect(sorted[2].name == "Third")
    }

    @Test func equalPlayTimeDistribution() {
        // Create 4 players
        let players = (1 ... 4).map { Player(name: "Player \($0)") }

        // Simulate equal play time
        for player in players {
            player.totalPlayTime = 300 // 5 minutes each
        }

        let totalTime = players.reduce(0.0) { $0 + $1.totalPlayTime }
        let averageTime = totalTime / Double(players.count)

        // Check each player is within 10% of average
        for player in players {
            let variance = abs(player.totalPlayTime - averageTime) / averageTime
            #expect(variance <= 0.1) // Within 10%
        }
    }

    @Test func unfairPlayTimeDetection() {
        let player1 = Player(name: "Player 1")
        player1.totalPlayTime = 500 // 8:20

        let player2 = Player(name: "Player 2")
        player2.totalPlayTime = 200 // 3:20

        let totalTime = player1.totalPlayTime + player2.totalPlayTime
        let averageTime = totalTime / 2.0

        let variance1 = abs(player1.totalPlayTime - averageTime) / averageTime
        let variance2 = abs(player2.totalPlayTime - averageTime) / averageTime

        // These players have >10% variance (unfair distribution)
        #expect(variance1 > 0.1)
        #expect(variance2 > 0.1)
    }
}
