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
    ActivePlayersSectionView(
      players: activePlayers,
      maxActiveCount: configuration.activePlayersCount,
      onPlayerTap: { player in showingPlayerActions = player }
    )
  }

  // MARK: - Bench Section

  private var benchSection: some View {
    BenchSectionView(
      players: benchedPlayers,
      activePlayersCount: activePlayers.count,
      maxActiveCount: configuration.activePlayersCount,
      onPlayerTap: { player in showingPlayerActions = player },
      onActivatePlayer: activatePlayer
    )
  }

  // MARK: - Temporarily Out Section

  private var temporarilyOutSection: some View {
    TemporarilyOutSectionView(
      players: temporarilyOutPlayers,
      onReturnToBench: returnPlayerToBench
    )
  }

  // MARK: - Substitute Button

  private var substituteButtonSection: some View {
    SubstitutionButtonView(
      canPerformSubstitution: canPerformSubstitution,
      onSubstitute: performAutomaticSubstitution
    )
  }

  private var canPerformSubstitution: Bool {
    !activePlayers.isEmpty && !benchedPlayers.isEmpty
  }

  // MARK: - Manual Substitution Sheet

  private func manualSubstitutionSheet(playerToSubOut: Player) -> some View {
    ManualSubstitutionSheetView(
      playerToSubOut: playerToSubOut,
      benchPlayers: benchedPlayers,
      onSubstitute: { benchPlayer in
        performManualSubstitution(subOut: playerToSubOut, subIn: benchPlayer)
      },
      onCancel: {
        showingManualSubstitution = false
        selectedPlayerToSubOut = nil
      }
    )
  }

  // MARK: - Player Actions Sheet

  private func playerActionsSheet(player: Player) -> some View {
    PlayerActionsSheetView(
      player: player,
      canActivate: activePlayers.count < configuration.activePlayersCount,
      onSubstituteOut: {
        selectedPlayerToSubOut = player
        showingPlayerActions = nil
        showingManualSubstitution = true
      },
      onActivatePlayer: {
        activatePlayer(player)
        showingPlayerActions = nil
      },
      onMarkTemporarilyOut: {
        markPlayerTemporarilyOut(player)
        showingPlayerActions = nil
      },
      onReturnToBench: {
        returnPlayerToBench(player)
        showingPlayerActions = nil
      },
      onClose: {
        showingPlayerActions = nil
      }
    )
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
