//
//  SchemaMigrationPlan.swift
//  SubTimer
//
//  Created by SubTimer on 8/17/26.
//

import Foundation
import SwiftData

/// The schema shape prior to #57: `Player`, `AppConfiguration`, `Session`, and
/// `OrderManager` only.
///
/// `AppConfiguration`/`Session`/`OrderManager` reuse the current model classes
/// directly, since their shapes never changed. `Player` needs its own frozen
/// snapshot here instead: the real `Player` class already carries #57's
/// `rosterMemberships`/`stints` relationships into `RosterMembership`/`Stint`,
/// and reusing it as-is would pull those (and, transitively, `Team`/`Game`)
/// into this version's compiled model too — making it indistinguishable from
/// `SchemaV2` and crashing migration with "the current model reference and
/// the next model reference cannot be equal".
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Player.self, AppConfiguration.self, Session.self, OrderManager.self]
    }

    @Model
    final class Player {
        var id = UUID()
        var name: String = ""
        var createdDate = Date()
        var currentPlayDuration: TimeInterval = 0
        var totalPlayTime: TimeInterval = 0
        var status = PlayerStatus.benched
        var sortOrder = 0
        var activatedAtDate = Date()

        init(name: String) {
            self.name = name
        }
    }
}

/// The schema shape from #57 onward: everything in `SchemaV1` plus the
/// dormant `Team`, `RosterMembership`, `Game`, and `Stint` models.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Player.self,
            AppConfiguration.self,
            Session.self,
            OrderManager.self,
            Team.self,
            RosterMembership.self,
            Game.self,
            Stint.self
        ]
    }
}

/// Drives the one-time transform of legacy `Player`/`Session`/`AppConfiguration`
/// rows into the `Team`/`RosterMembership`/`Game` shape added by #57, on
/// `ModelContainer` open. See docs/architecture/data-model.md for the full
/// sequence diagram.
///
/// This purely produces correct rows for later tickets to wire up — no
/// `GameManager`/`TeamManager` involvement, no UI, no behavior change.
enum SubTimerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            try migrateLegacyDataToTeamModel(in: context)
        }
    )
}

/// Auto-creates exactly one `Team` — seeded from the existing `AppConfiguration`
/// singleton, falling back to its static defaults when none exists — a
/// `RosterMembership` (no position) for every existing `Player` into that
/// `Team`, and a `Game` for every existing `Session`, carrying over
/// `startDate`/`endDate`/`duration`/`substitutionCount`/`preferredPlayTimeSeconds`/
/// `activePlayersCount`.
///
/// Guarded by "does any `Team` already exist" *before* creating any row, so
/// running this twice (e.g. app relaunch after a partial/completed migration)
/// never creates a second `Team` or duplicate `RosterMembership`/`Game` rows.
private func migrateLegacyDataToTeamModel(in context: ModelContext) throws {
    guard try context.fetchCount(FetchDescriptor<Team>()) == 0 else {
        return
    }

    let configuration = try context.fetch(FetchDescriptor<AppConfiguration>()).first
    let team = Team(
        name: "",
        sport: "",
        preferredPlayTimeSeconds: configuration?.preferredPlayTimeSeconds
            ?? AppConfiguration.defaultPreferredPlayTimeSeconds,
        activePlayersCount: configuration?.activePlayersCount
            ?? AppConfiguration.defaultActivePlayersCount
    )
    context.insert(team)

    let players = try context.fetch(FetchDescriptor<Player>())
    for player in players {
        context.insert(RosterMembership(player: player, team: team))
    }

    let sessions = try context.fetch(FetchDescriptor<Session>())
    for session in sessions {
        context.insert(
            Game(
                startDate: session.startDate,
                endDate: session.endDate,
                duration: session.duration,
                substitutionCount: session.substitutionCount,
                preferredPlayTimeSeconds: session.preferredPlayTimeSeconds,
                activePlayersCount: session.activePlayersCount,
                team: team
            )
        )
    }

    try context.save()
}
