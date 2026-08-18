//
//  DataMigrationTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/17/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

/// Exercises `SubTimerMigrationPlan` end-to-end: a fixture pre-#57 store is
/// seeded under `SchemaV1` alone (no migration plan involved yet, matching
/// what a real pre-#57 install would have on disk), then reopened through the
/// full plan the way `SubTimerApp` does on every launch.
struct DataMigrationTests {
    private func makeStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("DataMigrationTests-\(UUID().uuidString)")
            .appendingPathExtension("sqlite")
    }

    private func removeStore(at url: URL) {
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(
            at: url.deletingPathExtension().appendingPathExtension("sqlite-shm")
        )
        try? FileManager.default.removeItem(
            at: url.deletingPathExtension().appendingPathExtension("sqlite-wal")
        )
    }

    private func seedLegacyStore(at url: URL) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        // Explicitly SchemaV1.Player, not the real (post-#57) `Player`: an
        // unqualified `Player(...)` here would resolve to the top-level class,
        // which carries relationships this schema's compiled model doesn't
        // declare — defeating the point of seeding a genuine pre-#57 store.
        context.insert(SchemaV1.Player(name: "Alice"))
        context.insert(SchemaV1.Player(name: "Bob"))
        context.insert(AppConfiguration(preferredPlayTimeSeconds: 240, activePlayersCount: 6))
        context.insert(Session(
            startDate: Date(timeIntervalSince1970: 1_000),
            endDate: Date(timeIntervalSince1970: 1_900),
            duration: 900,
            substitutionCount: 3,
            preferredPlayTimeSeconds: 240,
            activePlayersCount: 6
        ))

        try context.save()
    }

    private func openMigratedStore(at url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(
            for: schema,
            migrationPlan: SubTimerMigrationPlan.self,
            configurations: [configuration]
        )
    }

    @Test func migratesLegacyPlayersSessionsAndConfigurationIntoNewModel() throws {
        let url = makeStoreURL()
        defer { removeStore(at: url) }
        try seedLegacyStore(at: url)

        let container = try openMigratedStore(at: url)
        let context = ModelContext(container)

        let teams = try context.fetch(FetchDescriptor<Team>())
        #expect(teams.count == 1)
        let team = try #require(teams.first)
        #expect(team.preferredPlayTimeSeconds == 240)
        #expect(team.activePlayersCount == 6)

        let memberships = try context.fetch(FetchDescriptor<RosterMembership>())
        #expect(memberships.count == 2)
        #expect(memberships.allSatisfy { $0.team?.id == team.id })
        #expect(memberships.allSatisfy { $0.position == nil })
        #expect(Set(memberships.compactMap { $0.player?.name }) == ["Alice", "Bob"])

        let games = try context.fetch(FetchDescriptor<Game>())
        #expect(games.count == 1)
        let game = try #require(games.first)
        #expect(game.team?.id == team.id)
        #expect(game.startDate == Date(timeIntervalSince1970: 1_000))
        #expect(game.endDate == Date(timeIntervalSince1970: 1_900))
        #expect(game.duration == 900)
        #expect(game.substitutionCount == 3)
    }

    @Test func reopeningMigratedStoreDoesNotDuplicateRows() throws {
        let url = makeStoreURL()
        defer { removeStore(at: url) }
        try seedLegacyStore(at: url)

        _ = try openMigratedStore(at: url)
        let context = ModelContext(try openMigratedStore(at: url))

        #expect(try context.fetch(FetchDescriptor<Team>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<RosterMembership>()).count == 2)
        #expect(try context.fetch(FetchDescriptor<Game>()).count == 1)
    }

    @Test func seedsTeamDefaultsWhenNoAppConfigurationExists() throws {
        let url = makeStoreURL()
        defer { removeStore(at: url) }

        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let legacyContainer = try ModelContainer(for: schema, configurations: [configuration])
        try ModelContext(legacyContainer).save()

        let context = ModelContext(try openMigratedStore(at: url))
        let team = try #require(try context.fetch(FetchDescriptor<Team>()).first)

        #expect(team.preferredPlayTimeSeconds == AppConfiguration.defaultPreferredPlayTimeSeconds)
        #expect(team.activePlayersCount == AppConfiguration.defaultActivePlayersCount)
    }
}
