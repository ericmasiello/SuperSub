//
//  SettingsViewUITests.swift
//  SubTimerUITests
//
//  Created by SubTimer on 2/13/26.
//
//  UI TESTS FOR SETTINGSVIEW AND SETTINGS COMPONENTS
//
//  Tests cover:
//  • Player management (add, edit, delete)
//  • Configuration settings (active players count, preferred time)
//  • Session history display and management
//  • Form validation and error states
//  • Navigation and sheet presentations
//  • Accessibility and user interactions
//
//  CONSOLIDATION NOTE (see GitHub issue #46):
//  Every `XCTestCase` method spawns a fresh app process in `setUpWithError`, so
//  fewer test methods directly means fewer relaunches and a faster suite.
//  Trivial single-assertion smoke tests that exercised the same initial screen
//  state have been folded into `testInitialSettingsScreenState()`, with each
//  condition wrapped in its own `XCTContext.runActivity` so a failure still
//  points at exactly which check broke. `testPlayerManagementFlow()`,
//  `testConfigurationFlow()`, and `testSessionHistoryFlow()` group the rest of
//  the file's coverage by the app state they exercise. The two integration
//  tests (`testCompletePlayerManagementFlow`, `testSettingsToTimerIntegration`)
//  are kept as their own methods per the ticket.
//
//  All `sleep`/`usleep` synchronization has been replaced with
//  `waitForExistence(timeout:)` or predicate-based waits on the actual
//  condition being awaited (see `waitForNonExistence` below).
//

import XCTest

// The consolidation described above (issue #46) trades method count for
// length in both this file and its remaining flow methods; splitting them
// back up would undo that consolidation, so the length ceiling is disabled
// for the rest of this file rather than elsewhere in the codebase.
// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
final class SettingsViewUITests: XCTestCase {
    /// Matches `SettingsPlayerRowView`'s `.accessibilityIdentifier`. Kept as
    /// one constant so the row query and the swipe-target query below can't
    /// drift apart.
    private static let playerRowIdentifier = "settings.player.row"

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Synchronization Helpers

    /// Waits for `element` to stop existing (e.g. a sheet dismissing), instead
    /// of sleeping for a fixed duration.
    @discardableResult
    private func waitForNonExistence(of element: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits for `element`'s label to differ from `initialLabel`.
    @discardableResult
    private func waitForLabelChange(
        of element: XCUIElement, from initialLabel: String, timeout: TimeInterval = 3
    ) -> Bool {
        let predicate = NSPredicate(format: "label != %@", initialLabel)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits for `element`'s accessibility value to differ from
    /// `initialValue`. Stepper's accessibility value updates on tap, but its
    /// label (the fixed "Active Players" title) does not, so this is used
    /// instead of `waitForLabelChange` for stepper changes. Polls directly
    /// rather than through `XCTNSPredicateExpectation`, since `value` is
    /// `Any?` and doesn't bridge reliably through NSPredicate/KVC.
    @discardableResult
    private func waitForValueChange(
        of element: XCUIElement, from initialValue: String?, timeout: TimeInterval = 3
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline, (element.value as? String) == initialValue {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return (element.value as? String) != initialValue
    }

    /// Waits for the player roster's edit-button count to drop below
    /// `count`, instead of sleeping after a delete action.
    private func waitForRowCountBelow(_ count: Int, timeout: TimeInterval = 3) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if playerRowEditButtons().count < count { return true }
        }
        return playerRowEditButtons().count < count
    }

    /// Every `SettingsPlayerRowView` carries `settings.player.row` as its
    /// accessibility identifier; SwiftUI applies it to the row's children
    /// (the name/status text and the edit button) rather than to a single
    /// merged cell, so scoping the query to `app.buttons` reliably yields one
    /// match per player row - each row's edit button, labeled "Edit <name>".
    private func playerRowEditButtons() -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier == '\(Self.playerRowIdentifier)'"))
    }

    /// Row swipe-to-delete needs a large enough touch target to register as
    /// a drag rather than a tap; the edit button is a ~14pt icon, too small
    /// for a reliable `swipeLeft()`. This targets one of the row's text
    /// elements instead (also carrying `settings.player.row`), which is wide
    /// enough for the gesture to register; either the name or status text
    /// works equally well since both sit within the same row's bounds.
    private func lastPlayerRowSwipeTarget() -> XCUIElement {
        let texts = app.staticTexts.matching(NSPredicate(format: "identifier == '\(Self.playerRowIdentifier)'"))
        return texts.element(boundBy: texts.count - 1)
    }

    private func addPlayerButton() -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
        ).firstMatch
    }

    private func preferredTimeButton() -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Preferred Play Time'")).firstMatch
    }

    // MARK: - Initial Settings Screen State

    /// Consolidates every read-only smoke check against the Settings screen's
    /// initial render: navigation title, section headers, player rows,
    /// configuration controls, session history link, accessibility, and
    /// navigation away/back to Timer. Each condition is its own activity so a
    /// failure identifies precisely which one broke.
    @MainActor
    func testInitialSettingsScreenState() {
        XCTContext.runActivity(named: "Settings view loads with its sections") { _ in
            XCTAssertTrue(
                app.navigationBars["Settings"].waitForExistence(timeout: 2), "Settings view should load"
            )
            XCTAssertTrue(app.staticTexts["Players"].exists, "Players section should exist")
            XCTAssertTrue(app.staticTexts["Configuration"].exists, "Configuration section should exist")
        }

        XCTContext.runActivity(named: "Player rows render with a usable, accessible edit action") { _ in
            let editButtons = playerRowEditButtons()
            XCTAssertGreaterThan(editButtons.count, 0, "At least one player row should render")
            let firstEditButton = editButtons.element(boundBy: 0)
            XCTAssertFalse(firstEditButton.label.isEmpty, "Edit button should have an accessibility label")
        }

        XCTContext.runActivity(named: "Add Player button exists and is accessible") { _ in
            let addButton = addPlayerButton()
            XCTAssertTrue(addButton.waitForExistence(timeout: 2), "Add player button should exist")
            XCTAssertFalse(addButton.label.isEmpty, "Add player button should have accessibility label")
        }

        XCTContext.runActivity(named: "Active Players stepper exists with an accessibility value") { _ in
            let stepper = app.steppers.firstMatch
            XCTAssertTrue(stepper.waitForExistence(timeout: 2), "Active players stepper should exist")
            XCTAssertNotNil(stepper.value, "Stepper should have accessibility value")
        }

        XCTContext.runActivity(named: "Preferred Play Time control exists with an accessibility value") { _ in
            let control = preferredTimeButton()
            XCTAssertTrue(control.waitForExistence(timeout: 2), "Preferred time control should exist")
            XCTAssertFalse(control.label.isEmpty, "Preferred time control should have an accessibility label")
        }

        XCTContext.runActivity(named: "Session History link exists and is accessible") { _ in
            let sessionHistoryLink = app.buttons["Session History"]
            XCTAssertTrue(sessionHistoryLink.exists, "Session History link should exist")
        }

        XCTContext.runActivity(named: "Navigating to Timer and back to Settings") { _ in
            let timerTab = app.tabBars.buttons["Timer"]
            XCTAssertTrue(timerTab.exists, "Timer tab should exist")
            timerTab.tap()

            let activeSection = app.staticTexts["Active Players"]
            XCTAssertTrue(activeSection.waitForExistence(timeout: 2), "Should navigate to Timer view")

            let settingsTab = app.tabBars.buttons["Settings"]
            settingsTab.tap()
            XCTAssertTrue(
                app.navigationBars["Settings"].waitForExistence(timeout: 2), "Should return to Settings view"
            )
        }
    }

    // MARK: - Player Management Flow

    /// Combines add (with empty-name validation), edit, duplicate-name
    /// handling, and delete into a single pass over the seeded roster.
    /// Drag-to-reorder is not covered: the original tests only smoke-tested
    /// for an `Edit` toolbar button, but `SettingsView` never adds one -
    /// there is no accessible control that enters list edit mode, so there
    /// was never any real coverage to preserve here.
    @MainActor
    // swiftlint:disable:next function_body_length
    func testPlayerManagementFlow() {
        let initialRowCount = playerRowEditButtons().count

        XCTContext.runActivity(named: "Add button is disabled until a name is entered") { _ in
            addPlayerButton().tap()
            XCTAssertTrue(
                app.navigationBars["Add Player"].waitForExistence(timeout: 2), "Add player sheet should appear"
            )

            let addConfirmButton = app.buttons["Add"]
            XCTAssertFalse(addConfirmButton.isEnabled, "Add should be disabled with an empty name")

            let nameField = app.textFields.firstMatch
            XCTAssertTrue(nameField.exists, "Name field should exist")
            nameField.tap()
            nameField.typeText("Integration Test Player")
            XCTAssertTrue(addConfirmButton.isEnabled, "Add should be enabled once a name is entered")

            addConfirmButton.tap()
            XCTAssertTrue(
                waitForNonExistence(of: app.navigationBars["Add Player"]), "Sheet should dismiss after adding"
            )
            XCTAssertEqual(
                playerRowEditButtons().count, initialRowCount + 1, "Roster should gain exactly one player"
            )
        }

        XCTContext.runActivity(named: "Adding a player with a duplicate name is accepted") { _ in
            // The app has no duplicate-name validation (`addPlayer()` only
            // rejects empty/whitespace names), so this documents actual
            // behavior rather than an assumed rejection.
            let countBeforeDuplicate = playerRowEditButtons().count
            addPlayerButton().tap()
            let nameField = app.textFields.firstMatch
            nameField.tap()
            nameField.typeText("Integration Test Player")

            let addConfirmButton = app.buttons["Add"]
            addConfirmButton.tap()
            XCTAssertTrue(waitForNonExistence(of: app.navigationBars["Add Player"]), "Sheet should dismiss")
            XCTAssertEqual(
                playerRowEditButtons().count, countBeforeDuplicate + 1,
                "Duplicate name should still be added"
            )
        }

        XCTContext.runActivity(named: "Editing a player's name updates the roster") { _ in
            let editButtons = playerRowEditButtons()
            let lastEditButton = editButtons.element(boundBy: editButtons.count - 1)
            lastEditButton.tap()

            XCTAssertTrue(
                app.navigationBars["Edit Player"].waitForExistence(timeout: 2), "Edit player sheet should appear"
            )

            let nameField = app.textFields.firstMatch
            nameField.tap()
            nameField.typeText(" Edited")

            let saveButton = app.buttons["Save"]
            XCTAssertTrue(saveButton.isEnabled, "Save should be enabled for a non-empty name")
            saveButton.tap()

            XCTAssertTrue(
                waitForNonExistence(of: app.navigationBars["Edit Player"]), "Sheet should dismiss after saving"
            )
            XCTAssertTrue(
                app.staticTexts["Integration Test Player Edited"].waitForExistence(timeout: 2),
                "Edited name should appear in the roster"
            )
        }

        XCTContext.runActivity(named: "Deleting a player removes it from the roster") { _ in
            let countBeforeDelete = playerRowEditButtons().count
            lastPlayerRowSwipeTarget().swipeLeft()

            let deleteButton = app.buttons["Delete"]
            XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete action should appear on swipe")
            deleteButton.tap()

            XCTAssertTrue(
                waitForRowCountBelow(countBeforeDelete), "Roster should shrink by one after delete"
            )
        }
    }

    // MARK: - Configuration Flow

    /// Combines the stepper (including the persistence-across-tabs check
    /// that was this file's one catalogued failure) and the preferred time
    /// picker into a single pass, plus boundary behavior at both ends of the
    /// stepper's range.
    @MainActor
    // swiftlint:disable:next function_body_length
    func testConfigurationFlow() {
        let stepper = app.steppers.firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 2), "Stepper should exist")
        // This test doesn't add/remove players, so the roster size observed
        // now is the stepper's maximum for its whole duration.
        let maxPlayers = playerRowEditButtons().count

        XCTContext.runActivity(named: "Changing Active Players persists across a tab switch") { _ in
            let incrementButton = stepper.buttons["Increment"]
            let decrementButton = stepper.buttons["Decrement"]
            let initialValue = stepper.value as? String

            // SwiftUI's Stepper doesn't disable Increment/Decrement at its
            // range bounds - both report `isEnabled == true` even when
            // tapping them is a no-op - so `isEnabled` can't tell us which
            // direction actually moves the value. The seeded fixture starts
            // at the stepper's maximum, so try Increment first and fall back
            // to Decrement if the value didn't actually move.
            incrementButton.tap()
            if !waitForValueChange(of: stepper, from: initialValue, timeout: 1) {
                decrementButton.tap()
            }
            XCTAssertTrue(
                waitForValueChange(of: stepper, from: initialValue), "Stepper value should change after tap"
            )

            let timerTab = app.tabBars.buttons["Timer"]
            timerTab.tap()
            XCTAssertTrue(
                app.staticTexts["Active Players"].waitForExistence(timeout: 2), "Should navigate to Timer view"
            )

            let settingsTab = app.tabBars.buttons["Settings"]
            settingsTab.tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2), "Should return to Settings")

            XCTAssertNotEqual(
                initialValue, app.steppers.firstMatch.value as? String,
                "Configuration changes should persist across tab switches"
            )
        }

        XCTContext.runActivity(named: "Decrementing repeatedly settles at the minimum of 1") { _ in
            let decrementButton = stepper.buttons["Decrement"]
            for _ in 0 ..< (maxPlayers + 2) {
                decrementButton.tap()
            }
            XCTAssertEqual(stepper.value as? String, "1", "Stepper should settle at its minimum of 1")
        }

        XCTContext.runActivity(named: "Incrementing repeatedly settles at the roster-size maximum") { _ in
            let incrementButton = stepper.buttons["Increment"]
            for _ in 0 ..< (maxPlayers + 2) {
                incrementButton.tap()
            }
            XCTAssertEqual(
                stepper.value as? String, "\(maxPlayers)", "Stepper should settle at its maximum of \(maxPlayers)"
            )
        }

        XCTContext.runActivity(named: "Preferred Play Time can be changed via its option menu") { _ in
            let control = preferredTimeButton()
            let initialLabel = control.label
            control.tap()

            let option = app.buttons["1:00"]
            XCTAssertTrue(option.waitForExistence(timeout: 2), "Time option menu should appear")
            option.tap()

            XCTAssertTrue(
                waitForLabelChange(of: preferredTimeButton(), from: initialLabel),
                "Preferred time control should reflect the new selection"
            )
            XCTAssertEqual(
                preferredTimeButton().label, "Preferred Play Time, 1:00",
                "Preferred time should update to the selected option"
            )
        }
    }

    // MARK: - Session History Flow

    /// Covers navigating into session history (seeded fixture data has no
    /// sessions, so this is the empty state) and the two real destructive
    /// actions in `SettingsView` - "Clear Current Session" and "Reset All
    /// Player Times" - each cancelled via their confirmation alert. The
    /// original file's `testClearAllSessions` looked for a "clear all"/
    /// "delete all" button that never existed in the app; these are the
    /// actual actions available.
    @MainActor
    func testSessionHistoryFlow() {
        XCTContext.runActivity(named: "Session History shows the empty state and returns to Settings") { _ in
            app.buttons["Session History"].tap()
            XCTAssertTrue(
                app.navigationBars["Session History"].waitForExistence(timeout: 2),
                "Should navigate to Session History"
            )
            XCTAssertTrue(app.staticTexts["No Sessions"].exists, "Empty state should render with no sessions")

            app.navigationBars["Session History"].buttons["Settings"].tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2), "Should return to Settings")
        }

        XCTContext.runActivity(named: "Clear Current Session can be cancelled") { _ in
            app.buttons["Clear Current Session"].tap()
            let alert = app.alerts["Clear Current Session"]
            XCTAssertTrue(alert.waitForExistence(timeout: 2), "Confirmation alert should appear")
            alert.buttons["Cancel"].tap()
            XCTAssertTrue(waitForNonExistence(of: alert), "Alert should dismiss on cancel")
        }

        XCTContext.runActivity(named: "Reset All Player Times can be cancelled") { _ in
            app.buttons["Reset All Player Times"].tap()
            let alert = app.alerts["Reset All Player Times"]
            XCTAssertTrue(alert.waitForExistence(timeout: 2), "Confirmation alert should appear")
            alert.buttons["Cancel"].tap()
            XCTAssertTrue(waitForNonExistence(of: alert), "Alert should dismiss on cancel")
        }
    }

    // MARK: - Integration Tests

    @MainActor
    func testCompletePlayerManagementFlow() {
        let initialRowCount = playerRowEditButtons().count

        addPlayerButton().tap()
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should appear")
        nameField.tap()
        nameField.typeText("Integration Test Player")

        let addConfirmButton = app.buttons["Add"]
        XCTAssertTrue(addConfirmButton.isEnabled, "Add should be enabled once a name is entered")
        addConfirmButton.tap()
        XCTAssertTrue(waitForNonExistence(of: app.navigationBars["Add Player"]), "Sheet should dismiss")

        let editButtons = playerRowEditButtons()
        XCTAssertEqual(editButtons.count, initialRowCount + 1, "Should gain exactly one player")

        editButtons.element(boundBy: editButtons.count - 1).tap()
        XCTAssertTrue(
            app.navigationBars["Edit Player"].waitForExistence(timeout: 2), "Edit player sheet should appear"
        )
        let editNameField = app.textFields.firstMatch
        editNameField.tap()
        editNameField.typeText(" Modified")

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled for a non-empty name")
        saveButton.tap()
        XCTAssertTrue(waitForNonExistence(of: app.navigationBars["Edit Player"]), "Sheet should dismiss")

        // Decrement is safe here regardless of the roster's current size:
        // the fixture always seeds well above the minimum of 1.
        app.steppers.firstMatch.buttons["Decrement"].tap()

        XCTAssertTrue(
            app.navigationBars["Settings"].exists, "Should remain on Settings view after complete flow"
        )
        XCTAssertTrue(
            app.staticTexts["Integration Test Player Modified"].waitForExistence(timeout: 2),
            "Edited player name should be visible in the roster"
        )
    }

    @MainActor
    func testSettingsToTimerIntegration() {
        // Decrement is safe here regardless of the roster's current size:
        // the fixture always seeds well above the minimum of 1.
        app.steppers.firstMatch.buttons["Decrement"].tap()

        let timerTab = app.tabBars.buttons["Timer"]
        timerTab.tap()
        XCTAssertTrue(
            app.staticTexts["Active Players"].waitForExistence(timeout: 2),
            "Timer should be accessible after settings change"
        )

        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2), "Should return to Settings view")
    }
}
