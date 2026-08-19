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
// This screen coordinates 11 extracted subviews plus their SwiftData/Live
// Activity wiring, which pushes the file past SwiftLint's default 400-line
// ceiling; splitting it further is a candidate for a future pass, not this
// lint-baseline ticket.
// swiftlint:disable file_length
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

// This view's `body` and its state-management helpers exceed the default
// 250-line ceiling; extracting further is future work, not this ticket.
// swiftlint:disable:next type_body_length
struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.sortOrder) var players: [Player]
    @Query private var configurations: [AppConfiguration]
    @Query(sort: \Session.startDate, order: .reverse) var sessions: [Session]
    @Query private var orderManagers: [OrderManager]
    @Query private var teams: [Team]
    @Query private var games: [Game]

    @State var timerViewModel: TimerViewModel?
    @State private var activeSheet: TimerSheet?
    @State private var cachedManagers: [PlayerOrderRole: OrderManager] = [:]
    @State private var currentGame: Game?
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

    /// The app's one auto-created `Team` (per #59's migration guarantee) —
    /// lazily created here to also cover installs where migration never ran
    /// (a fresh install, or `--uitesting`'s in-memory fixture store), since
    /// neither of those goes through `SchemaMigrationPlan`.
    var team: Team {
        if let existing = teams.first {
            return existing
        }
        let newTeam = Team(
            name: "",
            sport: "",
            preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds,
            activePlayersCount: configuration.activePlayersCount
        )
        modelContext.insert(newTeam)
        return newTeam
    }

    var gameManager: GameManager { GameManager(context: modelContext) }

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
        guard let game = currentGame else { return [] }
        let active = players.filter { gameManager.status(playerId: $0.id, in: game) == .active }

        return active.sorted { player1, player2 in
            let pos1 = game.activeOrder.firstIndex(of: player1.id)
            let pos2 = game.activeOrder.firstIndex(of: player2.id)

            if let pos1, let pos2 {
                return pos1 < pos2
            } else if pos1 != nil {
                return true
            } else if pos2 != nil {
                return false
            } else {
                return gameManager.currentPlayDuration(playerId: player1.id, in: game)
                    > gameManager.currentPlayDuration(playerId: player2.id, in: game)
            }
        }
    }

    var benchedPlayers: [Player] {
        guard let game = currentGame else { return [] }
        let benched = players.filter { gameManager.status(playerId: $0.id, in: game) == .benched }

        return benched.sorted { player1, player2 in
            let pos1 = game.benchOrder.firstIndex(of: player1.id)
            let pos2 = game.benchOrder.firstIndex(of: player2.id)

            if let pos1, let pos2 {
                return pos1 < pos2
            } else if pos1 != nil {
                return true
            } else if pos2 != nil {
                return false
            } else {
                return player1.sortOrder < player2.sortOrder
            }
        }
    }

    /// `Game.temporarilyOut` is an unordered `Set`, so this relies on
    /// `players` already being `@Query(sort: \Player.sortOrder)` for a
    /// stable, roster-order display - matching this section's old
    /// `Player.status`-filtered behavior exactly.
    var temporarilyOutPlayers: [Player] {
        guard let game = currentGame else { return [] }
        return players.filter { gameManager.status(playerId: $0.id, in: game) == .temporarilyOut }
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
                resolveOrCreateGame()
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
            scrollableContent(scrollProxy: scrollProxy)
        }
    }

    private func scrollableContent(scrollProxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                timerControlsSection
                    .id("timerControls")
                preferredTimeDisplay
                    .background(timerVisibilityTracker)
                activePlayersSection
                benchSection
                if !temporarilyOutPlayers.isEmpty {
                    temporarilyOutSection
                }
            }
            .padding()
        }
        .coordinateSpace(name: "timerScroll")
        .onPreferenceChange(TimerVisibilityPreferenceKey.self, perform: handleTimerVisibilityChange)
        .safeAreaInset(edge: .top) {
            compactTimerBar(scrollProxy: scrollProxy)
        }
        .safeAreaInset(edge: .bottom) {
            pinnedSubstituteButton
                .opacity(showPinnedButton ? 1 : 0)
                .offset(y: showPinnedButton ? 0 : 40)
        }
        .onAppear(perform: animatePinnedButtonIn)
    }

    private var timerVisibilityTracker: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: TimerVisibilityPreferenceKey.self,
                value: geo.frame(in: .named("timerScroll"))
            )
        }
    }

    private func handleTimerVisibilityChange(_ frame: CGRect) {
        let isVisible = frame.maxY > 0
        if showCompactTimer != !isVisible {
            withAnimation(.easeInOut(duration: 0.25)) {
                showCompactTimer = !isVisible
            }
        }
    }

    @ViewBuilder
    private func compactTimerBar(scrollProxy: ScrollViewProxy) -> some View {
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

    private func animatePinnedButtonIn() {
        guard !showPinnedButton else { return }
        withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
            showPinnedButton = true
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
            currentPlayDuration: { resolvedCurrentPlayDuration(for: $0) },
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
            totalPlayTime: { resolvedTotalPlayTime(for: $0) },
            onPlayerTap: { player in activeSheet = .playerActions(player) },
            onActivatePlayer: activatePlayer,
            onReorder: { self.reorderPlayers($0, role: .bench) }
        )
    }

    // MARK: - Temporarily Out Section

    private var temporarilyOutSection: some View {
        TemporarilyOutSectionView(
            players: temporarilyOutPlayers,
            totalPlayTime: { resolvedTotalPlayTime(for: $0) },
            onReturnToBench: returnPlayerToBench
        )
    }

    /// `GameManager.currentPlayDuration`/`totalPlayTime` resolved for a
    /// single `player`, so section/row views receive display values as
    /// parameters instead of reading `Player.currentPlayDuration`/
    /// `totalPlayTime` directly (see issue #60).
    private func resolvedCurrentPlayDuration(for player: Player) -> TimeInterval {
        guard let game = currentGame else { return 0 }
        return gameManager.currentPlayDuration(playerId: player.id, in: game)
    }

    private func resolvedTotalPlayTime(for player: Player) -> TimeInterval {
        guard let game = currentGame else { return 0 }
        return gameManager.totalPlayTime(playerId: player.id, in: game)
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
        let status = currentGame.map { gameManager.status(playerId: player.id, in: $0) } ?? .benched
        return PlayerActionsSheetView(
            player: player,
            status: status,
            currentPlayDuration: resolvedCurrentPlayDuration(for: player),
            totalPlayTime: resolvedTotalPlayTime(for: player),
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

    /// Resolves `currentGame` to the `Team`'s open `Game` (no `endDate` yet),
    /// or creates one. A fresh `Game` only exists here (no open `Game` found)
    /// in two cases: a real user's very first launch after this ticket ships
    /// (migration only produces closed, historical `Game`s from old
    /// `Session`s - never an open one), or the `--uitesting` fixture launch
    /// (no `Team`/`Game` at all). `GameManager.seedFromLegacyStatus` bridges
    /// both by carrying the current `Player.status`-driven state into the
    /// new `Game` exactly once, at creation.
    func resolveOrCreateGame() {
        guard currentGame == nil else { return }
        let resolvedTeam = team

        if let openGame = games.first(where: { $0.team?.id == resolvedTeam.id && $0.endDate == nil }) {
            currentGame = openGame
            return
        }

        let newGame = Game(
            preferredPlayTimeSeconds: configuration.preferredPlayTimeSeconds,
            activePlayersCount: configuration.activePlayersCount,
            team: resolvedTeam
        )
        modelContext.insert(newGame)
        let snapshot = LegacyRotationSnapshot(
            activePlayers: players.filter { $0.status == .active },
            benchedPlayers: players.filter { $0.status == .benched },
            temporarilyOutPlayers: players.filter { $0.status == .temporarilyOut },
            existingActiveOrder: activeManager.playerOrder,
            existingBenchOrder: benchManager.playerOrder
        )
        gameManager.seedFromLegacyStatus(snapshot, in: newGame)
        currentGame = newGame
    }

    func reorderPlayers(_ reorderedPlayers: [Player], role: PlayerOrderRole) {
        guard let game = currentGame else { return }
        let newOrder = reorderedPlayers.map { $0.id }
        let bucket: RotationBucket = role == .active ? .active : .benched
        gameManager.setOrder(newOrder, for: bucket, in: game)
    }

    func toggleTimer() {
        guard let viewModel = timerViewModel else { return }
        if viewModel.isRunning {
            viewModel.pauseTimer()
            cancelOvertimeUpdate()
            updateLiveActivity()
        } else {
            autoActivateInitialPlayersIfNeeded()
            createOrUpdateSession()
            viewModel.startTimer()
            startLiveActivity()
        }
    }

    func resetTimer() {
        guard let viewModel = timerViewModel else { return }
        viewModel.resetTimer()
        endLiveActivity()
    }

    private func autoActivateInitialPlayersIfNeeded() {
        guard let game = currentGame, activePlayers.isEmpty else { return }
        let allFilteredPlayers = activePlayers + benchedPlayers + temporarilyOutPlayers
        let playersToActivate = min(configuration.activePlayersCount, allFilteredPlayers.count)
        let now = Date()
        for index in 0..<playersToActivate where index < allFilteredPlayers.count {
            let player = allFilteredPlayers[index]
            do {
                try gameManager.transition(playerId: player.id, to: .active, in: game)
            } catch {
                // `player` was just pulled from this same context's query results, so
                // `playerNotFound` here would mean a real programming bug, not a
                // recoverable runtime state.
                assertionFailure(
                    "GameManager.transition failed for a player already resolved from the context: \(error)"
                )
            }
            player.status = .active
            player.activatedAtDate = now
            player.currentPlayDuration = 0
        }
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

        activeManager.removePlayer(subOut.id)
        activeManager.addPlayer(subIn.id)

        // Substitution stays on the Player.status/OrderManager path above
        // (rewiring it fully onto GameManager is #61's job) but also mirrors
        // the swap into Game/Stint here, so the Game-derived duration values
        // (see PlayerActionsSheetView/row views) stay correct in the interim.
        if let game = currentGame {
            do {
                try gameManager.manualSubstitution(outgoing: subOut.id, incoming: subIn.id, game: game)
            } catch {
                // Unlike the transition() sites above, the legacy path and this mirror
                // aren't the same call, so a throw here is a real drift signal between
                // Player.status/OrderManager and Game/Stint, not just a defensive check.
                assertionFailure(
                    "GameManager.manualSubstitution mirror failed, Game/Stint state has drifted from legacy path: "
                        + "\(error)"
                )
            }
        }

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

    // Activate/mark-temporarily-out/return-to-bench read/write Game via
    // GameManager exclusively now (issue #60) - the Player.status write in
    // each is a display-only mirror for SettingsView, which still reads
    // Player.status directly until #62 rewires it onto TeamManager/Game;
    // TimerView itself never reads these three fields back. Tracked as
    // tech debt to remove in #62 alongside Player.status's deletion.

    func activatePlayer(_ player: Player) {
        guard let game = currentGame else { return }
        do {
            try gameManager.transition(playerId: player.id, to: .active, in: game)
        } catch {
            assertionFailure("GameManager.transition failed for a player already resolved from the context: \(error)")
        }

        player.status = .active
        player.activatedAtDate = Date()
        player.currentPlayDuration = 0
        updateLiveActivity()
    }

    func markPlayerTemporarilyOut(_ player: Player) {
        guard let game = currentGame else { return }
        let wasActive = gameManager.status(playerId: player.id, in: game) == .active
        try? gameManager.transition(playerId: player.id, to: .temporarilyOut, in: game)

        if wasActive {
            let timePlayedThisSegment = Date().timeIntervalSince(player.activatedAtDate)
            player.totalPlayTime += timePlayedThisSegment
        }
        player.status = .temporarilyOut
        updateLiveActivity()
    }

    func returnPlayerToBench(_ player: Player) {
        guard let game = currentGame else { return }
        try? gameManager.transition(playerId: player.id, to: .benched, in: game)

        player.status = .benched
        updateLiveActivity()
    }

    // MARK: - Session & Feedback

    private func createOrUpdateSession() {
        guard !sessions.contains(where: { $0.isActive }) else { return }
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

/// Registers the full app schema (see `SchemaV2.models`) so `TimerView`'s
/// `@Query`s for `OrderManager`/`Team`/`Game`/`Stint` don't crash at preview
/// render time.
private let previewSchemaModels: [any PersistentModel.Type] = [
    Player.self, AppConfiguration.self, Session.self, OrderManager.self,
    Team.self, RosterMembership.self, Game.self, Stint.self
]

#Preview("Empty State") {
    TimerView()
        .modelContainer(for: previewSchemaModels, inMemory: true)
}

/// Preview providers are compile-time-only and never execute in a shipped
/// build, so a failed `ModelContainer` creation here can only mean a bug in
/// this preview's setup - `try!` surfaces that immediately instead of
/// silently producing a broken preview.
private func makeMainTimerPreviewContainer() -> ModelContainer {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: Schema(previewSchemaModels),
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
    player1.activatedAtDate = Date().addingTimeInterval(-120)

    let player2 = Player(name: "Bob", sortOrder: 1)
    player2.status = .active
    player2.currentPlayDuration = 95
    player2.activatedAtDate = Date().addingTimeInterval(-95)

    let player3 = Player(name: "Charlie", sortOrder: 2)
    player3.status = .active
    player3.currentPlayDuration = 110
    player3.activatedAtDate = Date().addingTimeInterval(-110)

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

    return container
}

#Preview("Main Timer View") {
    TimerView()
        .modelContainer(makeMainTimerPreviewContainer())
}
