//
//  GameManager.swift
//  SubTimer
//
//  Created by SubTimer on 8/7/26.
//

import Foundation
import SwiftData

/// The three mutually-exclusive rotation buckets a player can occupy within a `Game`.
/// Distinct from `PlayerStatus` (see `Player.swift`): `PlayerStatus` backs the in-use
/// `OrderManager`-based rotation, while `RotationBucket` backs the dormant `Game`
/// schema from #57. They share case names by coincidence of domain vocabulary, not
/// by design — see docs/architecture/data-model.md for the in-use/dormant split.
enum RotationBucket: String, Codable {
    case active = "active"
    case benched = "benched"
    case temporarilyOut = "temporarilyOut"
}

/// Errors raised by `GameManager` when a requested mutation can't be performed safely.
enum GameManagerError: Error, Equatable {
    /// `transition` needed to open a new `Stint` for a player but no `Player` with
    /// that id exists in the context.
    case playerNotFound
    /// `manualSubstitution`'s outgoing player isn't currently in `activeOrder`.
    case outgoingPlayerNotActive
    /// `manualSubstitution`'s incoming player is already in `activeOrder`.
    case incomingPlayerAlreadyActive
}

/// The result of a successful substitution: who came out, who came in.
struct Substitution: Equatable {
    let outgoingPlayerId: UUID
    let incomingPlayerId: UUID
}

/// Sole mutator of `Game.activeOrder`/`benchOrder`/`temporarilyOut` and sole
/// opener/closer of `Stint`s. Plain (non-`@Model`) class — see #58: nothing in the
/// app calls this yet, it operates purely on the dormant schema from #57 via an
/// injected `ModelContext`.
final class GameManager {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Moves `playerId` into `bucket`, purging it from the other two buckets first so
    /// a player can never be a member of more than one bucket at once. Opens a new
    /// `Stint` when entering `.active` from elsewhere; closes the currently-open
    /// `Stint` when leaving `.active`. Both the bucket-membership change and the
    /// `Stint` open/close happen atomically within this single call.
    func transition(playerId: UUID, to bucket: RotationBucket, in game: Game) throws {
        let wasActive = game.activeOrder.contains(playerId)
        let entersActive = bucket == .active && !wasActive

        // Resolve the `Player` before mutating anything: if this throws, the buckets
        // and Stints must be left exactly as they were, not partially updated.
        let enteringPlayer = entersActive ? try fetchPlayer(id: playerId) : nil
        if entersActive && enteringPlayer == nil {
            throw GameManagerError.playerNotFound
        }

        game.activeOrder.removeAll { $0 == playerId }
        game.benchOrder.removeAll { $0 == playerId }
        game.temporarilyOut.remove(playerId)

        switch bucket {
        case .active:
            game.activeOrder.append(playerId)
        case .benched:
            game.benchOrder.append(playerId)
        case .temporarilyOut:
            game.temporarilyOut.insert(playerId)
        }

        if let enteringPlayer {
            openNewStint(for: enteringPlayer, in: game)
        } else if bucket != .active && wasActive {
            closeOpenStint(for: playerId, in: game)
        }
    }

    private func openNewStint(for player: Player, in game: Game, at date: Date = Date()) {
        let stint = Stint(startDate: date, player: player, game: game)
        context.insert(stint)
        if game.stints == nil {
            game.stints = []
        }
        game.stints?.append(stint)
    }

    private func closeOpenStint(for playerId: UUID, in game: Game, at date: Date = Date()) {
        guard let openStint = findOpenStint(for: playerId, in: game) else { return }
        openStint.endDate = date
    }

    private func findOpenStint(for playerId: UUID, in game: Game) -> Stint? {
        game.stints?.first { $0.player?.id == playerId && $0.endDate == nil }
    }

    private func fetchPlayer(id: UUID) throws -> Player? {
        let descriptor = FetchDescriptor<Player>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    /// Swaps the longest-serving `.active` player (earliest-`startDate` open `Stint`)
    /// for the Next Up bench player, incrementing `substitutionCount`. Returns the
    /// pairing that was made, or `nil` (leaving state untouched) when the bench has
    /// no Next Up player.
    func automaticSubstitution(game: Game) throws -> Substitution? {
        guard let incomingPlayerId = game.benchOrder.first else { return nil }
        guard let outgoingPlayerId = longestServingActivePlayerId(in: game) else { return nil }

        // Validate the incoming player exists before mutating anything: a swap is
        // two `transition` calls with no rollback, so if the second one threw after
        // the first succeeded, the outgoing player would be left benched with no
        // incoming replacement.
        guard try fetchPlayer(id: incomingPlayerId) != nil else {
            throw GameManagerError.playerNotFound
        }

        try transition(playerId: outgoingPlayerId, to: .benched, in: game)
        try transition(playerId: incomingPlayerId, to: .active, in: game)
        game.substitutionCount += 1

        return Substitution(outgoingPlayerId: outgoingPlayerId, incomingPlayerId: incomingPlayerId)
    }

    /// Swaps a coach-specified `outgoingPlayerId` (must currently be `.active`) for
    /// `incomingPlayerId` (must not already be `.active`), incrementing
    /// `substitutionCount`. Throws rather than swapping nonsensical pairings.
    func manualSubstitution(outgoing outgoingPlayerId: UUID, incoming incomingPlayerId: UUID, game: Game) throws {
        guard game.activeOrder.contains(outgoingPlayerId) else {
            throw GameManagerError.outgoingPlayerNotActive
        }
        guard !game.activeOrder.contains(incomingPlayerId) else {
            throw GameManagerError.incomingPlayerAlreadyActive
        }
        guard try fetchPlayer(id: incomingPlayerId) != nil else {
            throw GameManagerError.playerNotFound
        }

        try transition(playerId: outgoingPlayerId, to: .benched, in: game)
        try transition(playerId: incomingPlayerId, to: .active, in: game)
        game.substitutionCount += 1
    }

    private func longestServingActivePlayerId(in game: Game) -> UUID? {
        let openActiveStints = (game.stints ?? []).filter { stint in
            guard stint.endDate == nil, let playerId = stint.player?.id else { return false }
            return game.activeOrder.contains(playerId)
        }
        return openActiveStints.min { $0.startDate < $1.startDate }?.player?.id
    }

    /// Adds `player` to `game`'s bench, with no `RosterMembership` required — an
    /// ad-hoc player can still appear in `benchOrder`/`activeOrder` and accrue
    /// `Stint`s once transitioned to `.active`.
    func addAdHocPlayer(_ player: Player, to game: Game) throws {
        try transition(playerId: player.id, to: .benched, in: game)
    }

    /// The elapsed time of `playerId`'s currently-open `Stint` in `game`, or `0` if
    /// they have none open. Never cached — always derived by locating the open
    /// `Stint`.
    func currentPlayDuration(playerId: UUID, in game: Game, now: Date = Date()) -> TimeInterval {
        guard let openStint = findOpenStint(for: playerId, in: game) else { return 0 }
        return now.timeIntervalSince(openStint.startDate)
    }

    /// `playerId`'s total play time in `game`, derived by summing every `Stint`
    /// belonging to them — closed `Stint`s use their own `endDate`, a still-open one
    /// is measured up to `now`. Never cached redundantly.
    func totalPlayTime(playerId: UUID, in game: Game, now: Date = Date()) -> TimeInterval {
        (game.stints ?? [])
            .filter { $0.player?.id == playerId }
            .reduce(0) { total, stint in
                total + (stint.endDate ?? now).timeIntervalSince(stint.startDate)
            }
    }
}
