//
//  SessionTests.swift
//  SubTimerTests
//
//  Created by Eric Masiello on 2/13/26.
//

import Foundation
import SwiftData
import Testing

@testable import SubTimer

struct SessionTests {

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
    session.duration = 185  // 3:05
    #expect(session.formattedDuration == "3:05")

    // Test hours, minutes, and seconds
    session.duration = 3665  // 1:01:05
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
}
