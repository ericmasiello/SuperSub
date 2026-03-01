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
    @Query private var benchManagers: [BenchManager]

    @State var timerViewModel: TimerViewModel?
    @State var showingManualSubstitution = false
    @State var selectedPlayerToSubOut: Player?
    @State var showingPlayerActions: Player?
    @State private var benchOrder: [UUID] = []
    @State private var cachedBenchManager: BenchManager?

    var configuration: AppConfiguration {
        if let config = configurations.first {
            return config
        } else {
            let newConfig = AppConfiguration()
            modelContext.insert(newConfig)
            return newConfig
        }
    }

    var benchManager: BenchManager {
        if let cached = cachedBenchManager {
            return cached
        }

        if let manager = benchManagers.first {
            cachedBenchManager = manager
            return manager
        } else {
            let newManager = BenchManager()
            modelContext.insert(newManager)
            try? modelContext.save()
            cachedBenchManager = newManager
            return newManager
        }
    }

    var activePlayers: [Player] {
        players.filter { $0.status == .active }
            .sorted(by: { $0.currentPlayDuration > $1.currentPlayDuration })
    }

    var benchedPlayers: [Player] {
        let benched = players.filter { $0.status == .benched }

        // Use the state-managed bench order for immediate UI updates
        let orderToUse = benchOrder.isEmpty ? (benchManagers.first?.playerOrder ?? []) : benchOrder

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
                // Initialize cached bench manager first
                _ = benchManager
                initializeViewModel(allPlayers: players)
                syncBenchManager()
                loadBenchOrder()
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
            onActivatePlayer: activatePlayer,
            onReorder: reorderBench
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

    func syncBenchManager() {
        let manager = benchManager
        let currentBenched = players.filter { $0.status == .benched }.sorted {
            $0.sortOrder < $1.sortOrder
        }

        // Add any benched players that aren't in the manager (in sortOrder)
        for player in currentBenched {
            if manager.position(of: player.id) == nil {
                manager.addPlayer(player.id)
            }
        }

        // Remove any players that are no longer benched
        let benchedIds = Set(currentBenched.map { $0.id })
        manager.playerOrder.removeAll { !benchedIds.contains($0) }
        manager.updatedDate = Date()
    }

    func loadBenchOrder() {
        benchOrder = benchManager.playerOrder
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
        let timerElapsed = timerViewModel?.elapsedTime ?? 0
        for i in 0 ..< playersToActivate where i < allFilteredPlayers.count {
            allFilteredPlayers[i].status = .active
            allFilteredPlayers[i].activatedAtTime = timerElapsed
            allFilteredPlayers[i].currentPlayDuration = 0 // Will be calculated based on activatedAtTime
        }
    }

    private func updatePlayerTimes() {
        guard let timerElapsed = timerViewModel?.elapsedTime else { return }

        // Calculate currentPlayDuration based on when each player was activated
        // This preserves play time for players who aren't being substituted
        for player in activePlayers {
            player.currentPlayDuration = timerElapsed - player.activatedAtTime
        }

        if let activeSession = sessions.first(where: { $0.isActive }) {
            activeSession.duration = Date().timeIntervalSince(activeSession.startDate)
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
            let playerToSubOut = activePlayers.max(by: { $0.currentPlayDuration < $1.currentPlayDuration }),
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
        guard let timerElapsed = timerViewModel?.elapsedTime else { return }

        let wasRunning = timerViewModel?.isRunning ?? false

        // Pause the timer if it's running
        if wasRunning {
            timerViewModel?.pauseTimer()
        }

        // For all active players EXCEPT the one being subbed out,
        // preserve their accumulated play time by adjusting their activatedAtTime
        // to account for the timer reset
        for player in activePlayers where player.id != subOut.id {
            let currentAccumulatedTime = timerElapsed - player.activatedAtTime
            // After timer resets to 0, this negative activatedAtTime will preserve their time
            player.activatedAtTime = -currentAccumulatedTime
        }

        // Add the time this player was actually active to their total
        let timePlayedThisSegment = timerElapsed - subOut.activatedAtTime
        subOut.totalPlayTime += timePlayedThisSegment
        subOut.status = .benched
        subOut.currentPlayDuration = 0

        // Set when the new player became active (will be 0 after timer reset)
        // This ensures they start with 0 current play duration
        subIn.status = .active
        subIn.activatedAtTime = 0
        subIn.currentPlayDuration = 0

        // Update bench order: remove the player coming in, then add the player going out
        benchManager.removePlayer(subIn.id)
        benchManager.addPlayer(subOut.id)
        benchOrder = benchManager.playerOrder

        if let activeSession = sessions.first(where: { $0.isActive }) {
            activeSession.substitutionCount += 1
        }

        // Reset the timer to 0
        timerViewModel?.resetTimer()

        // Resume the timer if it was running
        if wasRunning {
            timerViewModel?.startTimer()
        }

        provideHapticFeedback()
    }

    // MARK: - Player Status

    func activatePlayer(_ player: Player) {
        guard let timerElapsed = timerViewModel?.elapsedTime else { return }
        player.status = .active
        player.activatedAtTime = timerElapsed
        player.currentPlayDuration = 0 // Will be calculated based on activatedAtTime
        benchManager.removePlayer(player.id)
        benchOrder = benchManager.playerOrder
    }

    func markPlayerTemporarilyOut(_ player: Player) {
        if player.status == .active {
            guard let timerElapsed = timerViewModel?.elapsedTime else { return }
            let timePlayedThisSegment = timerElapsed - player.activatedAtTime
            player.totalPlayTime += timePlayedThisSegment
        }
        player.status = .temporarilyOut
    }

    func returnPlayerToBench(_ player: Player) {
        player.status = .benched
        benchManager.addPlayer(player.id)
        benchOrder = benchManager.playerOrder
    }

    func reorderBench(_ reorderedPlayers: [Player]) {
        let newOrder = reorderedPlayers.map { $0.id }

        // Immediately update the state for instant UI feedback
        benchOrder = newOrder

        // Get the first bench manager (or create one)
        guard let manager = benchManagers.first else {
            let newManager = BenchManager()
            newManager.playerOrder = newOrder
            newManager.updatedDate = Date()
            modelContext.insert(newManager)
            return
        }

        // Update the bench manager with new order
        manager.playerOrder.removeAll()
        manager.playerOrder.append(contentsOf: newOrder)
        manager.updatedDate = Date()
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
