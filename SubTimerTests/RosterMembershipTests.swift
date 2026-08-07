//
//  RosterMembershipTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct RosterMembershipTests {
    @Test func rosterMembershipInitialization() {
        let membership = RosterMembership()

        #expect(membership.position == nil)
        #expect(membership.player == nil)
        #expect(membership.team == nil)
    }

    @Test func rosterMembershipWithPlayerAndTeam() {
        let player = Player(name: "Alex")
        let team = Team(name: "Warriors", sport: "Soccer")
        let membership = RosterMembership(position: "Forward", player: player, team: team)

        #expect(membership.position == "Forward")
        #expect(membership.player === player)
        #expect(membership.team === team)
    }
}
