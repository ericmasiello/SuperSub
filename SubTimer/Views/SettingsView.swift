//
//  SettingsView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Player.sortOrder) private var players: [Player]
  @Query private var configurations: [AppConfiguration]
  @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

  @State private var showingAddPlayer = false
  @State private var newPlayerName = ""
  @State private var editingPlayer: Player?
  @State private var showingClearSessionAlert = false

  private var configuration: AppConfiguration {
    if let config = configurations.first {
      return config
    } else {
      let newConfig = AppConfiguration()
      modelContext.insert(newConfig)
      return newConfig
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        playerManagementSection
        configurationSection
        sessionManagementSection
      }
      .navigationTitle("Settings")
      .sheet(isPresented: $showingAddPlayer) {
        addPlayerSheet
      }
      .sheet(item: $editingPlayer) { player in
        editPlayerSheet(player: player)
      }
      .alert("Clear Current Session", isPresented: $showingClearSessionAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Clear", role: .destructive) {
          clearCurrentSession()
        }
      } message: {
        Text("This will reset all player times and end the current session. This cannot be undone.")
      }
    }
  }

  // MARK: - Player Management Section

  private var playerManagementSection: some View {
    PlayerListSectionView(
      players: players,
      onEdit: { player in editingPlayer = player },
      onDelete: deletePlayers,
      onMove: movePlayers,
      onAdd: { showingAddPlayer = true }
    )
  }

  // MARK: - Configuration Section

  private var configurationSection: some View {
    ConfigurationSectionView(
      activePlayersCount: configuration.activePlayersCount,
      maxPlayers: players.count,
      preferredTimeSeconds: configuration.preferredPlayTimeSeconds,
      onActivePlayersChange: { newValue in
        configuration.activePlayersCount = newValue
        configuration.lastModifiedDate = Date()
      },
      onPreferredTimeChange: { newValue in
        configuration.preferredPlayTimeSeconds = newValue
        configuration.lastModifiedDate = Date()
      }
    )
  }

  // MARK: - Session Management Section

  private var sessionManagementSection: some View {
    Section {
      NavigationLink {
        sessionHistoryView
      } label: {
        Label("Session History", systemImage: "clock.arrow.circlepath")
      }

      Button(role: .destructive) {
        showingClearSessionAlert = true
      } label: {
        Label("Clear Current Session", systemImage: "trash")
      }
    } header: {
      Text("Session Management")
    }
  }

  // MARK: - Session History View

  private var sessionHistoryView: some View {
    List {
      if sessions.isEmpty {
        ContentUnavailableView(
          "No Sessions",
          systemImage: "clock.badge.questionmark",
          description: Text("Start a session from the Timer tab to see history here.")
        )
      } else {
        ForEach(sessions) { session in
          VStack(alignment: .leading, spacing: 4) {
            Text(session.startDate, format: .dateTime.month().day().year().hour().minute())
              .font(.headline)

            HStack {
              Label("\(session.formattedDuration)", systemImage: "clock")
              Label("\(session.substitutionCount) subs", systemImage: "arrow.left.arrow.right")
              Label("\(session.playerNames.count) players", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
        .onDelete(perform: deleteSessions)
      }
    }
    .navigationTitle("Session History")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Add Player Sheet

  private var addPlayerSheet: some View {
    AddPlayerSheetView(
      playerName: $newPlayerName,
      onCancel: {
        showingAddPlayer = false
        newPlayerName = ""
      },
      onAdd: addPlayer
    )
  }

  // MARK: - Edit Player Sheet

  private func editPlayerSheet(player: Player) -> some View {
    EditPlayerSheetView(
      player: player,
      onSave: { name, status in
        player.name = name
        player.status = status
        editingPlayer = nil
      },
      onCancel: {
        editingPlayer = nil
      }
    )
  }

  // MARK: - Actions

  private func addPlayer() {
    let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return }

    let newPlayer = Player(
      name: trimmedName,
      sortOrder: players.count
    )
    modelContext.insert(newPlayer)

    showingAddPlayer = false
    newPlayerName = ""
  }

  private func deletePlayers(at offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(players[index])
    }

    // Reorder remaining players
    for (index, player) in players.enumerated() {
      player.sortOrder = index
    }
  }

  private func movePlayers(from source: IndexSet, to destination: Int) {
    var revisedPlayers = players.map { $0 }
    revisedPlayers.move(fromOffsets: source, toOffset: destination)

    for (index, player) in revisedPlayers.enumerated() {
      player.sortOrder = index
    }
  }

  private func clearCurrentSession() {
    // Reset all player times
    for player in players {
      player.currentPlayDuration = 0
      player.status = .benched
    }

    // End any active sessions
    for session in sessions where session.isActive {
      session.endDate = Date()
    }
  }

  private func deleteSessions(at offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(sessions[index])
    }
  }

}

#Preview {
  SettingsView()
    .modelContainer(for: [Player.self, AppConfiguration.self, Session.self], inMemory: true)
}
