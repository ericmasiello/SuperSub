//
//  TeamTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct TeamTests {
    @Test func teamInitialization() {
        let team = Team(name: "Warriors", sport: "Soccer")

        #expect(team.name == "Warriors")
        #expect(team.sport == "Soccer")
        #expect(team.preferredPlayTimeSeconds == 180)
        #expect(team.activePlayersCount == 4)
        #expect(team.rosterMemberships == nil)
        #expect(team.games == nil)
    }

    @Test func teamCustomDefaults() {
        let team = Team(
            name: "Sharks",
            sport: "Basketball",
            preferredPlayTimeSeconds: 240,
            activePlayersCount: 5
        )

        #expect(team.preferredPlayTimeSeconds == 240)
        #expect(team.activePlayersCount == 5)
    }
}
