//
//  TeamManagerTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/7/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct TeamManagerTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Player.self, Team.self, RosterMembership.self, Game.self, Stint.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func addToRosterCreatesMembership() throws {
        let context = try makeContext()
        let player = Player(name: "Alex")
        let team = Team(name: "Warriors", sport: "Soccer")
        context.insert(player)
        context.insert(team)
        let manager = TeamManager(context: context)

        let membership = try manager.addToRoster(player: player, team: team)

        #expect(membership.player === player)
        #expect(membership.team === team)
    }

    @Test func addToRosterRejectsDuplicateForSamePlayerAndTeam() throws {
        let context = try makeContext()
        let player = Player(name: "Alex")
        let team = Team(name: "Warriors", sport: "Soccer")
        context.insert(player)
        context.insert(team)
        let manager = TeamManager(context: context)

        try manager.addToRoster(player: player, team: team)

        #expect(throws: TeamManagerError.duplicateRosterMembership) {
            try manager.addToRoster(player: player, team: team)
        }
    }

    @Test func addToRosterAllowsSamePlayerOnDifferentTeams() throws {
        let context = try makeContext()
        let player = Player(name: "Alex")
        let teamA = Team(name: "Warriors", sport: "Soccer")
        let teamB = Team(name: "Sharks", sport: "Basketball")
        context.insert(player)
        context.insert(teamA)
        context.insert(teamB)
        let manager = TeamManager(context: context)

        try manager.addToRoster(player: player, team: teamA)
        try manager.addToRoster(player: player, team: teamB)
    }

    @Test func removeFromRosterDeletesMembership() throws {
        let context = try makeContext()
        let player = Player(name: "Alex")
        let team = Team(name: "Warriors", sport: "Soccer")
        context.insert(player)
        context.insert(team)
        let manager = TeamManager(context: context)
        try manager.addToRoster(player: player, team: team)

        try manager.removeFromRoster(player: player, team: team)

        let remaining = try context.fetch(FetchDescriptor<RosterMembership>())
        #expect(remaining.isEmpty)
    }

    @Test func removeFromRosterThrowsWhenNoMembershipExists() throws {
        let context = try makeContext()
        let player = Player(name: "Alex")
        let team = Team(name: "Warriors", sport: "Soccer")
        context.insert(player)
        context.insert(team)
        let manager = TeamManager(context: context)

        #expect(throws: TeamManagerError.rosterMembershipNotFound) {
            try manager.removeFromRoster(player: player, team: team)
        }
    }

    @Test func updatePreferredPositionChangesMembershipPosition() throws {
        let context = try makeContext()
        let player = Player(name: "Alex")
        let team = Team(name: "Warriors", sport: "Soccer")
        context.insert(player)
        context.insert(team)
        let manager = TeamManager(context: context)
        let membership = try manager.addToRoster(player: player, team: team)

        manager.updatePreferredPosition(membership, position: "Forward")

        #expect(membership.position == "Forward")
    }

    @Test func updateDefaultsChangesTeamPreferredPlayTimeAndActivePlayersCount() throws {
        let context = try makeContext()
        let team = Team(name: "Warriors", sport: "Soccer")
        context.insert(team)
        let manager = TeamManager(context: context)

        manager.updateDefaults(team: team, preferredPlayTimeSeconds: 240, activePlayersCount: 5)

        #expect(team.preferredPlayTimeSeconds == 240)
        #expect(team.activePlayersCount == 5)
    }
}
