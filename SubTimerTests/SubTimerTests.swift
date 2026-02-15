//
//  SubTimerTests.swift
//  SubTimerTests
//
//  Created by Eric Masiello on 2/13/26.
//

import Foundation
import Testing
import SwiftData
@testable import SubTimer

struct SubTimerTests {

    // MARK: - Player Tests

    @Test func testPlayerInitialization() async throws {
        let player = Player(name: "John Doe")

        #expect(player.name == "John Doe")
        #expect(player.currentPlayDuration == 0)
        #expect(player.totalPlayTime == 0)
        #expect(player.status == .benched)
        #expect(player.sortOrder == 0)
    }

    @Test func testPlayerStatusChanges() async throws {
        let player = Player(name: "Jane Smith")

        player.status = .active
        #expect(player.status == .active)

        player.status = .temporarilyOut
        #expect(player.status == .temporarilyOut)

        player.status = .benched
        #expect(player.status == .benched)
    }

    @Test func testPlayerTimeTracking() async throws {
        let player = Player(name: "Test Player")

        player.currentPlayDuration = 180 // 3 minutes
        #expect(player.currentPlayDuration == 180)

        player.totalPlayTime = 600 // 10 minutes
        #expect(player.totalPlayTime == 600)
    }

    // MARK: - AppConfiguration Tests

    @Test func testConfigurationDefaults() async throws {
        let config = AppConfiguration()

        #expect(config.preferredPlayTimeSeconds == 180) // 3 minutes
        #expect(config.activePlayersCount == 4)
    }

    @Test func testConfigurationFormatting() async throws {
        let config = AppConfiguration(preferredPlayTimeSeconds: 210)

        #expect(config.preferredPlayTimeFormatted == "3:30")

        config.preferredPlayTimeSeconds = 60
        #expect(config.preferredPlayTimeFormatted == "1:00")

        config.preferredPlayTimeSeconds = 300
        #expect(config.preferredPlayTimeFormatted == "5:00")
    }

    @Test func testConfigurationValidation() async throws {
        let config = AppConfiguration(activePlayersCount: 4)

        #expect(config.isValid(playerCount: 10) == true)
        #expect(config.isValid(playerCount: 4) == true)
        #expect(config.isValid(playerCount: 3) == false)
        #expect(config.isValid(playerCount: 0) == false)
    }

    @Test func testConfigurationBoundaries() async throws {
        let config = AppConfiguration()

        // Test minimum time (30 seconds)
        config.preferredPlayTimeSeconds = 30
        #expect(config.preferredPlayTimeSeconds == 30)
        #expect(config.preferredPlayTimeFormatted == "0:30")

        // Test maximum time (30 minutes = 1800 seconds)
        config.preferredPlayTimeSeconds = 1800
        #expect(config.preferredPlayTimeSeconds == 1800)
        #expect(config.preferredPlayTimeFormatted == "30:00")
    }

    // MARK: - Session Tests

    @Test func testSessionInitialization() async throws {
        let session = Session()

        #expect(session.duration == 0)
        #expect(session.substitutionCount == 0)
        #expect(session.isActive == true)
        #expect(session.playerNames.isEmpty)
    }

    @Test func testSessionIsActive() async throws {
        let session = Session()

        #expect(session.isActive == true)

        session.endDate = Date()
        #expect(session.isActive == false)
    }

    @Test func testSessionDurationFormatting() async throws {
        let session = Session()

        // Test seconds only
        session.duration = 45
        #expect(session.formattedDuration == "0:45")

        // Test minutes and seconds
        session.duration = 185 // 3:05
        #expect(session.formattedDuration == "3:05")

        // Test hours, minutes, and seconds
        session.duration = 3665 // 1:01:05
        #expect(session.formattedDuration == "1:01:05")
    }

    @Test func testSessionTracking() async throws {
        let session = Session(
            preferredPlayTimeSeconds: 180,
            activePlayersCount: 4,
            playerNames: ["Player 1", "Player 2", "Player 3", "Player 4"]
        )

        #expect(session.preferredPlayTimeSeconds == 180)
        #expect(session.activePlayersCount == 4)
        #expect(session.playerNames.count == 4)

        session.substitutionCount = 5
        #expect(session.substitutionCount == 5)
    }

    // MARK: - Player Status Enum Tests

    @Test func testPlayerStatusEnum() async throws {
        let activeStatus = PlayerStatus.active
        let benchedStatus = PlayerStatus.benched
        let tempOutStatus = PlayerStatus.temporarilyOut

        #expect(activeStatus.rawValue == "active")
        #expect(benchedStatus.rawValue == "benched")
        #expect(tempOutStatus.rawValue == "temporarilyOut")
    }

    // MARK: - Edge Case Tests

    @Test func testZeroPlayers() async throws {
        let config = AppConfiguration(activePlayersCount: 4)

        #expect(config.isValid(playerCount: 0) == false)
    }

    @Test func testSinglePlayer() async throws {
        let config = AppConfiguration(activePlayersCount: 1)

        #expect(config.isValid(playerCount: 1) == true)

        let player = Player(name: "Solo Player")
        player.status = .active

        #expect(player.status == .active)
    }

    @Test func testPlayerCountLessThanActiveSpots() async throws {
        let config = AppConfiguration(activePlayersCount: 5)

        // With only 3 players, configuration should be invalid
        #expect(config.isValid(playerCount: 3) == false)

        // Adjust active players to match
        config.activePlayersCount = 3
        #expect(config.isValid(playerCount: 3) == true)
    }

    @Test func testPreferredTimeZero() async throws {
        let config = AppConfiguration(preferredPlayTimeSeconds: 0)

        #expect(config.preferredPlayTimeSeconds == 0)
        #expect(config.preferredPlayTimeFormatted == "0:00")
    }

    // MARK: - Substitution Logic Tests

    @Test func testPlayerPlayTimeAccumulation() async throws {
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

    @Test func testFindLongestPlayingPlayer() async throws {
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

    @Test func testPlayerSortOrder() async throws {
        let player1 = Player(name: "First", sortOrder: 0)
        let player2 = Player(name: "Second", sortOrder: 1)
        let player3 = Player(name: "Third", sortOrder: 2)

        let players = [player2, player3, player1]
        let sorted = players.sorted(by: { $0.sortOrder < $1.sortOrder })

        #expect(sorted[0].name == "First")
        #expect(sorted[1].name == "Second")
        #expect(sorted[2].name == "Third")
    }

    // MARK: - Time Formatting Tests

    @Test func testTimeIntervalFormatting() async throws {
        func formatTime(_ timeInterval: TimeInterval) -> String {
            let hours = Int(timeInterval) / 3600
            let minutes = (Int(timeInterval) % 3600) / 60
            let seconds = Int(timeInterval) % 60

            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }

        #expect(formatTime(0) == "0:00")
        #expect(formatTime(30) == "0:30")
        #expect(formatTime(60) == "1:00")
        #expect(formatTime(90) == "1:30")
        #expect(formatTime(180) == "3:00")
        #expect(formatTime(3665) == "1:01:05")
    }

    // MARK: - Configuration Persistence Tests

    @Test func testConfigurationModification() async throws {
        let config = AppConfiguration()
        let originalDate = config.lastModifiedDate

        // Small delay to ensure date changes
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        config.preferredPlayTimeSeconds = 240
        config.lastModifiedDate = Date()

        #expect(config.preferredPlayTimeSeconds == 240)
        #expect(config.lastModifiedDate > originalDate)
    }

    // MARK: - Session History Tests

    @Test func testSessionCompletion() async throws {
        let startDate = Date()
        let session = Session(startDate: startDate)

        #expect(session.isActive == true)

        // Simulate 10 minutes of play
        session.duration = 600
        session.substitutionCount = 3

        // End session
        session.endDate = Date()

        #expect(session.isActive == false)
        #expect(session.duration == 600)
        #expect(session.substitutionCount == 3)
    }

    // MARK: - Fair Play Distribution Tests

    @Test func testEqualPlayTimeDistribution() async throws {
        // Create 4 players
        let players = (1...4).map { Player(name: "Player \($0)") }

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

    @Test func testUnfairPlayTimeDetection() async throws {
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
