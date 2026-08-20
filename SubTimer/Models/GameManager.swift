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

/// The old `Player.status`/`OrderManager`-driven rotation state, captured as
/// input to `GameManager.seedFromLegacyStatus`. These five values only ever
/// travel together, for that one purpose — see issue #60.
struct LegacyRotationSnapshot {
    let activePlayers: [Player]
    let benchedPlayers: [Player]
    let temporarilyOutPlayers: [Player]
    let existingActiveOrder: [UUID]
    let existingBenchOrder: [UUID]
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

    /// Resolves which `RotationBucket` `playerId` currently occupies in `game`.
    /// Defaults to `.benched` when the player is in none of the three buckets
    /// (e.g. a roster player never yet transitioned into this `Game`'s
    /// rotation) — matching `Player.defaultStatus`'s old-model default, so a
    /// player's very first appearance renders the same way under both models.
    func status(playerId: UUID, in game: Game) -> RotationBucket {
        if game.activeOrder.contains(playerId) {
            return .active
        }
        if game.temporarilyOut.contains(playerId) {
            return .temporarilyOut
        }
        return .benched
    }

    /// Replaces `bucket`'s order in `game` with `playerIds`, without changing
    /// bucket membership — the caller is responsible for passing the same
    /// membership, just reordered (e.g. drag-to-reorder). A `.temporarilyOut`
    /// bucket is a no-op, since `Game.temporarilyOut` is an unordered `Set`.
    /// Kept alongside `transition` so `Game.activeOrder`/`benchOrder` still
    /// only ever change through `GameManager`.
    func setOrder(_ playerIds: [UUID], for bucket: RotationBucket, in game: Game) {
        switch bucket {
        case .active:
            game.activeOrder = playerIds
        case .benched:
            game.benchOrder = playerIds
        case .temporarilyOut:
            break
        }
    }

    /// One-time migration bridge (see issue #60): seeds a freshly-created,
    /// history-less `game`'s bucket membership and `Stint`s from the old
    /// `Player.status`-driven model, so an in-progress rotation (or a
    /// `--uitesting` fixture launch) carries over exactly instead of
    /// resetting the first time `TimerView` starts operating on `Game`. Not
    /// part of the ordinary `transition`/substitution API — only ever
    /// called once, immediately after `game` is created.
    ///
    /// `snapshot.existingActiveOrder`/`existingBenchOrder` (typically the
    /// legacy `OrderManager.playerOrder`) are preserved for players present
    /// in each, so a coach's existing custom order survives. Each player's
    /// prior `totalPlayTime` becomes a closed, synthetic `Stint` (only its
    /// duration matters — `totalPlayTime`/`currentPlayDuration` are always
    /// derived by summing `Stint`s, never by a `Stint`'s actual dates); an
    /// `.active` player additionally gets a second, open `Stint` starting
    /// at their existing `activatedAtDate`, so their current segment's
    /// elapsed time carries over too.
    func seedFromLegacyStatus(_ snapshot: LegacyRotationSnapshot, in game: Game) {
        game.activeOrder = preservingOrder(of: snapshot.activePlayers, matching: snapshot.existingActiveOrder)
        game.benchOrder = preservingOrder(of: snapshot.benchedPlayers, matching: snapshot.existingBenchOrder)
        game.temporarilyOut = Set(snapshot.temporarilyOutPlayers.map { $0.id })

        var stints: [Stint] = []
        for player in snapshot.benchedPlayers + snapshot.temporarilyOutPlayers {
            if let historicalStint = historicalStint(for: player, in: game) {
                stints.append(historicalStint)
            }
        }
        for player in snapshot.activePlayers {
            if let historicalStint = historicalStint(for: player, in: game) {
                stints.append(historicalStint)
            }
            stints.append(Stint(startDate: player.activatedAtDate, player: player, game: game))
        }

        for stint in stints {
            context.insert(stint)
        }
        game.stints = stints
    }

    /// A closed `Stint` whose duration equals `player.totalPlayTime`, or
    /// `nil` when there's nothing to carry over. Start/end dates are
    /// otherwise arbitrary, ending at `Date()` so it never reads as
    /// still-open.
    private func historicalStint(for player: Player, in game: Game) -> Stint? {
        guard player.totalPlayTime > 0 else { return nil }
        let end = Date()
        return Stint(startDate: end.addingTimeInterval(-player.totalPlayTime), endDate: end, player: player, game: game)
    }

    private func preservingOrder(of matchingPlayers: [Player], matching existingOrder: [UUID]) -> [UUID] {
        let matchedIds = Set(matchingPlayers.map { $0.id })
        let ordered = existingOrder.filter { matchedIds.contains($0) }
        let orderedSet = Set(ordered)
        let remaining = matchingPlayers.filter { !orderedSet.contains($0.id) }.map { $0.id }
        return ordered + remaining
    }
}
