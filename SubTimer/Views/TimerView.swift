//
//  TimerView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftData
import SwiftUI

struct TimerView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Player.sortOrder) private var players: [Player]
  @Query private var configurations: [AppConfiguration]
  @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

  @State private var timerViewModel: TimerViewModel?
  @State private var showingManualSubstitution = false
  @State private var selectedPlayerToSubOut: Player?
  @State private var showingPlayerActions: Player?

  private var configuration: AppConfiguration {
    if let config = configurations.first {
      return config
    } else {
      let newConfig = AppConfiguration()
      modelContext.insert(newConfig)
      return newConfig
    }
  }

  private var activePlayers: [Player] {
    players.filter { $0.status == .active }
  }

  private var benchedPlayers: [Player] {
    players.filter { $0.status == .benched }
  }

  private var temporarilyOutPlayers: [Player] {
    players.filter { $0.status == .temporarilyOut }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        if players.isEmpty {
          emptyStateView
        } else {
          mainTimerView
        }
      }
      .navigationTitle("SubTimer")
      .onAppear {
        initializeViewModel()
      }
      .sheet(isPresented: $showingManualSubstitution) {
        if let playerToSubOut = selectedPlayerToSubOut {
          manualSubstitutionSheet(playerToSubOut: playerToSubOut)
        }
      }
      .sheet(item: $showingPlayerActions) { player in
        playerActionsSheet(player: player)
      }
    }
  }

  // MARK: - Empty State

  private var emptyStateView: some View {
    ContentUnavailableView(
      "No Players",
      systemImage: "person.3.slash",
      description: Text("Add players in Settings to start tracking substitutions.")
    )
  }

  // MARK: - Main Timer View

  private var mainTimerView: some View {
    ScrollView {
      VStack(spacing: 24) {
        timerControlsSection
        preferredTimeDisplay
        activePlayersSection
        benchSection
        if !temporarilyOutPlayers.isEmpty {
          temporarilyOutSection
        }
        substituteButtonSection
      }
      .padding()
    }
  }

  // MARK: - Timer Controls

  private var timerControlsSection: some View {
    TimerControlsView(
      isRunning: timerViewModel?.isRunning ?? false,
      onToggle: toggleTimer
    )
  }

  // MARK: - Preferred Time Display

  private var preferredTimeDisplay: some View {
    let currentDuration =
      activePlayers.max(by: {
        $0.currentPlayDuration < $1.currentPlayDuration
      })?.currentPlayDuration ?? 0

    return PreferredTimeDisplayView(
      currentPlayDuration: currentDuration,
      preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds
    )
  }

  // MARK: - Active Players Section

  private var activePlayersSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Active Players", systemImage: "figure.run")
          .font(.title3)
          .bold()
        Spacer()
        Text("\(activePlayers.count)/\(configuration.activePlayersCount)")
          .foregroundStyle(.secondary)
      }

      if activePlayers.isEmpty {
        emptyActivePlayersView
      } else {
        ForEach(activePlayers) { player in
          activePlayerRow(player: player)
        }
      }
    }
  }

  private var emptyActivePlayersView: some View {
    Text("No active players. Tap a player on the bench to activate.")
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(Color(uiColor: .tertiarySystemBackground))
      .cornerRadius(8)
  }

  private func activePlayerRow(player: Player) -> some View {
    let isNextToSubOut =
      activePlayers.max(by: { $0.currentPlayDuration < $1.currentPlayDuration })?.id == player.id

    return ActivePlayerRowView(
      player: player,
      isNextToSubOut: isNextToSubOut && activePlayers.count > 1,
      onTap: { showingPlayerActions = player }
    )
  }

  // MARK: - Bench Section

  private var benchSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Bench", systemImage: "person.2")
          .font(.title3)
          .bold()
        Spacer()
        Text("\(benchedPlayers.count)")
          .foregroundStyle(.secondary)
      }

      if benchedPlayers.isEmpty {
        Text("No players on bench")
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          .background(Color(uiColor: .tertiarySystemBackground))
          .cornerRadius(8)
      } else {
        ForEach(Array(benchedPlayers.enumerated()), id: \.element.id) { index, player in
          benchPlayerRow(player: player, isNextUp: index == 0)
        }
      }
    }
  }

  private func benchPlayerRow(player: Player, isNextUp: Bool) -> some View {
    BenchPlayerRowView(
      player: player,
      isNextUp: isNextUp,
      canActivate: activePlayers.count < configuration.activePlayersCount,
      onTap: { showingPlayerActions = player },
      onActivate: { activatePlayer(player) }
    )
  }

  // MARK: - Temporarily Out Section

  private var temporarilyOutSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Temporarily Out", systemImage: "exclamationmark.triangle")
        .font(.title3)
        .bold()

      ForEach(temporarilyOutPlayers) { player in
        TemporarilyOutPlayerRowView(
          player: player,
          onReturnToBench: { returnPlayerToBench(player) }
        )
      }
    }
  }

  // MARK: - Substitute Button

  private var substituteButtonSection: some View {
    Button {
      performAutomaticSubstitution()
    } label: {
      HStack {
        Image(systemName: "arrow.left.arrow.right.circle.fill")
          .font(.title2)
        Text("Substitute")
          .font(.title2)
          .bold()
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 20)
      .background(canPerformSubstitution ? Color.blue : Color.gray.opacity(0.3))
      .foregroundStyle(.white)
      .cornerRadius(12)
    }
    .disabled(!canPerformSubstitution)
  }

  private var canPerformSubstitution: Bool {
    !activePlayers.isEmpty && !benchedPlayers.isEmpty
  }

  // MARK: - Manual Substitution Sheet

  private func manualSubstitutionSheet(playerToSubOut: Player) -> some View {
    NavigationStack {
      List {
        ForEach(benchedPlayers) { benchPlayer in
          Button {
            performManualSubstitution(subOut: playerToSubOut, subIn: benchPlayer)
          } label: {
            HStack {
              Text(benchPlayer.name)
              Spacer()
              Text("Total: \(formatTime(benchPlayer.totalPlayTime))")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle("Select Player to Sub In")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            showingManualSubstitution = false
            selectedPlayerToSubOut = nil
          }
        }
      }
    }
  }

  // MARK: - Player Actions Sheet

  private func playerActionsSheet(player: Player) -> some View {
    NavigationStack {
      List {
        if player.status == .active {
          Section {
            Button {
              selectedPlayerToSubOut = player
              showingPlayerActions = nil
              showingManualSubstitution = true
            } label: {
              Label("Substitute Out", systemImage: "arrow.down.circle")
            }

            Button(role: .destructive) {
              markPlayerTemporarilyOut(player)
              showingPlayerActions = nil
            } label: {
              Label("Mark Temporarily Out", systemImage: "exclamationmark.triangle")
            }
          }
        } else if player.status == .benched {
          Section {
            if activePlayers.count < configuration.activePlayersCount {
              Button {
                activatePlayer(player)
                showingPlayerActions = nil
              } label: {
                Label("Activate Player", systemImage: "arrow.up.circle")
              }
            }

            Button(role: .destructive) {
              markPlayerTemporarilyOut(player)
              showingPlayerActions = nil
            } label: {
              Label("Mark Temporarily Out", systemImage: "exclamationmark.triangle")
            }
          }
        } else if player.status == .temporarilyOut {
          Section {
            Button {
              returnPlayerToBench(player)
              showingPlayerActions = nil
            } label: {
              Label("Return to Bench", systemImage: "arrow.counterclockwise")
            }
          }
        }

        Section {
          HStack {
            Text("Current Play Duration")
            Spacer()
            Text(formatTime(player.currentPlayDuration))
              .foregroundStyle(.secondary)
          }

          HStack {
            Text("Total Play Time")
            Spacer()
            Text(formatTime(player.totalPlayTime))
              .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle(player.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            showingPlayerActions = nil
          }
        }
      }
    }
  }

  // MARK: - Actions

  private func initializeViewModel() {
    if timerViewModel == nil {
      timerViewModel = TimerViewModel(players: players)
    }
    timerViewModel?.onTimerTick = {
      updatePlayerTimes()
    }
  }

  private func toggleTimer() {
    guard let vm = timerViewModel else { return }

    if vm.isRunning {
      vm.pauseTimer()
    } else {
      // Ensure we have active players
      if activePlayers.isEmpty && !players.isEmpty {
        // Auto-activate players up to the configured count
        let playersToActivate = min(configuration.activePlayersCount, players.count)
        for i in 0..<playersToActivate {
          if i < players.count {
            players[i].status = .active
          }
        }
      }

      // Create or update session
      createOrUpdateSession()
      vm.startTimer()
    }
  }

  private func updatePlayerTimes() {
    for player in activePlayers {
      player.currentPlayDuration += 1
    }

    // Update active session duration
    if let activeSession = sessions.first(where: { $0.isActive }) {
      activeSession.duration = Date().timeIntervalSince(activeSession.startDate)
    }

    // Check if preferred time reached for alerts
    if let longestPlayingPlayer = activePlayers.max(by: {
      $0.currentPlayDuration < $1.currentPlayDuration
    }) {
      let preferredTime = TimeInterval(configuration.preferredPlayTimeSeconds)
      if preferredTime > 0 && longestPlayingPlayer.currentPlayDuration == preferredTime {
        triggerPreferredTimeAlert()
      }
    }
  }

  private func performAutomaticSubstitution() {
    guard
      let playerToSubOut = activePlayers.max(by: { $0.currentPlayDuration < $1.currentPlayDuration }
      ),
      let playerToSubIn = benchedPlayers.first
    else {
      return
    }

    performSubstitution(subOut: playerToSubOut, subIn: playerToSubIn)
  }

  private func performManualSubstitution(subOut: Player, subIn: Player) {
    performSubstitution(subOut: subOut, subIn: subIn)
    showingManualSubstitution = false
    selectedPlayerToSubOut = nil
  }

  private func performSubstitution(subOut: Player, subIn: Player) {
    let wasRunning = timerViewModel?.isRunning ?? false

    // Update total play time for player going out
    subOut.totalPlayTime += subOut.currentPlayDuration

    // Swap statuses
    subOut.status = .benched
    subIn.status = .active

    // Reset all active players' current duration
    for player in activePlayers {
      player.currentPlayDuration = 0
    }

    // Update session substitution count
    if let activeSession = sessions.first(where: { $0.isActive }) {
      activeSession.substitutionCount += 1
    }

    // Restart timer if it was running
    if wasRunning {
      timerViewModel?.startTimer()
    }

    // Provide haptic feedback
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
  }

  private func activatePlayer(_ player: Player) {
    player.status = .active
    player.currentPlayDuration = 0
  }

  private func markPlayerTemporarilyOut(_ player: Player) {
    if player.status == .active {
      player.totalPlayTime += player.currentPlayDuration
      player.currentPlayDuration = 0
    }
    player.status = .temporarilyOut
  }

  private func returnPlayerToBench(_ player: Player) {
    player.status = .benched
  }

  private func createOrUpdateSession() {
    // Check if there's an active session
    if sessions.first(where: { $0.isActive }) == nil {
      let newSession = Session(
        preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds,
        activePlayersCount: configuration.activePlayersCount,
        playerNames: players.map { $0.name }
      )
      modelContext.insert(newSession)
    }
  }

  private func triggerPreferredTimeAlert() {
    // Visual feedback is already handled by color change
    // Add haptic and audio feedback
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.warning)

    // Note: For audio, you would use AVFoundation to play a sound
    // This is left as a future enhancement
  }

  private func formatTime(_ timeInterval: TimeInterval) -> String {
    TimeFormatter.format(timeInterval)
  }
}

#Preview {
  TimerView()
    .modelContainer(for: [Player.self, AppConfiguration.self, Session.self], inMemory: true)
}
