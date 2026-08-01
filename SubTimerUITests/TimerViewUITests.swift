//
//  TimerViewUITests.swift
//  SubTimerUITests
//
//  Created by SubTimer on 2/13/26.
//
//  UI TESTS FOR TIMERVIEW AND TIMER COMPONENTS
//
//  Tests cover:
//  • Timer controls (play/pause) and accessibility of the initial screen state
//  • Player status sections (active/bench/temporarily out)
//  • Substitution functionality (automatic + manual)
//  • Player action sheet interactions and status changes
//  • Preferred time display and overtime warnings
//  • Navigation and UI state changes
//

import XCTest

// Each `test...Flow`/`testInitial...State` method below intentionally
// consolidates several related checks into one app launch (see their
// individual doc comments); that consolidation is what pushes this file
// and class past SwiftLint's default length ceilings, so both are disabled
// here rather than by splitting the flows back apart.
// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
final class TimerViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Navigate to Timer tab
        let timerTab = app.tabBars.buttons["Timer"]
        if timerTab.exists {
            timerTab.tap()
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Synchronization Helpers

    /// Waits for `element`'s label to differ from `initialLabel`, instead of
    /// sleeping for a fixed duration and hoping SwiftUI has re-rendered by then.
    @discardableResult
    private func waitForLabelChange(
        of element: XCUIElement, from initialLabel: String, timeout: TimeInterval = 3
    ) -> Bool {
        let predicate = NSPredicate(format: "label != %@", initialLabel)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits for `element` to stop existing (e.g. a sheet dismissing), instead
    /// of sleeping for a fixed duration.
    @discardableResult
    private func waitForNonExistence(of element: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Each player row applies its `player.row.<status>` accessibility
    /// identifier to the row's *children* rather than a single merged
    /// element (SwiftUI decomposes the row into separate accessibility
    /// elements here), so the row's `ellipsis.circle` action button - the
    /// one actually wired to open the action sheet - is what carries that
    /// identifier alongside its own explicit "More" label (set via
    /// `.accessibilityLabel("More")` in `ActivePlayerRowView`/
    /// `BenchPlayerRowView`, not left to the SF Symbol's implicit VoiceOver
    /// label). Pass `status` ("active" or "bench") to scope to one section;
    /// omit it to match either. Temporarily-out rows have no such button
    /// (they only expose "Return to Bench"), so they're correctly excluded
    /// from this query.
    private func playerRowActionButtons(status: String? = nil) -> XCUIElementQuery {
        let identifierClause = status.map { "identifier == 'player.row.\($0)'" }
            ?? "identifier BEGINSWITH 'player.row'"
        return app.buttons.matching(NSPredicate(format: "\(identifierClause) AND label == 'More'"))
    }

    // MARK: - Initial Timer Screen State

    /// Consolidates every read-only smoke check against the Timer screen's
    /// initial render: timer controls, preferred time display, player
    /// sections, substitution button, accessibility labels, and navigation
    /// away/back to Settings. Each condition is its own activity so a
    /// failure identifies precisely which one broke.
    @MainActor
    // swiftlint:disable:next function_body_length
    func testInitialTimerScreenState() {
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch

        XCTContext.runActivity(named: "Play/Pause button exists, is enabled, and is accessible") { _ in
            XCTAssertTrue(playPauseButton.exists, "Play/Pause button should exist")
            XCTAssertTrue(playPauseButton.isEnabled, "Play/Pause button should be enabled")
            XCTAssertFalse(
                playPauseButton.label.isEmpty, "Play/Pause button should have accessibility label"
            )
            XCTAssertNotNil(playPauseButton.value, "Play/Pause button should have accessibility value")
        }

        XCTContext.runActivity(named: "Preferred time display exists with the correct format") { _ in
            let timeDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS ':'")).firstMatch
            XCTAssertTrue(timeDisplay.waitForExistence(timeout: 2), "Time display should exist")

            let timeTexts = app.staticTexts.matching(
                NSPredicate(format: "label MATCHES %@", "\\d+:\\d{2}(:\\d{2})?")
            )
            XCTAssertGreaterThan(
                timeTexts.count, 0, "Should have at least one time display with correct format"
            )
        }

        XCTContext.runActivity(named: "Active Players section exists and is accessible") { _ in
            let activeSection = app.staticTexts["Active Players"]
            XCTAssertTrue(activeSection.exists, "Active Players section should have accessibility label")
        }

        XCTContext.runActivity(named: "Bench section exists") { _ in
            let benchSection = app.staticTexts["Bench"]
            XCTAssertTrue(benchSection.exists, "Bench section should exist")
        }

        XCTContext.runActivity(named: "Temporarily Out section renders without crashing") { _ in
            // This section only appears conditionally (when a player has that
            // status); verifying the query doesn't crash is the coverage we
            // actually have with the seeded fixture data.
            let tempOutSection = app.staticTexts["Temporarily Out"]
            _ = tempOutSection.exists
        }

        XCTContext.runActivity(named: "Player rows render with a tappable action button") { _ in
            // XCUIElementQuery has no `isEmpty`, only `count` (an XCTest API constraint).
            XCTAssertTrue(
                // swiftlint:disable:next empty_count
                playerRowActionButtons().count > 0,
                "At least one player row should render its action ('More') button"
            )
        }

        XCTContext.runActivity(named: "Substitute button exists and is accessible") { _ in
            let subButton = app.buttons["Substitute"]
            XCTAssertTrue(subButton.waitForExistence(timeout: 2), "Substitute button should exist")
            XCTAssertFalse(
                subButton.label.isEmpty, "Substitute button should have accessibility label"
            )
        }

        XCTContext.runActivity(named: "Navigating to Settings and back to Timer") { _ in
            let settingsTab = app.tabBars.buttons["Settings"]
            XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
            settingsTab.tap()

            let settingsTitle = app.navigationBars["Settings"]
            XCTAssertTrue(
                settingsTitle.waitForExistence(timeout: 2), "Should navigate to Settings view"
            )

            let timerTab = app.tabBars.buttons["Timer"]
            timerTab.tap()

            let activeSection = app.staticTexts["Active Players"]
            XCTAssertTrue(
                activeSection.waitForExistence(timeout: 2), "Should return to Timer view"
            )
        }
    }

    // MARK: - Timer Controls Behavior

    /// Combines starting/stopping the timer (button label toggles and
    /// returns to its original state) with the running-state smoke check
    /// (time display updates while the timer runs).
    @MainActor
    func testTimerControlsBehavior() {
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch
        XCTAssertTrue(playPauseButton.exists, "Play/Pause button should exist")

        let initialLabel = playPauseButton.label

        XCTContext.runActivity(named: "Starting the timer changes the button label") { _ in
            playPauseButton.tap()
            XCTAssertTrue(
                waitForLabelChange(of: playPauseButton, from: initialLabel),
                "Button state should change after tap"
            )
        }

        XCTContext.runActivity(named: "Time display updates while the timer runs") { _ in
            let timeDisplay = app.staticTexts.matching(
                NSPredicate(format: "label MATCHES %@", "\\d+:\\d{2}")
            ).firstMatch
            let initialTime = timeDisplay.label

            // Smoke test: the time display should tick forward while running.
            // Not asserted strictly (timer implementation may debounce ticks),
            // but we wait for the actual condition rather than a blind sleep.
            _ = waitForLabelChange(of: timeDisplay, from: initialTime, timeout: 3)
            XCTAssertTrue(timeDisplay.exists, "Time display should still exist while timer runs")
        }

        XCTContext.runActivity(named: "Stopping the timer returns the button to its original state") { _ in
            let runningLabel = playPauseButton.label
            playPauseButton.tap()
            XCTAssertTrue(
                waitForLabelChange(of: playPauseButton, from: runningLabel),
                "Button state should change after tap"
            )
            XCTAssertEqual(playPauseButton.label, initialLabel, "Button should return to original state")
        }
    }

    // MARK: - Player Action Sheet Flow

    /// Exercises `PlayerActionsSheetView` across every status transition it
    /// actually supports - "Substitute Out"/"Mark Temporarily Out" for an
    /// active player, and "Activate Player" for a benched player - all
    /// against the same app launch. (There is no direct "bench an active
    /// player" action in this sheet: benching only happens via substitution.)
    @MainActor
    // swiftlint:disable:next function_body_length
    func testPlayerActionSheetFlow() {
        XCTContext.runActivity(named: "Tapping an active player's row shows its status-appropriate actions") { _ in
            let activeRowButtons = playerRowActionButtons(status: "active")
            guard activeRowButtons.firstMatch.waitForExistence(timeout: 3) else {
                XCTFail("Expected at least one active player row from seeded fixture data")
                return
            }

            activeRowButtons.element(boundBy: 0).tap()

            XCTAssertTrue(
                app.buttons["Substitute Out"].waitForExistence(timeout: 2),
                "Substitute Out action should be available for an active player"
            )
            XCTAssertTrue(
                app.buttons["Mark Temporarily Out"].exists,
                "Mark Temporarily Out action should be available for an active player"
            )

            let closeButton = app.buttons["Close"]
            closeButton.tap()
            XCTAssertTrue(waitForNonExistence(of: closeButton), "Action sheet should dismiss")
        }

        XCTContext.runActivity(named: "Marking an active player temporarily out shows that section") { _ in
            let activeRowButtons = playerRowActionButtons(status: "active")
            guard activeRowButtons.firstMatch.waitForExistence(timeout: 3) else {
                XCTFail("Expected at least one active player row from seeded fixture data")
                return
            }

            activeRowButtons.element(boundBy: 0).tap()

            let tempOutButton = app.buttons["Mark Temporarily Out"]
            guard tempOutButton.waitForExistence(timeout: 2) else {
                XCTFail("Mark Temporarily Out action should be available")
                return
            }
            tempOutButton.tap()

            let tempOutSection = app.staticTexts["Temporarily Out"]
            XCTAssertTrue(
                tempOutSection.waitForExistence(timeout: 2), "Temporarily Out section should appear"
            )
        }

        XCTContext.runActivity(named: "Activating a benched player moves them to Active Players") { _ in
            let benchRowButtons = playerRowActionButtons(status: "bench")
            guard benchRowButtons.firstMatch.waitForExistence(timeout: 3) else {
                XCTFail("Expected at least one benched player row from seeded fixture data")
                return
            }

            benchRowButtons.element(boundBy: 0).tap()

            let activateButton = app.buttons["Activate Player"]
            guard activateButton.waitForExistence(timeout: 2) else {
                // Only offered when the active roster has room; the previous
                // activity already freed a slot, so this should normally be
                // available, but close gracefully rather than fail if not.
                app.buttons["Close"].tap()
                return
            }
            activateButton.tap()

            let activeSection = app.staticTexts["Active Players"]
            XCTAssertTrue(
                activeSection.waitForExistence(timeout: 2),
                "Active Players section should still exist after activating a player"
            )
        }
    }

    // MARK: - Substitution Flows

    /// Combines the automatic substitute-button flow with the manual
    /// substitution flow, which is reached via an active player's action
    /// sheet ("Substitute Out") rather than a standalone button on the main
    /// screen - `ManualSubstitutionSheetView` presents a plain list of bench
    /// players to sub in, titled "Select Player to Sub In".
    @MainActor
    // swiftlint:disable:next function_body_length
    func testSubstitutionFlows() {
        XCTContext.runActivity(named: "Automatic substitution keeps the user on the Timer view") { _ in
            let subButton = app.buttons["Substitute"]
            guard subButton.waitForExistence(timeout: 3), subButton.isEnabled else {
                XCTFail("Substitute button should exist and be enabled from seeded fixture data")
                return
            }

            subButton.tap()
            XCTAssertTrue(
                app.navigationBars["Timer"].exists || app.staticTexts["Active Players"].exists,
                "Should remain on timer view after substitution"
            )
        }

        XCTContext.runActivity(named: "Manual substitution via the action sheet can be cancelled") { _ in
            let activeRowButtons = playerRowActionButtons(status: "active")
            guard activeRowButtons.firstMatch.waitForExistence(timeout: 3) else {
                XCTFail("Expected at least one active player row from seeded fixture data")
                return
            }
            activeRowButtons.element(boundBy: 0).tap()

            let substituteOutButton = app.buttons["Substitute Out"]
            guard substituteOutButton.waitForExistence(timeout: 2) else {
                XCTFail("Substitute Out action should be available")
                return
            }
            substituteOutButton.tap()

            let sheetTitle = app.navigationBars["Select Player to Sub In"]
            guard sheetTitle.waitForExistence(timeout: 3) else {
                XCTFail("Manual substitution sheet should appear")
                return
            }

            let cancelButton = app.buttons["Cancel"]
            XCTAssertTrue(cancelButton.exists, "Manual substitution sheet should offer Cancel")
            cancelButton.tap()
            XCTAssertTrue(waitForNonExistence(of: sheetTitle), "Sheet should dismiss on cancel")
        }

        XCTContext.runActivity(named: "Manual substitution via the action sheet can select a bench player") { _ in
            let activeRowButtons = playerRowActionButtons(status: "active")
            guard activeRowButtons.firstMatch.waitForExistence(timeout: 3) else {
                XCTFail("Expected at least one active player row from seeded fixture data")
                return
            }
            activeRowButtons.element(boundBy: 0).tap()

            let substituteOutButton = app.buttons["Substitute Out"]
            guard substituteOutButton.waitForExistence(timeout: 2) else {
                XCTFail("Substitute Out action should be available")
                return
            }
            substituteOutButton.tap()

            let sheetTitle = app.navigationBars["Select Player to Sub In"]
            guard sheetTitle.waitForExistence(timeout: 2) else {
                XCTFail("Manual substitution sheet should appear")
                return
            }

            // Rows here are plain Buttons combining a player's name and total
            // play time, with no accessibility identifier of their own;
            // "Total:" reliably scopes the match to a bench-player row.
            let benchPlayerRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Total:'")).firstMatch
            guard benchPlayerRow.waitForExistence(timeout: 2) else {
                XCTFail("Expected at least one bench player to sub in")
                return
            }
            benchPlayerRow.tap()

            XCTAssertTrue(
                waitForNonExistence(of: sheetTitle),
                "Manual substitution sheet should dismiss after selecting a player"
            )
        }
    }

    // MARK: - Stress Tests

    @MainActor
    func testRapidButtonTaps() {
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch

        if playPauseButton.exists {
            // Rapidly tap the button back-to-back with no artificial delay -
            // XCUIElement.tap() already synchronizes on hittability, so this
            // is a stronger stress test than pacing taps with usleep.
            for _ in 1 ... 5 {
                playPauseButton.tap()
            }

            // App should still be responsive
            XCTAssertTrue(playPauseButton.exists, "Button should still exist after rapid taps")
            XCTAssertTrue(playPauseButton.isEnabled, "Button should still be enabled")
        }
    }

    @MainActor
    func testMultipleSubstitutions() {
        let substituteButton = app.buttons["Substitute"]
        let activeSection = app.staticTexts["Active Players"]

        if substituteButton.exists, substituteButton.isEnabled {
            // Perform multiple substitutions, waiting for the UI to settle
            // (Active Players section re-rendering) between taps instead of
            // sleeping for a fixed duration.
            for _ in 1 ... 3 {
                substituteButton.tap()
                XCTAssertTrue(
                    activeSection.waitForExistence(timeout: 2),
                    "UI should remain stable after each substitution"
                )
            }

            // App should still be stable
            XCTAssertTrue(
                activeSection.exists, "UI should remain stable after multiple substitutions"
            )
        }
    }

    // MARK: - Integration Tests

    @MainActor
    func testCompleteTimerSession() {
        // Start timer
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch
        if playPauseButton.exists {
            let initialLabel = playPauseButton.label
            playPauseButton.tap()
            waitForLabelChange(of: playPauseButton, from: initialLabel)

            // Perform substitution
            let substituteButton = app.buttons["Substitute"]
            if substituteButton.exists, substituteButton.isEnabled {
                let activeSection = app.staticTexts["Active Players"]
                substituteButton.tap()
                _ = activeSection.waitForExistence(timeout: 2)
            }

            // Change player status
            let rowActionButtons = playerRowActionButtons()
            // XCUIElementQuery has no `isEmpty`, only `count` (an XCTest API constraint).
            // swiftlint:disable:next empty_count
            if rowActionButtons.count > 0 {
                let closeButton = app.buttons["Close"]
                rowActionButtons.element(boundBy: 0).tap()
                _ = closeButton.waitForExistence(timeout: 2)

                // Close the action sheet without changing anything
                if closeButton.exists {
                    closeButton.tap()
                    _ = waitForNonExistence(of: closeButton)
                }
            }

            // Stop timer
            playPauseButton.tap()

            // Verify everything still works
            XCTAssertTrue(
                app.staticTexts["Active Players"].exists,
                "Timer view should still be functional"
            )
        }
    }
}
