//
//  SettingsView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI
import SwiftData

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
                Button("Cancel", role: .cancel) { }
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
        Section {
            ForEach(players) { player in
                HStack {
                    VStack(alignment: .leading) {
                        Text(player.name)
                            .font(.body)
                        Text(statusText(for: player.status))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        editingPlayer = player
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onDelete(perform: deletePlayers)
            .onMove(perform: movePlayers)

            Button {
                showingAddPlayer = true
            } label: {
                Label("Add Player", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Players")
        } footer: {
            Text("\(players.count) player(s) in roster")
        }
    }

    // MARK: - Configuration Section

    private var configurationSection: some View {
        Section {
            Stepper(value: Binding(
                get: { configuration.activePlayersCount },
                set: { newValue in
                    let maxPlayers = players.count
                    configuration.activePlayersCount = min(newValue, maxPlayers > 0 ? maxPlayers : 1)
                    configuration.lastModifiedDate = Date()
                }
            ), in: 1...max(1, players.count)) {
                HStack {
                    Text("Active Players")
                    Spacer()
                    Text("\(configuration.activePlayersCount)")
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Preferred Play Time", selection: Binding(
                get: { configuration.preferredPlayTimeSeconds },
                set: { newValue in
                    configuration.preferredPlayTimeSeconds = newValue
                    configuration.lastModifiedDate = Date()
                }
            )) {
                Text("0:30").tag(30)
                Text("1:00").tag(60)
                Text("1:30").tag(90)
                Text("2:00").tag(120)
                Text("2:30").tag(150)
                Text("3:00").tag(180)
                Text("3:30").tag(210)
                Text("4:00").tag(240)
                Text("4:30").tag(270)
                Text("5:00").tag(300)
                Text("7:30").tag(450)
                Text("10:00").tag(600)
                Text("15:00").tag(900)
                Text("20:00").tag(1200)
                Text("30:00").tag(1800)
            }
        } header: {
            Text("Configuration")
        } footer: {
            if players.count < configuration.activePlayersCount {
                Text("⚠️ Active players automatically adjusted to match available players (\(players.count))")
                    .foregroundStyle(.orange)
            }
        }
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
        NavigationStack {
            Form {
                TextField("Player Name", text: $newPlayerName)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddPlayer = false
                        newPlayerName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addPlayer()
                    }
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Edit Player Sheet

    private func editPlayerSheet(player: Player) -> some View {
        EditPlayerView(player: player, onDismiss: {
            editingPlayer = nil
        })
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

    private func statusText(for status: PlayerStatus) -> String {
        switch status {
        case .active:
            return "Currently Playing"
        case .benched:
            return "On Bench"
        case .temporarilyOut:
            return "Temporarily Out"
        }
    }
}

// MARK: - Edit Player View

struct EditPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    let player: Player
    let onDismiss: () -> Void

    @State private var editedName: String
    @State private var editedStatus: PlayerStatus

    init(player: Player, onDismiss: @escaping () -> Void) {
        self.player = player
        self.onDismiss = onDismiss
        _editedName = State(initialValue: player.name)
        _editedStatus = State(initialValue: player.status)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Information") {
                    TextField("Name", text: $editedName)
                        .textInputAutocapitalization(.words)
                }

                Section("Status") {
                    Picker("Status", selection: $editedStatus) {
                        Text("On Bench").tag(PlayerStatus.benched)
                        Text("Currently Playing").tag(PlayerStatus.active)
                        Text("Temporarily Out").tag(PlayerStatus.temporarilyOut)
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current Play Duration:")
                            Spacer()
                            Text(formatTime(player.currentPlayDuration))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Total Play Time:")
                            Spacer()
                            Text(formatTime(player.totalPlayTime))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Created:")
                            Spacer()
                            Text(player.createdDate, format: .dateTime.month().day().year())
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Statistics")
                }
            }
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        player.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        player.status = editedStatus
        onDismiss()
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Player.self, AppConfiguration.self, Session.self], inMemory: true)
}
