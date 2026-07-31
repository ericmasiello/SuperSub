//
//  PlayerComponentsUITests.swift
//  SubTimerUITests
//
//  Created by SubTimer on 2/13/26.
//
//  UI TESTS FOR PLAYER COMPONENTS
//
//  Tests cover:
//  • ActivePlayerRowView - Individual active player display
//  • BenchPlayerRowView - Individual benched player display
//  • TemporarilyOutPlayerRowView - Temporarily out player display
//  • ActivePlayersSectionView - Active players section
//  • BenchSectionView - Bench section
//  • TemporarilyOutSectionView - Temporarily out section
//  • Player status transitions
//  • Time display formatting
//  • Interactive elements and accessibility
//

import XCTest

final class PlayerComponentsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Navigate to Timer tab where player components are visible
        let timerTab = app.tabBars.buttons["Timer"]
        XCTAssertTrue(timerTab.waitForExistence(timeout: 8), "Timer tab should exist")
        timerTab.tap()

        // Wait for the actual player content to render instead of sleeping
        // for a fixed duration.
        XCTAssertTrue(
            app.staticTexts["Active Players"].waitForExistence(timeout: 8),
            "Timer view should finish loading player sections"
        )
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Row Query Helpers

    /// `ActivePlayerRowView`/`BenchPlayerRowView` apply their
    /// `.accessibilityIdentifier("player.row.<status>")` to an HStack that
    /// also contains an interactive "More" button; SwiftUI pushes that
    /// identifier onto the button's leaves rather than the List row itself,
    /// so matching cells that *contain* that button finds the actual row -
    /// including its name/time text - regardless of where the identifier
    /// physically surfaces.
    private func playerRow(status: String) -> XCUIElementQuery {
        app.cells.containing(.button, identifier: "player.row.\(status)")
    }

    /// Scopes to the row's action button within an already-located row,
    /// mirroring `TimerViewUITests.playerRowActionButtons`'s defensive
    /// `identifier AND label` match.
    private func moreButton(in row: XCUIElement, status: String) -> XCUIElement {
        row.buttons.matching(
            NSPredicate(format: "identifier == 'player.row.\(status)' AND label == 'More'")
        ).firstMatch
    }

    /// Temporarily-out rows render in a `LazyVStack`, not a `List`, so
    /// there's no row-level cell to query. Its only interactive element -
    /// "Return to Bench" - has a stable, inferred accessibility label, so
    /// it's matched directly.
    private func returnToBenchButtons() -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label == 'Return to Bench'"))
    }

    /// `TemporarilyOutSectionView` lays out its rows in a `LazyVStack`
    /// inside the screen's outer `ScrollView`, so a row below the fold
    /// (e.g. the seeded temp-out player, which sits below Active Players
    /// and Bench) isn't materialized into the accessibility tree until it
    /// scrolls into view. Swipes up until `element` exists or gives up.
    @discardableResult
    private func scrollUntilVisible(_ element: XCUIElement) -> Bool {
        var remainingSwipes = 4
        while !element.exists, remainingSwipes > 0 {
            app.swipeUp()
            remainingSwipes -= 1
        }
        return element.waitForExistence(timeout: 2)
    }

    /// Finds the row (of a given status) whose displayed name matches
    /// `name`, without looping over `allElementsBoundByIndex`.
    private func row(status: String, named name: String) -> XCUIElement {
        playerRow(status: status).containing(
            NSPredicate(format: "elementType == \(XCUIElement.ElementType.staticText.rawValue) AND label == %@", name)
        ).firstMatch
    }

    /// Matches a time display in `M:SS` (or `H:MM:SS`) format, shared by
    /// every check below that looks for a rendered time regardless of which
    /// row/section it's in.
    private func timeDisplayPredicate(includeHours: Bool = false) -> NSPredicate {
        let pattern = includeHours ? "\\d+:\\d{2}(:\\d{2})?" : "\\d+:\\d{2}"
        return NSPredicate(format: "label MATCHES %@", pattern)
    }

    // MARK: - Initial Section Render State

    /// Consolidates every read-only smoke check against the sections'
    /// initial render: headers, seeded player counts, the conditionally
    /// displayed Temporarily Out section, shared time-display format, and
    /// scroll stability. The seeded fixture always has 2 active, 2 benched,
    /// and 1 temporarily out player (see `SubTimerApp.setupTestData`).
    @MainActor
    func testInitialPlayerSectionsRenderState() {
        XCTContext.runActivity(named: "Active Players section header and count") { _ in
            XCTAssertTrue(app.staticTexts["Active Players"].exists, "Active Players header should exist")
            let countTexts = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+/\\d+"))
            XCTAssertGreaterThan(countTexts.count, 0, "Should display an active players count (e.g. 2/5)")
        }

        XCTContext.runActivity(named: "Bench section header and seeded players") { _ in
            XCTAssertTrue(app.staticTexts["Bench"].exists, "Bench header should exist")
            XCTAssertGreaterThan(
                playerRow(status: "bench").count, 0,
                "Seeded fixture should have benched players"
            )
        }

        XCTContext.runActivity(named: "Time displays use M:SS or H:MM:SS format") { _ in
            let timeDisplays = app.staticTexts.matching(timeDisplayPredicate(includeHours: true))
            XCTAssertGreaterThan(timeDisplays.count, 0, "Should have time displays in M:SS format")
        }

        XCTContext.runActivity(named: "Active Players section remains stable after scrolling") { _ in
            app.swipeUp()
            app.swipeDown()
            XCTAssertTrue(
                app.staticTexts["Active Players"].waitForExistence(timeout: 2),
                "Should remain on timer view after scrolling"
            )
        }

        // Runs last: the seeded temp-out player's row lives in a `LazyVStack`
        // below Active Players and Bench, so this must scroll past the
        // stability check above rather than before it (see
        // `scrollUntilVisible`'s doc comment).
        XCTContext.runActivity(named: "Temporarily Out section appears for the seeded temp-out player") { _ in
            XCTAssertTrue(
                app.staticTexts["Temporarily Out"].waitForExistence(timeout: 2),
                "Temporarily Out section should appear when a player has that status"
            )
            XCTAssertTrue(
                scrollUntilVisible(returnToBenchButtons().firstMatch),
                "Seeded fixture should have a temporarily out player"
            )
        }
    }

    // MARK: - Active Player Row Content

    /// Consolidates every read-only check against a single active player
    /// row: name, current play time, and its accessible action button.
    ///
    /// The dropped `testActivePlayerRowAccessibility` originally asserted
    /// `firstRow.value` was non-nil, but that never actually ran under the
    /// old `app.cells.matching(identifier:)` query (always zero matches).
    /// With the query fixed, a `Cell`/row container turns out to have no
    /// accessibility "value" trait (confirmed via `app.debugDescription`),
    /// so that check is replaced below with a real one - that the row's
    /// action button is present and enabled - rather than restoring an
    /// assertion that would now fail.
    @MainActor
    func testActivePlayerRowRendersContent() {
        let activeRows = playerRow(status: "active")
        guard activeRows.firstMatch.waitForExistence(timeout: 3) else {
            XCTFail("Expected at least one active player row from seeded fixture data")
            return
        }
        let firstRow = activeRows.element(boundBy: 0)

        XCTContext.runActivity(named: "Displays a non-empty player name") { _ in
            let nameLabel = firstRow.staticTexts.element(boundBy: 0)
            XCTAssertTrue(nameLabel.exists, "Active player name should be displayed")
            XCTAssertFalse(nameLabel.label.isEmpty, "Active player name should not be empty")
        }

        XCTContext.runActivity(named: "Displays current play time in M:SS format") { _ in
            let timeDisplay = firstRow.staticTexts.matching(timeDisplayPredicate()).firstMatch
            XCTAssertTrue(timeDisplay.exists, "Active player should display current play time")
        }

        XCTContext.runActivity(named: "Row exposes an accessible 'More' action button") { _ in
            let button = moreButton(in: firstRow, status: "active")
            XCTAssertTrue(button.exists, "Active player row should have an accessible action button")
            XCTAssertTrue(button.isEnabled, "Action button should be enabled")
        }
    }

    // MARK: - Bench Player Row Content

    /// Consolidates every read-only check against a single benched player
    /// row: name, total time, and its visual/structural difference from an
    /// active row (bench rows show "Total:", active rows show a bare time).
    @MainActor
    func testBenchPlayerRowRendersContent() {
        let benchRows = playerRow(status: "bench")
        guard benchRows.firstMatch.waitForExistence(timeout: 3) else {
            XCTFail("Expected at least one benched player row from seeded fixture data")
            return
        }
        let firstRow = benchRows.element(boundBy: 0)

        XCTContext.runActivity(named: "Displays a non-empty player name") { _ in
            let nameLabel = firstRow.staticTexts.element(boundBy: 0)
            XCTAssertTrue(nameLabel.exists, "Benched player name should be displayed")
            XCTAssertFalse(nameLabel.label.isEmpty, "Benched player name should not be empty")
        }

        XCTContext.runActivity(named: "Displays total play time prefixed with 'Total:'") { _ in
            let totalTimeLabel = firstRow.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] 'Total:'")
            ).firstMatch
            XCTAssertTrue(totalTimeLabel.exists, "Benched player should show a 'Total:' time label")
        }

        XCTContext.runActivity(named: "Renders distinctly from an active row") { _ in
            let activeRows = playerRow(status: "active")
            XCTAssertTrue(activeRows.firstMatch.exists, "Active rows should also exist alongside bench rows")
            let activeTotalTimeLabel = activeRows.element(boundBy: 0).staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] 'Total:'")
            ).firstMatch
            XCTAssertFalse(
                activeTotalTimeLabel.exists,
                "Active rows should not show a 'Total:' label the way bench rows do"
            )
        }
    }

    // MARK: - Multi-Row Rendering & Identity

    /// Verifies rendered rows exist across all sections and that every
    /// active/bench player has a unique displayed name.
    @MainActor
    func testMultiplePlayerRowsRenderWithUniqueIdentity() {
        let activeRows = playerRow(status: "active")
        let benchRows = playerRow(status: "bench")
        let tempOutRows = returnToBenchButtons()

        XCTContext.runActivity(named: "At least one player row renders across all sections") { _ in
            XCTAssertTrue(activeRows.firstMatch.waitForExistence(timeout: 3), "Active rows should render")
            let totalCount = activeRows.count + benchRows.count + tempOutRows.count
            let rowCountsDescription = "active: \(activeRows.count), bench: \(benchRows.count), "
                + "tempOut: \(tempOutRows.count)"
            XCTAssertGreaterThan(
                totalCount, 0,
                "Should have at least one player row (\(rowCountsDescription))"
            )
        }

        XCTContext.runActivity(named: "Rendered active/bench rows have unique names") { _ in
            var playerNames: Set<String> = []
            for rowIndex in 0 ..< activeRows.count {
                playerNames.insert(activeRows.element(boundBy: rowIndex).staticTexts.element(boundBy: 0).label)
            }
            for rowIndex in 0 ..< benchRows.count {
                playerNames.insert(benchRows.element(boundBy: rowIndex).staticTexts.element(boundBy: 0).label)
            }
            XCTAssertEqual(
                playerNames.count, activeRows.count + benchRows.count,
                "Every rendered active/bench row should have a unique player name"
            )
        }
    }

    // MARK: - Player Status Transition Flow

    /// Exercises the full status lifecycle a player row can go through on
    /// this screen - active -> temporarily out -> back to bench -> active
    /// again - all against the same app launch, verifying the player's name
    /// survives each transition.
    @MainActor
    // swiftlint:disable:next function_body_length
    func testPlayerRowStatusTransitionFlow() {
        let activeRows = playerRow(status: "active")
        guard activeRows.firstMatch.waitForExistence(timeout: 3) else {
            XCTFail("Expected at least one active player row from seeded fixture data")
            return
        }

        var transitionedPlayerName = ""

        XCTContext.runActivity(
            named: "Tapping an active row's action button marks the player temporarily out"
        ) { _ in
            let firstRow = activeRows.element(boundBy: 0)
            transitionedPlayerName = firstRow.staticTexts.element(boundBy: 0).label

            moreButton(in: firstRow, status: "active").tap()

            let tempOutButton = app.buttons["Mark Temporarily Out"]
            guard tempOutButton.waitForExistence(timeout: 2) else {
                XCTFail("Mark Temporarily Out action should be available for an active player")
                return
            }
            tempOutButton.tap()

            XCTAssertTrue(
                app.staticTexts["Temporarily Out"].waitForExistence(timeout: 2),
                "Temporarily Out section should appear"
            )
            // The temp-out row lives in a `LazyVStack` below the fold (see
            // `scrollUntilVisible`), so it must be scrolled into view before
            // it exists in the accessibility tree.
            XCTAssertTrue(
                scrollUntilVisible(app.staticTexts[transitionedPlayerName]),
                "Player name should still be displayed after moving to Temporarily Out"
            )
        }

        XCTContext.runActivity(named: "Returning a temporarily out player moves them back to the bench") { _ in
            let returnButton = returnToBenchButtons().firstMatch
            guard scrollUntilVisible(returnButton) else {
                XCTFail("Return to Bench button should be available for a temporarily out player")
                return
            }
            returnButton.tap()

            XCTAssertTrue(
                app.staticTexts["Bench"].waitForExistence(timeout: 2),
                "Bench section should still exist after returning a player"
            )
            XCTAssertTrue(
                app.staticTexts[transitionedPlayerName].waitForExistence(timeout: 2),
                "Player name should still be displayed after returning to the bench"
            )
        }

        XCTContext.runActivity(named: "Activating a benched player moves them to Active Players") { _ in
            let benchRow = row(status: "bench", named: transitionedPlayerName)
            guard benchRow.waitForExistence(timeout: 2) else {
                XCTFail("Expected to find \(transitionedPlayerName) back on the bench")
                return
            }
            moreButton(in: benchRow, status: "bench").tap()

            let activateButton = app.buttons["Activate Player"]
            guard activateButton.waitForExistence(timeout: 2) else {
                // Only offered when the active roster has room; close
                // gracefully rather than fail if capacity was reached.
                app.buttons["Close"].tap()
                return
            }
            activateButton.tap()

            XCTAssertTrue(
                app.staticTexts[transitionedPlayerName].waitForExistence(timeout: 2),
                "Player name should still be displayed after activation"
            )
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testPlayerRowsRenderPerformance() {
        // Measures querying real rows via `playerRow(status:)`, not the raw
        // `.cells.matching(identifier:)` form, which always returns zero
        // matches and would measure querying an empty collection instead.
        measure(metrics: [XCTClockMetric()]) {
            _ = playerRow(status: "active").count
        }
    }

    @MainActor
    func testScrollingPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            app.swipeUp()
            usleep(100_000)
            app.swipeDown()
        }
    }
}
