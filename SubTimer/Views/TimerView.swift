//
//  TimerView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//
//  PHASE 1.6 FINAL - CONSOLIDATED TIMERVIEW
//  PHASE 1.7 - LIVE ACTIVITY INTEGRATION
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

/*
 IDEA:
 - Add a widget that appears on my lock screen showing active session timer
 - Add a dynamic island widget showing the count down
 - Add ability to force the app to stay on (not go to sleep)

 */

import ActivityKit
import SwiftData
import SwiftUI

private struct TimerVisibilityPreferenceKey: PreferenceKey {
  static let defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}

/// The player-related sheet currently presented on `TimerView`, if any.
/// Two separate `.sheet` modifiers on the same view (one for player actions,
/// one for manual substitution) proved unreliable when handing off from one
/// to the other - SwiftUI would silently drop the second presentation.
/// Routing both through a single `.sheet(item:)` on this enum makes that
/// hand-off just a normal state change within one presentation, not a
/// cross-modifier coordination problem.
private enum TimerSheet: Identifiable {
  case playerActions(Player)
  case manualSubstitution(playerToSubOut: Player)

  var id: String {
    switch self {
    case .playerActions(let player):
      "playerActions-\(player.id)"
    case .manualSubstitution(let player):
      "manualSubstitution-\(player.id)"
    }
  }
}

struct TimerView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Player.sortOrder) var players: [Player]
  @Query private var configurations: [AppConfiguration]
  @Query(sort: \Session.startDate, order: .reverse) var sessions: [Session]
  @Query private var orderManagers: [OrderManager]

  @State var timerViewModel: TimerViewModel?
  @State private var activeSheet: TimerSheet?
  @State private var benchOrder: [UUID] = []
  @State private var activeOrder: [UUID] = []
  @State private var cachedManagers: [PlayerOrderRole: OrderManager] = [:]
  @State private var showPinnedButton = false
  @State private var overtimeUpdateWork: DispatchWorkItem?
  @State private var showCompactTimer = false

  var configuration: AppConfiguration {
    if let config = configurations.first {
      return config
    } else {
      let newConfig = AppConfiguration()
      modelContext.insert(newConfig)
      return newConfig
    }
  }

  func orderManager(for role: PlayerOrderRole) -> OrderManager {
    if let cached = cachedManagers[role] {
      return cached
    }

    if let manager = orderManagers.first(where: { $0.role == role }) {
      cachedManagers[role] = manager
      return manager
    } else {
      let newManager = OrderManager(role: role)
      modelContext.insert(newManager)
      try? modelContext.save()
      cachedManagers[role] = newManager
      return newManager
    }
  }

  var benchManager: OrderManager { orderManager(for: .bench) }

  var activeManager: OrderManager { orderManager(for: .active) }

  var activePlayers: [Player] {
    let active = players.filter { $0.status == .active }

    let orderToUse = activeOrder.isEmpty
      ? (orderManagers.first(where: { $0.role == .active })?.playerOrder ?? [])
      : activeOrder

    return active.sorted { player1, player2 in
      let pos1 = orderToUse.firstIndex(of: player1.id)
      let pos2 = orderToUse.firstIndex(of: player2.id)

      if let p1 = pos1, let p2 = pos2 {
        return p1 < p2
      } else if pos1 != nil {
        return true
      } else if pos2 != nil {
        return false
      } else {
        return player1.currentPlayDuration > player2.currentPlayDuration
      }
    }
  }

  var benchedPlayers: [Player] {
    let benched = players.filter { $0.status == .benched }

    // Use the state-managed bench order for immediate UI updates
    let orderToUse = benchOrder.isEmpty
      ? (orderManagers.first(where: { $0.role == .bench })?.playerOrder ?? [])
      : benchOrder

    // Sort by bench order, then by sortOrder for players not in the bench order
    return benched.sorted { player1, player2 in
      let pos1 = orderToUse.firstIndex(of: player1.id)
      let pos2 = orderToUse.firstIndex(of: player2.id)

      if let p1 = pos1, let p2 = pos2 {
        return p1 < p2
      } else if pos1 != nil {
        return true
      } else if pos2 != nil {
        return false
      } else {
        return player1.sortOrder < player2.sortOrder
      }
    }
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
      .navigationTitle("Super Sub")
      .onAppear {
        // Initialize cached managers first
        _ = benchManager
        _ = activeManager
        initializeViewModel(allPlayers: players)
        syncOrderManager(role: .bench, status: .benched)
        syncOrderManager(role: .active, status: .active)
        loadOrder(for: .bench)
        loadOrder(for: .active)
      }
      .sheet(item: $activeSheet) { sheet in
        switch sheet {
        case .playerActions(let player):
          playerActionsSheet(player: player)
        case .manualSubstitution(let playerToSubOut):
          manualSubstitutionSheet(playerToSubOut: playerToSubOut)
        }
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
    ScrollViewReader { scrollProxy in
      ScrollView {
        VStack(spacing: 24) {
          timerControlsSection
            .id("timerControls")
          preferredTimeDisplay            
            .background(
              GeometryReader { geo in
                Color.clear.preference(
                  key: TimerVisibilityPreferenceKey.self,
                  value: geo.frame(in: .named("timerScroll"))
                )
              }
            )
          activePlayersSection
          benchSection
          if !temporarilyOutPlayers.isEmpty {
            temporarilyOutSection
          }
        }
        .padding()
      }
      .coordinateSpace(name: "timerScroll")
      .onPreferenceChange(TimerVisibilityPreferenceKey.self) { frame in
        let isVisible = frame.maxY > 0
        if showCompactTimer != !isVisible {
          withAnimation(.easeInOut(duration: 0.25)) {
            showCompactTimer = !isVisible
          }
        }
      }
      .safeAreaInset(edge: .top) {
        if showCompactTimer {
          CompactTimerBarView(
            currentPlayDuration: timerViewModel?.elapsedTime ?? 0,
            preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds,
            onTap: {
              withAnimation {
                scrollProxy.scrollTo("timerControls", anchor: .top)
              }
            }
          )
          .transition(.move(edge: .top).combined(with: .opacity))
        }
      }
      .safeAreaInset(edge: .bottom) {
        pinnedSubstituteButton
          .opacity(showPinnedButton ? 1 : 0)
          .offset(y: showPinnedButton ? 0 : 40)
      }
      .onAppear {
        guard !showPinnedButton else { return }
        withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
          showPinnedButton = true
        }
      }
    }
  }

  // MARK: - Pinned Substitute Button

  private var pinnedSubstituteButton: some View {
    VStack(spacing: 0) {
      Divider()
      substituteButtonSection
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    .glassEffect(.regular.interactive(), in: .rect)
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
    let currentDuration = timerViewModel?.elapsedTime ?? 0

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
      onPlayerTap: { player in activeSheet = .playerActions(player) },
      onReorder: { self.reorderPlayers($0, role: .active) }
    )
  }

  // MARK: - Bench Section

  private var benchSection: some View {
    BenchSectionView(
      players: benchedPlayers,
      activePlayersCount: activePlayers.count,
      maxActiveCount: configuration.activePlayersCount,
      onPlayerTap: { player in activeSheet = .playerActions(player) },
      onActivatePlayer: activatePlayer,
      onReorder: { self.reorderPlayers($0, role: .bench) }
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
        activeSheet = nil
      }
    )
  }

  // MARK: - Player Actions Sheet

  private func playerActionsSheet(player: Player) -> some View {
    PlayerActionsSheetView(
      player: player,
      canActivate: activePlayers.count < configuration.activePlayersCount,
      onSubstituteOut: {
        activeSheet = .manualSubstitution(playerToSubOut: player)
      },
      onActivatePlayer: {
        activatePlayer(player)
        activeSheet = nil
      },
      onMarkTemporarilyOut: {
        markPlayerTemporarilyOut(player)
        activeSheet = nil
      },
      onReturnToBench: {
        returnPlayerToBench(player)
        activeSheet = nil
      },
      onClose: {
        activeSheet = nil
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

  /// Syncs a role-scoped order (players is already `@Query(sort: \Player.sortOrder)`,
  /// so filtering it preserves roster order) against current player statuses: adds
  /// players missing from the order, drops ones that changed status.
  func syncOrderManager(role: PlayerOrderRole, status: PlayerStatus) {
    let manager = orderManager(for: role)
    let currentPlayers = players.filter { $0.status == status }

    for player in currentPlayers {
      if manager.position(of: player.id) == nil {
        manager.addPlayer(player.id)
      }
    }

    let currentIds = Set(currentPlayers.map { $0.id })
    manager.playerOrder.removeAll { !currentIds.contains($0) }
    manager.updatedDate = Date()
  }

  func loadOrder(for role: PlayerOrderRole) {
    switch role {
    case .bench:
      benchOrder = orderManager(for: role).playerOrder
    case .active:
      activeOrder = orderManager(for: role).playerOrder
    }
  }

  func reorderPlayers(_ reorderedPlayers: [Player], role: PlayerOrderRole) {
    let newOrder = reorderedPlayers.map { $0.id }

    switch role {
    case .bench:
      benchOrder = newOrder
    case .active:
      activeOrder = newOrder
    }

    let manager = orderManager(for: role)
    manager.playerOrder.removeAll()
    manager.playerOrder.append(contentsOf: newOrder)
    manager.updatedDate = Date()
  }

  func toggleTimer() {
    guard let vm = timerViewModel else { return }
    if vm.isRunning {
      vm.pauseTimer()
      cancelOvertimeUpdate()
      updateLiveActivity()
    } else {
      autoActivateInitialPlayersIfNeeded()
      createOrUpdateSession()
      vm.startTimer()
      startLiveActivity()
    }
  }

  func resetTimer() {
    guard let vm = timerViewModel else { return }
    vm.resetTimer()
    endLiveActivity()
  }

  private func autoActivateInitialPlayersIfNeeded() {
    guard activePlayers.isEmpty else { return }
    let allFilteredPlayers = activePlayers + benchedPlayers + temporarilyOutPlayers
    let playersToActivate = min(configuration.activePlayersCount, allFilteredPlayers.count)
    let now = Date()
    for i in 0..<playersToActivate where i < allFilteredPlayers.count {
      allFilteredPlayers[i].status = .active
      allFilteredPlayers[i].activatedAtDate = now
      allFilteredPlayers[i].currentPlayDuration = 0
      activeManager.addPlayer(allFilteredPlayers[i].id)
    }
    activeOrder = activeManager.playerOrder
  }

  private func updatePlayerTimes() {
    let now = Date()

    for player in activePlayers {
      player.currentPlayDuration = now.timeIntervalSince(player.activatedAtDate)
    }

    if let activeSession = sessions.first(where: { $0.isActive }) {
      activeSession.duration = now.timeIntervalSince(activeSession.startDate)
    }
    checkPreferredTimeAlert()
  }

  private func checkPreferredTimeAlert() {
    guard let timerElapsed = timerViewModel?.elapsedTime else { return }
    let preferredTime = TimeInterval(configuration.preferredPlayTimeSeconds)
    if preferredTime > 0, timerElapsed == preferredTime {
      triggerPreferredTimeAlert()
    }
  }

  // MARK: - Substitution

  func performAutomaticSubstitution() {
    guard
      let playerToSubOut = activePlayers.first,
      let playerToSubIn = benchedPlayers.first
    else { return }
    performSubstitution(subOut: playerToSubOut, subIn: playerToSubIn)
  }

  func performManualSubstitution(subOut: Player, subIn: Player) {
    performSubstitution(subOut: subOut, subIn: subIn)
    activeSheet = nil
  }

  private func performSubstitution(subOut: Player, subIn: Player) {
    let now = Date()
    let wasRunning = timerViewModel?.isRunning ?? false

    if wasRunning {
      timerViewModel?.pauseTimer()
    }

    let timePlayedThisSegment = now.timeIntervalSince(subOut.activatedAtDate)
    subOut.totalPlayTime += timePlayedThisSegment
    subOut.status = .benched
    subOut.currentPlayDuration = 0

    subIn.status = .active
    subIn.activatedAtDate = now
    subIn.currentPlayDuration = 0

    benchManager.removePlayer(subIn.id)
    benchManager.addPlayer(subOut.id)
    benchOrder = benchManager.playerOrder

    activeManager.removePlayer(subOut.id)
    activeManager.addPlayer(subIn.id)
    activeOrder = activeManager.playerOrder

    if let activeSession = sessions.first(where: { $0.isActive }) {
      activeSession.substitutionCount += 1
    }

    timerViewModel?.resetTimer()

    if wasRunning {
      timerViewModel?.startTimer()
    }

    provideHapticFeedback()
    updateLiveActivity()
    if wasRunning {
      scheduleOvertimeUpdate()
    }
  }  // MARK: - Player Status

  func activatePlayer(_ player: Player) {
    player.status = .active
    player.activatedAtDate = Date()
    player.currentPlayDuration = 0
    benchManager.removePlayer(player.id)
    benchOrder = benchManager.playerOrder
    activeManager.addPlayer(player.id)
    activeOrder = activeManager.playerOrder
    updateLiveActivity()
  }

  func markPlayerTemporarilyOut(_ player: Player) {
    if player.status == .active {
      let timePlayedThisSegment = Date().timeIntervalSince(player.activatedAtDate)
      player.totalPlayTime += timePlayedThisSegment
      activeManager.removePlayer(player.id)
      activeOrder = activeManager.playerOrder
    }
    player.status = .temporarilyOut
    updateLiveActivity()
  }

  func returnPlayerToBench(_ player: Player) {
    player.status = .benched
    benchManager.addPlayer(player.id)
    benchOrder = benchManager.playerOrder
    updateLiveActivity()
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

  // MARK: - Live Activity Management

  private func startLiveActivity() {
    if #available(iOS 16.2, *) {
      let sessionName: String
      if let activeSession = sessions.first(where: { $0.isActive }) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        sessionName = formatter.string(from: activeSession.startDate)
      } else {
        sessionName = "Practice Session"
      }

      LiveActivityManager.shared.startActivity(
        sessionName: sessionName,
        isRunning: timerViewModel?.isRunning ?? false,
        timerStartDate: timerViewModel?.timerStartDate ?? Date(),
        accumulatedTime: timerViewModel?.accumulatedTime ?? 0,
        preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds,
        activePlayersCount: activePlayers.count,
        benchedPlayersCount: benchedPlayers.count,
        subOutPlayerName: activePlayers.first?.name,
        subInPlayerName: benchedPlayers.first?.name
      )
      scheduleOvertimeUpdate()
    }
  }

  private func updateLiveActivity() {
    if #available(iOS 16.2, *) {
      LiveActivityManager.shared.updateActivity(
        isRunning: timerViewModel?.isRunning ?? false,
        timerStartDate: timerViewModel?.timerStartDate ?? Date(),
        accumulatedTime: timerViewModel?.accumulatedTime ?? 0,
        preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds,
        activePlayersCount: activePlayers.count,
        benchedPlayersCount: benchedPlayers.count,
        subOutPlayerName: activePlayers.first?.name,
        subInPlayerName: benchedPlayers.first?.name
      )
    }
  }

  private func endLiveActivity() {
    if #available(iOS 16.2, *) {
      cancelOvertimeUpdate()
      LiveActivityManager.shared.endActivity()
    }
  }

  private func scheduleOvertimeUpdate() {
    cancelOvertimeUpdate()

    let preferredSeconds = configuration.preferredPlayTimeSeconds
    guard preferredSeconds > 0 else { return }

    let accumulated = timerViewModel?.accumulatedTime ?? 0
    let delay = TimeInterval(preferredSeconds) - accumulated
    guard delay > 0 else { return }

    let work = DispatchWorkItem { [self] in
      updateLiveActivity()
    }
    overtimeUpdateWork = work
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
  }

  private func cancelOvertimeUpdate() {
    overtimeUpdateWork?.cancel()
    overtimeUpdateWork = nil
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
