//
//  TeamManager.swift
//  SubTimer
//
//  Created by SubTimer on 8/7/26.
//

import Foundation
import SwiftData

/// Errors raised by `TeamManager` when a requested mutation can't be performed safely.
enum TeamManagerError: Error, Equatable {
    /// `addToRoster` would create a second `RosterMembership` for the same
    /// (Player, Team) pair — CloudKit can't enforce this uniqueness at the schema
    /// level, so `TeamManager` enforces it at the app layer instead.
    case duplicateRosterMembership
    /// `removeFromRoster` found no `RosterMembership` for the given (Player, Team).
    case rosterMembershipNotFound
}

/// Sole creator/deleter of `RosterMembership`, enforcing (Player, Team) uniqueness;
/// also owns `Team` default updates. Plain (non-`@Model`) class — see #58: nothing in
/// the app calls this yet, it operates purely on the dormant schema from #57 via an
/// injected `ModelContext`.
final class TeamManager {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Creates a `RosterMembership` linking `player` to `team`, throwing
    /// `.duplicateRosterMembership` if one already exists for that pair.
    @discardableResult
    func addToRoster(player: Player, team: Team) throws -> RosterMembership {
        guard try existingMembership(player: player, team: team) == nil else {
            throw TeamManagerError.duplicateRosterMembership
        }
        let membership = RosterMembership(player: player, team: team)
        context.insert(membership)
        return membership
    }

    /// Deletes the `RosterMembership` linking `player` to `team`, throwing
    /// `.rosterMembershipNotFound` if none exists.
    func removeFromRoster(player: Player, team: Team) throws {
        guard let membership = try existingMembership(player: player, team: team) else {
            throw TeamManagerError.rosterMembershipNotFound
        }
        context.delete(membership)
    }

    /// Updates `membership`'s preferred position.
    func updatePreferredPosition(_ membership: RosterMembership, position: String?) {
        membership.position = position
    }

    /// Updates `team`'s default Preferred Play Time and Active Players Count.
    func updateDefaults(team: Team, preferredPlayTimeSeconds: Int, activePlayersCount: Int) {
        team.preferredPlayTimeSeconds = preferredPlayTimeSeconds
        team.activePlayersCount = activePlayersCount
    }

    private func existingMembership(player: Player, team: Team) throws -> RosterMembership? {
        let playerId = player.id
        let teamId = team.id
        let descriptor = FetchDescriptor<RosterMembership>(
            predicate: #Predicate { $0.player?.id == playerId && $0.team?.id == teamId }
        )
        return try context.fetch(descriptor).first
    }
}
