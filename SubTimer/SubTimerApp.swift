//
//  SubTimerApp.swift
//  SubTimer
//
//  Created by Eric Masiello on 2/13/26.
//

import SwiftData
import SwiftUI

@main
struct SubTimerApp: App {
    var sharedModelContainer: ModelContainer = Self.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Model Container Setup

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            Player.self,
            AppConfiguration.self,
            Session.self,
            OrderManager.self
        ])

        // Use in-memory storage for UI testing
        let isUITesting = CommandLine.arguments.contains("--uitesting")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Add test data when in UI testing mode
            if isUITesting {
                setupTestData(in: container)
            }

            return container
        } catch {
            print("ModelContainer creation failed: \(error)")
            return recoverModelContainer(
                schema: schema,
                modelConfiguration: modelConfiguration,
                isUITesting: isUITesting
            )
        }
    }

    /// Deletes the existing database files and retries container creation.
    /// Called when the initial `ModelContainer` creation fails, most likely
    /// due to a schema migration that SwiftData couldn't perform in place.
    private static func recoverModelContainer(
        schema: Schema,
        modelConfiguration: ModelConfiguration,
        isUITesting: Bool
    ) -> ModelContainer {
        print("Attempting to delete old database and create new one...")

        // Delete the existing database files
        let url = modelConfiguration.url
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(
            at: url.deletingPathExtension().appendingPathExtension("sqlite-shm")
        )
        try? FileManager.default.removeItem(
            at: url.deletingPathExtension().appendingPathExtension("sqlite-wal")
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            if isUITesting {
                setupTestData(in: container)
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer even after cleanup: \(error)")
        }
    }

    // MARK: - Test Data Setup

    private static func setupTestData(in container: ModelContainer) {
        let context = ModelContext(container)

        // Create test players
        let player1 = Player(name: "Alice Johnson")
        player1.status = .active
        player1.currentPlayDuration = 120
        player1.totalPlayTime = 300

        let player2 = Player(name: "Bob Smith")
        player2.status = .active
        player2.currentPlayDuration = 90
        player2.totalPlayTime = 250

        let player3 = Player(name: "Charlie Brown")
        player3.status = .benched
        player3.totalPlayTime = 180

        let player4 = Player(name: "Diana Prince")
        player4.status = .benched
        player4.totalPlayTime = 200

        let player5 = Player(name: "Eve Martinez")
        player5.status = .temporarilyOut
        player5.totalPlayTime = 150

        context.insert(player1)
        context.insert(player2)
        context.insert(player3)
        context.insert(player4)
        context.insert(player5)

        // Create test configuration
        let config = AppConfiguration()
        config.preferredPlayTimeSeconds = 120
        config.activePlayersCount = 5
        context.insert(config)

        do {
            try context.save()
        } catch {
            print("Failed to save test data: \(error)")
        }
    }
}
