//
//  TimerView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//
//  PHASE 1.6 FINAL - CONSOLIDATED TIMERVIEW
//
//  ARCHITECTURE OVERVIEW:
//  This view is the main timer screen with a clean separation of concerns:
//  • UI Presentation (lines 1-234): SwiftUI view hierarchy
//  • Business Logic Extension (lines 235-368): All action handlers
//
//  11 EXTRACTED COMPONENTS:
//
//  Timer Components (5):
//    • TimerControlsView - Play/pause button
//    • PreferredTimeDisplayView - Current play time with overtime indicator
//    • SubstitutionButtonView - Main substitute button
//    • ManualSubstitutionSheetView - Player selection sheet for manual subs
//    • PlayerActionsSheetView - Context-sensitive player actions
//
//  Player Components (6):
//    • ActivePlayerRowView - Individual active player display
//    • BenchPlayerRowView - Individual benched player display
//    • TemporarilyOutPlayerRowView - Individual temporarily out player display
//    • ActivePlayersSectionView - Active players section with header
//    • BenchSectionView - Bench section with header and empty state
//    • TemporarilyOutSectionView - Temporarily out section
//
//  RESPONSIBILITIES:
//  • Render timer UI using composition of smaller components
//  • Manage sheet presentation state (@State variables)
//  • Filter players by status (computed properties)
//  • Coordinate timer/substitution/player actions (extension methods)
//  • Session management and haptic feedback
//
//  METRICS:
//  • Original: 634 lines
//  • Final: 368 lines
//  • Reduction: 266 lines (42% smaller)
//  • Components created: 11
//  • Preview states: 47
//

import SwiftData
import SwiftUI

struct TimerView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Player.sortOrder) var players: [Player]
  @Query private var configurations: [AppConfiguration]
  @Query(sort: \Session.startDate, order: .reverse) var sessions: [Session]

  @State var timerViewModel: TimerViewModel?
  @State var showingManualSubstitution = false
  @State var selectedPlayerToSubOut: Player?
  @State var showingPlayerActions: Player?

  var configuration: AppConfiguration {
    if let config = configurations.first {
      return config
    } else {
      let newConfig = AppConfiguration()
      modelContext.insert(newConfig)
      return newConfig
    }
  }

  var activePlayers: [Player] {
    players.filter { $0.status == .active }
  }

  var benchedPlayers: [Player] {
    players.filter { $0.status == .benched }
  }

  var temporarilyOutPlayers: [Player] {
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
        initializeViewModel(allPlayers: players)
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
      onToggle: toggleTimer,
      onReset: resetTimer
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

}

// MARK: - Business Logic Extension

/// Extension containing all business logic and action handlers
/// Separated for clarity while maintaining access to private properties
extension TimerView {

  // MARK: - Timer Management

  func initializeViewModel(allPlayers: [Player]) {
    if timerViewModel == nil {
      timerViewModel = TimerViewModel(players: allPlayers)
    }
    timerViewModel?.onTimerTick = { updatePlayerTimes() }
  }

  func toggleTimer() {
    guard let vm = timerViewModel else { return }
    if vm.isRunning {
      vm.pauseTimer()
    } else {
      autoActivateInitialPlayersIfNeeded()
      createOrUpdateSession()
      vm.startTimer()
    }
  }
  
  func resetTimer() {
    guard let vm = timerViewModel else { return }
    vm.resetTimer()
  }

  private func autoActivateInitialPlayersIfNeeded() {
    guard activePlayers.isEmpty else { return }
    let allFilteredPlayers = activePlayers + benchedPlayers + temporarilyOutPlayers
    let playersToActivate = min(configuration.activePlayersCount, allFilteredPlayers.count)
    for i in 0..<playersToActivate where i < allFilteredPlayers.count {
      allFilteredPlayers[i].status = .active
    }
  }

  private func updatePlayerTimes() {
    for player in activePlayers { player.currentPlayDuration += 1 }
    if let activeSession = sessions.first(where: { $0.isActive }) {
      activeSession.duration = Date().timeIntervalSince(activeSession.startDate)
    }
    checkPreferredTimeAlert()
  }

  private func checkPreferredTimeAlert() {
    guard
      let longestPlayingPlayer = activePlayers.max(by: {
        $0.currentPlayDuration < $1.currentPlayDuration
      })
    else { return }
    let preferredTime = TimeInterval(configuration.preferredPlayTimeSeconds)
    if preferredTime > 0 && longestPlayingPlayer.currentPlayDuration == preferredTime {
      triggerPreferredTimeAlert()
    }
  }

  // MARK: - Substitution

  func performAutomaticSubstitution() {
    guard
      let playerToSubOut = activePlayers.max(by: { $0.currentPlayDuration < $1.currentPlayDuration }
      ),
      let playerToSubIn = benchedPlayers.first
    else { return }
    performSubstitution(subOut: playerToSubOut, subIn: playerToSubIn)
  }

  func performManualSubstitution(subOut: Player, subIn: Player) {
    performSubstitution(subOut: subOut, subIn: subIn)
    showingManualSubstitution = false
    selectedPlayerToSubOut = nil
  }

  private func performSubstitution(subOut: Player, subIn: Player) {
    let wasRunning = timerViewModel?.isRunning ?? false
    subOut.totalPlayTime += subOut.currentPlayDuration
    subOut.status = .benched
    subIn.status = .active
    for player in activePlayers { player.currentPlayDuration = 0 }
    if let activeSession = sessions.first(where: { $0.isActive }) {
      activeSession.substitutionCount += 1
    }
    if wasRunning { timerViewModel?.startTimer() }
    provideHapticFeedback()
  }

  // MARK: - Player Status

  func activatePlayer(_ player: Player) {
    player.status = .active
    player.currentPlayDuration = 0
  }

  func markPlayerTemporarilyOut(_ player: Player) {
    if player.status == .active {
      player.totalPlayTime += player.currentPlayDuration
      player.currentPlayDuration = 0
    }
    player.status = .temporarilyOut
  }

  func returnPlayerToBench(_ player: Player) {
    player.status = .benched
  }

  // MARK: - Session & Feedback

  private func createOrUpdateSession() {
    guard sessions.first(where: { $0.isActive }) == nil else { return }
    let allPlayerNames = (activePlayers + benchedPlayers + temporarilyOutPlayers).map { $0.name }
    let newSession = Session(
      preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds,
      activePlayersCount: configuration.activePlayersCount,
      playerNames: allPlayerNames
    )
    modelContext.insert(newSession)
  }

  private func triggerPreferredTimeAlert() {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
  }

  private func provideHapticFeedback() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }
}

#Preview("Empty State") {
  TimerView()
    .modelContainer(for: [Player.self, AppConfiguration.self, Session.self], inMemory: true)
}

#Preview("Main Timer View") {
  let container = try! ModelContainer(
    for: Player.self, AppConfiguration.self, Session.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )

  let context = container.mainContext

  // Create configuration
  let config = AppConfiguration()
  config.activePlayersCount = 3
  config.preferredPlayTimeSeconds = 180
  context.insert(config)

  // Create sample players
  let player1 = Player(name: "Alice", sortOrder: 0)
  player1.status = .active
  player1.currentPlayDuration = 120

  let player2 = Player(name: "Bob", sortOrder: 1)
  player2.status = .active
  player2.currentPlayDuration = 95

  let player3 = Player(name: "Charlie", sortOrder: 2)
  player3.status = .active
  player3.currentPlayDuration = 110

  let player4 = Player(name: "Diana", sortOrder: 3)
  player4.status = .benched
  player4.totalPlayTime = 85

  let player5 = Player(name: "Eve", sortOrder: 4)
  player5.status = .benched
  player5.totalPlayTime = 60

  let player6 = Player(name: "Frank", sortOrder: 5)
  player6.status = .temporarilyOut
  player6.totalPlayTime = 75

  context.insert(player1)
  context.insert(player2)
  context.insert(player3)
  context.insert(player4)
  context.insert(player5)
  context.insert(player6)

  return TimerView()
    .modelContainer(container)
}
