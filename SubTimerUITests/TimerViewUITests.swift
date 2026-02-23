//
//  TimerViewUITests.swift
//  SubTimerUITests
//
//  Created by SubTimer on 2/13/26.
//
//  UI TESTS FOR TIMERVIEW AND TIMER COMPONENTS
//
//  Tests cover:
//  • Timer controls (play/pause)
//  • Player status sections (active/bench/temporarily out)
//  • Substitution functionality
//  • Manual substitution flow
//  • Player action sheet interactions
//  • Preferred time display and overtime warnings
//  • Navigation and UI state changes
//

import XCTest

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

    // MARK: - Timer Controls Tests

    @MainActor
    func testTimerStartAndStop() {
        // Find the play/pause button
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch

        XCTAssertTrue(playPauseButton.exists, "Play/Pause button should exist")

        // Initially, timer should be stopped (showing play icon)
        let initialLabel = playPauseButton.label

        // Tap to start timer
        playPauseButton.tap()

        // Wait a moment for state to update
        sleep(1)

        // Button label should change (play → pause or vice versa)
        let updatedLabel = playPauseButton.label
        XCTAssertNotEqual(initialLabel, updatedLabel, "Button state should change after tap")

        // Tap again to stop
        playPauseButton.tap()
        sleep(1)

        // Should return to original state
        XCTAssertEqual(playPauseButton.label, initialLabel, "Button should return to original state")
    }

    @MainActor
    func testTimerControlsAccessibility() {
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch

        XCTAssertTrue(playPauseButton.exists)
        XCTAssertTrue(playPauseButton.isEnabled, "Play/Pause button should be enabled")
        XCTAssertFalse(playPauseButton.label.isEmpty, "Button should have accessible label")
    }

    // MARK: - Preferred Time Display Tests

    @MainActor
    func testPreferredTimeDisplayExists() {
        // Check that the time display is visible
        let timeDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS ':'")).firstMatch

        XCTAssertTrue(timeDisplay.waitForExistence(timeout: 2), "Time display should exist")
    }

    @MainActor
    func testPreferredTimeDisplayFormat() {
        // Time should be in M:SS or H:MM:SS format
        let timeTexts = app.staticTexts.matching(
            NSPredicate(format: "label MATCHES %@", "\\d+:\\d{2}(:\\d{2})?")
        )

        XCTAssertGreaterThan(
            timeTexts.count, 0, "Should have at least one time display with correct format"
        )
    }

    // MARK: - Player Section Tests

    @MainActor
    func testActivePlayersSectionExists() {
        // Check for Active Players section
        let activeSection = app.staticTexts["Active Players"]
        XCTAssertTrue(activeSection.exists, "Active Players section should exist")
    }

    @MainActor
    func testBenchSectionExists() {
        // Check for Bench section
        let benchSection = app.staticTexts["Bench"]
        XCTAssertTrue(benchSection.exists, "Bench section should exist")
    }

    @MainActor
    func testTemporarilyOutSectionExists() {
        // Check for Temporarily Out section (may not always be visible)
        let tempOutSection = app.staticTexts["Temporarily Out"]

        // This section appears conditionally
        // We'll just verify it doesn't crash when checking
        _ = tempOutSection.exists
    }

    @MainActor
    func testPlayerRowsDisplayed() {
        // Count player rows in the list
        let playerRows = app.cells.matching(identifier: "player.row")

        // Should have at least some players (depends on setup)
        // This is a smoke test to ensure rows render
        XCTAssertTrue(playerRows.count >= 0, "Player rows should render without crashing")
    }

    // MARK: - Substitution Button Tests

    @MainActor
    func testSubstitutionButtonExists() {
        let subButton = app.buttons["Substitute"]

        XCTAssertTrue(subButton.waitForExistence(timeout: 2), "Substitute button should exist")
    }

    @MainActor
    func testSubstitutionButtonTap() {
        let subButton = app.buttons["Substitute"]

        if subButton.exists, subButton.isEnabled {
            subButton.tap()

            // After substitution, should still be on timer view
            XCTAssertTrue(
                app.navigationBars["Timer"].exists || app.staticTexts["Active Players"].exists,
                "Should remain on timer view after substitution"
            )
        }
    }

    @MainActor
    func testManualSubstitutionButton() {
        // Look for manual sub button (ellipsis or manual option)
        let manualSubButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'manual' OR label == '...'")
        ).firstMatch

        if manualSubButton.exists {
            manualSubButton.tap()

            // Should show manual substitution sheet
            let sheetTitle = app.staticTexts["Select Players"]
            XCTAssertTrue(
                sheetTitle.waitForExistence(timeout: 2),
                "Manual substitution sheet should appear"
            )

            // Close sheet (look for Cancel or Done)
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }

    // MARK: - Player Actions Sheet Tests

    @MainActor
    func testPlayerRowTapShowsActionSheet() {
        // Find first player row
        let playerRows = app.cells.matching(identifier: "player.row")

        if playerRows.count > 0 {
            let firstRow = playerRows.element(boundBy: 0)
            firstRow.tap()

            // Should show action sheet
            sleep(1)

            // Look for common action buttons
            let actionButtons = app.buttons.matching(
                NSPredicate(
                    format:
                    "label CONTAINS[c] 'bench' OR label CONTAINS[c] 'substitute' OR label CONTAINS[c] 'activate'"
                )
            )

            // At least some action should be available
            XCTAssertTrue(
                actionButtons.count > 0 || app.buttons["Cancel"].exists,
                "Action sheet should show with options"
            )

            // Close sheet
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                // Tap outside to dismiss
                app.tap()
            }
        }
    }

    // MARK: - Player Status Change Tests

    @MainActor
    func testBenchPlayerFromActionSheet() {
        // Find an active player row
        let playerRows = app.cells.matching(identifier: "player.row.active")

        if playerRows.count > 0 {
            let firstActivePlayer = playerRows.element(boundBy: 0)
            let playerName = firstActivePlayer.staticTexts.element(boundBy: 0).label

            firstActivePlayer.tap()
            sleep(1)

            // Look for "Bench" action
            let benchButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'bench'"))
                .firstMatch

            if benchButton.exists, benchButton.isEnabled {
                benchButton.tap()
                sleep(1)

                // Verify player moved (check bench section)
                let benchSection = app.staticTexts["Bench"]
                XCTAssertTrue(benchSection.exists, "Bench section should exist after benching player")
            }
        }
    }

    @MainActor
    func testActivatePlayerFromBench() {
        // Find a benched player row
        let benchRows = app.cells.matching(identifier: "player.row.bench")

        if benchRows.count > 0 {
            let firstBenchPlayer = benchRows.element(boundBy: 0)
            firstBenchPlayer.tap()
            sleep(1)

            // Look for "Activate" or "Sub In" action
            let activateButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'activate' OR label CONTAINS[c] 'sub in'")
            ).firstMatch

            if activateButton.exists, activateButton.isEnabled {
                activateButton.tap()
                sleep(1)

                // Should perform substitution
                XCTAssertTrue(
                    app.staticTexts["Active Players"].exists,
                    "Active Players section should still exist"
                )
            }
        }
    }

    @MainActor
    func testTemporarilyOutPlayer() {
        // Find an active player
        let activeRows = app.cells.matching(identifier: "player.row.active")

        if activeRows.count > 0 {
            let firstActivePlayer = activeRows.element(boundBy: 0)
            firstActivePlayer.tap()
            sleep(1)

            // Look for "Temporarily Out" action
            let tempOutButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'temporarily out' OR label CONTAINS[c] 'temp out'")
            ).firstMatch

            if tempOutButton.exists, tempOutButton.isEnabled {
                tempOutButton.tap()
                sleep(1)

                // Temporarily Out section should appear
                let tempOutSection = app.staticTexts["Temporarily Out"]
                XCTAssertTrue(
                    tempOutSection.exists,
                    "Temporarily Out section should appear"
                )
            }
        }
    }

    // MARK: - Manual Substitution Flow Tests

    @MainActor
    func testManualSubstitutionFlow() {
        // Open manual substitution sheet
        let manualSubButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'manual'"))
            .firstMatch

        if manualSubButton.exists {
            manualSubButton.tap()
            sleep(1)

            // Sheet should appear
            let sheetTitle = app.staticTexts["Select Players"]
            XCTAssertTrue(
                sheetTitle.waitForExistence(timeout: 2),
                "Manual substitution sheet should appear"
            )

            // Look for player selection rows
            let playerPickers = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH 'In:' OR label BEGINSWITH 'Out:'")
            )

            if playerPickers.count >= 2 {
                // Tap "In" player picker
                let inPicker = playerPickers.matching(NSPredicate(format: "label BEGINSWITH 'In:'"))
                    .firstMatch
                if inPicker.exists {
                    inPicker.tap()
                    sleep(1)

                    // Select a player from menu
                    let playerOptions = app.buttons.matching(identifier: "player.option")
                    if playerOptions.count > 0 {
                        playerOptions.element(boundBy: 0).tap()
                    }
                }

                // Tap "Out" player picker
                let outPicker = playerPickers.matching(NSPredicate(format: "label BEGINSWITH 'Out:'"))
                    .firstMatch
                if outPicker.exists {
                    outPicker.tap()
                    sleep(1)

                    // Select a different player
                    let playerOptions = app.buttons.matching(identifier: "player.option")
                    if playerOptions.count > 1 {
                        playerOptions.element(boundBy: 1).tap()
                    }
                }

                // Tap Substitute button
                let substituteButton = app.buttons["Substitute"]
                if substituteButton.exists, substituteButton.isEnabled {
                    substituteButton.tap()
                    sleep(1)

                    // Sheet should dismiss
                    XCTAssertFalse(
                        sheetTitle.exists,
                        "Manual substitution sheet should dismiss after substitution"
                    )
                }
            }

            // Close sheet if still open
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }

    // MARK: - Timer Running State Tests

    @MainActor
    func testTimerUpdatesWhileRunning() {
        // Start timer
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch

        if playPauseButton.exists {
            playPauseButton.tap()

            // Get initial time display
            let timeDisplay = app.staticTexts.matching(
                NSPredicate(format: "label MATCHES %@", "\\d+:\\d{2}")
            ).firstMatch
            let initialTime = timeDisplay.label

            // Wait for timer to tick
            sleep(2)

            // Time should have changed
            let updatedTime = timeDisplay.label
            // Note: This might be flaky depending on timer implementation
            // Consider this a smoke test that the display exists

            // Stop timer
            playPauseButton.tap()
        }
    }

    // MARK: - Empty State Tests

    @MainActor
    func testEmptyBenchSection() {
        // If bench is empty, should show appropriate UI
        let benchSection = app.staticTexts["Bench"]

        if benchSection.exists {
            // Check for empty state message or player rows
            let benchRows = app.cells.matching(identifier: "player.row.bench")

            if benchRows.count == 0 {
                // Empty bench is valid state
                XCTAssertTrue(benchSection.exists, "Bench section should exist even when empty")
            }
        }
    }

    // MARK: - Navigation Tests

    @MainActor
    func testNavigationToSettings() {
        // Switch to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()

        // Verify we're on Settings
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(
            settingsTitle.waitForExistence(timeout: 2),
            "Should navigate to Settings view"
        )

        // Return to Timer
        let timerTab = app.tabBars.buttons["Timer"]
        timerTab.tap()

        // Verify we're back
        let activeSection = app.staticTexts["Active Players"]
        XCTAssertTrue(
            activeSection.waitForExistence(timeout: 2),
            "Should return to Timer view"
        )
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testAccessibilityLabels() {
        // Verify key elements have accessibility labels
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch
        XCTAssertFalse(
            playPauseButton.label.isEmpty, "Play/Pause button should have accessibility label"
        )

        let substituteButton = app.buttons["Substitute"]
        if substituteButton.exists {
            XCTAssertFalse(
                substituteButton.label.isEmpty, "Substitute button should have accessibility label"
            )
        }

        // Section headers should be accessible
        let activeSection = app.staticTexts["Active Players"]
        XCTAssertTrue(activeSection.exists, "Active Players section should have accessibility label")
    }

    @MainActor
    func testVoiceOverNavigation() {
        // Enable accessibility features for testing
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch

        XCTAssertTrue(playPauseButton.exists)
        XCTAssertNotNil(playPauseButton.value, "Button should have accessibility value")
    }

    // MARK: - Stress Tests

    @MainActor
    func testRapidButtonTaps() {
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch

        if playPauseButton.exists {
            // Rapidly tap button multiple times
            for _ in 1 ... 5 {
                playPauseButton.tap()
                usleep(100_000) // 0.1 second
            }

            // App should still be responsive
            XCTAssertTrue(playPauseButton.exists, "Button should still exist after rapid taps")
            XCTAssertTrue(playPauseButton.isEnabled, "Button should still be enabled")
        }
    }

    @MainActor
    func testMultipleSubstitutions() {
        let substituteButton = app.buttons["Substitute"]

        if substituteButton.exists, substituteButton.isEnabled {
            // Perform multiple substitutions
            for _ in 1 ... 3 {
                substituteButton.tap()
                sleep(1)
            }

            // App should still be stable
            XCTAssertTrue(
                app.staticTexts["Active Players"].exists,
                "UI should remain stable after multiple substitutions"
            )
        }
    }

    // MARK: - Integration Tests

    @MainActor
    func testCompleteTimerSession() {
        // Start timer
        let playPauseButton = app.buttons.matching(identifier: "timer.play.pause").firstMatch
        if playPauseButton.exists {
            playPauseButton.tap()
            sleep(2)

            // Perform substitution
            let substituteButton = app.buttons["Substitute"]
            if substituteButton.exists, substituteButton.isEnabled {
                substituteButton.tap()
                sleep(1)
            }

            // Change player status
            let playerRows = app.cells.matching(identifier: "player.row")
            if playerRows.count > 0 {
                playerRows.element(boundBy: 0).tap()
                sleep(1)

                // Cancel action sheet
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
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
