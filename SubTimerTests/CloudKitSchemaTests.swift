//
//  CloudKitSchemaTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

/// Verifies the full schema — the existing `Player`/`AppConfiguration`/
/// `Session`/`OrderManager` types plus the new, dormant
/// `Team`/`RosterMembership`/`Game`/`Stint` types from #57 — is
/// CloudKit-compatible: no `@Attribute(.unique)`, no non-optional
/// relationships, no unsupported value types.
///
/// This uses an in-memory, dev-only `ModelConfiguration` purely to exercise
/// SwiftData's CloudKit-compatibility validation at container-init time.
/// No real CloudKit container is contacted, no data is synced, and this is
/// not the app's shipped/production configuration — see
/// docs/adr/0001-local-only-persistence-no-cloudkit.md, which this test
/// does not change.
struct CloudKitSchemaTests {
    @Test func fullSchemaInitializesUnderCloudKitConfiguration() throws {
        let schema = Schema([
            Player.self,
            AppConfiguration.self,
            Session.self,
            OrderManager.self,
            Team.self,
            RosterMembership.self,
            Game.self,
            Stint.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .private("iCloud.com.synbydesign.SubTimer")
        )

        #expect(throws: Never.self) {
            _ = try ModelContainer(for: schema, configurations: [configuration])
        }
    }
}
