//
//  AppConfigurationTests.swift
//  SubTimerTests
//
//  Created by Eric Masiello on 2/13/26.
//

import Foundation
import SwiftData
import Testing

@testable import SubTimer

struct AppConfigurationTests {

  @Test func testConfigurationDefaults() async throws {
    let config = AppConfiguration()

    #expect(config.preferredPlayTimeSeconds == 180)  // 3 minutes
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

  @Test func testZeroPlayers() async throws {
    let config = AppConfiguration(activePlayersCount: 4)

    #expect(config.isValid(playerCount: 0) == false)
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

  @Test func testConfigurationModification() async throws {
    let config = AppConfiguration()
    let originalDate = config.lastModifiedDate

    // Small delay to ensure date changes
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

    config.preferredPlayTimeSeconds = 240
    config.lastModifiedDate = Date()

    #expect(config.preferredPlayTimeSeconds == 240)
    #expect(config.lastModifiedDate > originalDate)
  }
}
