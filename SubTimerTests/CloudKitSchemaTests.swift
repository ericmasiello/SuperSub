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
/// `Team`/`RosterMembership`/`Game`/`Stint` types from #57 — satisfies the
/// CloudKit *model-shape* rules: no `@Attribute(.unique)`, every relationship
/// optional and inverse-paired, every attribute optional or carrying a
/// default.
///
/// Scope, precisely: setting `cloudKitDatabase` to anything other than `.none`
/// makes `ModelContainer.init` run SwiftData's synchronous CloudKit model
/// validator, which throws on any of the above. That is the whole of what this
/// test covers, and it's the technique Apple engineering recommends for it
/// (Developer Forums 751617: "enable CloudKit temporarily to run the validator
/// against your model. If the ModelContainer initializes the model is
/// compatible").
///
/// What it deliberately does *not* cover: whether iCloud sync actually works.
/// Container provisioning and mirroring setup happen asynchronously in
/// `NSCloudKitMirroringDelegate` after `init` returns and surface only as log
/// output — never as a thrown error — so no test shaped like this one can
/// observe them. Proving real sync needs
/// `NSPersistentCloudKitContainer.initializeCloudKitSchema()` against a
/// provisioned container with a signed-in account, which is not CI-friendly.
/// Nothing here contacts CloudKit, syncs data, or changes the app's shipped
/// local-only configuration (see
/// docs/adr/0001-local-only-persistence-no-cloudkit.md).
///
/// See `CloudKitSchemaNegativeControlTests` for the proof that the assertion
/// below can actually fail.
struct CloudKitSchemaTests {
    /// The app's real iCloud container identifier.
    ///
    /// Inert in these tests: the validator above rejects or accepts a schema on
    /// shape alone and never resolves this string, contacts CloudKit, or
    /// consults entitlements — `SubTimer.entitlements` doesn't even list it
    /// (`com.apple.developer.icloud-container-identifiers` is an empty array),
    /// yet validation still runs. It's spelled out in full rather than
    /// environment-configurable so that if real sync is ever enabled, these
    /// tests already pin the container the app will ship with.
    static let cloudKitContainerIdentifier = "iCloud.com.synbydesign.SubTimer"

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
            cloudKitDatabase: .private(Self.cloudKitContainerIdentifier)
        )

        #expect(throws: Never.self) {
            _ = try ModelContainer(for: schema, configurations: [configuration])
        }
    }
}

// MARK: - Negative control

/// Proves `CloudKitSchemaTests` has teeth.
///
/// A passing `#expect(throws: Never.self)` is only meaningful if the same
/// assertion would *fail* on a CloudKit-incompatible schema. Nothing in that
/// test demonstrates it can: if `cloudKitDatabase` were ever switched to
/// `.none` — or if SwiftData stopped validating for in-memory stores — it would
/// keep passing while checking nothing whatsoever, silently.
///
/// Each probe below violates exactly one CloudKit rule and asserts container
/// init throws under the CloudKit configuration **and** succeeds under a
/// local-only one. The second half is what makes it a control rather than a
/// coincidence: it attributes the rejection to CloudKit validation
/// specifically, instead of to some unrelated defect in the throwaway model.
///
/// All three violations surface as a catchable
/// `SwiftDataError._Error.loadIssueModelContainer`. Note that this validation
/// has regressed before — it escaped as an uncatchable trap rather than a
/// throw on iOS 17.4 (Apple Feedback FB13694972) — so a crash here, rather
/// than a clean failure, is itself a meaningful signal.
struct CloudKitSchemaNegativeControlTests {
    private static func makeContainer(
        for schema: Schema,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: cloudKitDatabase
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func expectRejectedOnlyByCloudKit(
        _ schema: Schema,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(throws: (any Error).self, sourceLocation: sourceLocation) {
            _ = try makeContainer(
                for: schema,
                cloudKitDatabase: .private(CloudKitSchemaTests.cloudKitContainerIdentifier)
            )
        }

        #expect(throws: Never.self, sourceLocation: sourceLocation) {
            _ = try makeContainer(for: schema, cloudKitDatabase: .none)
        }
    }

    @Test func uniqueConstraintIsRejected() {
        Self.expectRejectedOnlyByCloudKit(Schema([UniqueConstrainedProbe.self]))
    }

    @Test func nonOptionalAttributeWithoutDefaultIsRejected() {
        Self.expectRejectedOnlyByCloudKit(Schema([NonOptionalAttributeProbe.self]))
    }

    @Test func nonOptionalRelationshipIsRejected() {
        Self.expectRejectedOnlyByCloudKit(
            Schema([NonOptionalRelationshipParentProbe.self, NonOptionalRelationshipChildProbe.self])
        )
    }
}

// MARK: - Deliberately CloudKit-incompatible probe models
//
// These exist only to be rejected by the negative control above. They are
// never added to the app's schema — see `SubTimerApp.makeModelContainer()` for
// the real one.

/// Violates "CloudKit integration does not support unique constraints".
@Model
final class UniqueConstrainedProbe {
    @Attribute(.unique) var code: String = ""

    init(code: String = "") {
        self.code = code
    }
}

/// Violates "CloudKit integration requires that all attributes be optional, or
/// have a default value set".
@Model
final class NonOptionalAttributeProbe {
    var requiredValue: String

    init(requiredValue: String) {
        self.requiredValue = requiredValue
    }
}

/// Violates "CloudKit integration requires that all relationships be optional".
@Model
final class NonOptionalRelationshipChildProbe {
    var parent: NonOptionalRelationshipParentProbe

    init(parent: NonOptionalRelationshipParentProbe) {
        self.parent = parent
    }
}

@Model
final class NonOptionalRelationshipParentProbe {
    @Relationship(deleteRule: .cascade, inverse: \NonOptionalRelationshipChildProbe.parent)
    var children: [NonOptionalRelationshipChildProbe] = []

    init() {}
}
