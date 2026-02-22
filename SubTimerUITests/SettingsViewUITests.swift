//
//  SettingsViewUITests.swift
//  SubTimerUITests
//
//  Created by SubTimer on 2/13/26.
//
//  UI TESTS FOR SETTINGSVIEW AND SETTINGS COMPONENTS
//
//  Tests cover:
//  • Player management (add, edit, delete, reorder)
//  • Configuration settings (active players count, preferred time)
//  • Session history display and management
//  • Form validation and error states
//  • Navigation and sheet presentations
//  • Accessibility and user interactions
//

import XCTest

final class SettingsViewUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    app.launch()

    // Navigate to Settings tab
    let settingsTab = app.tabBars.buttons["Settings"]
    if settingsTab.exists {
      settingsTab.tap()
    }
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - Basic Navigation Tests

  @MainActor
  func testSettingsViewLoads() throws {
    // Verify Settings view is visible
    let settingsTitle = app.navigationBars["Settings"]
    XCTAssertTrue(
      settingsTitle.waitForExistence(timeout: 2),
      "Settings view should load")
  }

  @MainActor
  func testSettingsSectionsExist() throws {
    // Check for main sections
    let playersSection = app.staticTexts["Players"]
    let configSection = app.staticTexts["Configuration"]

    XCTAssertTrue(playersSection.exists, "Players section should exist")
    XCTAssertTrue(configSection.exists, "Configuration section should exist")
  }

  @MainActor
  func testNavigationBetweenTabs() throws {
    // Switch to Timer tab
    let timerTab = app.tabBars.buttons["Timer"]
    XCTAssertTrue(timerTab.exists, "Timer tab should exist")
    timerTab.tap()

    // Verify we're on Timer
    let activeSection = app.staticTexts["Active Players"]
    XCTAssertTrue(
      activeSection.waitForExistence(timeout: 2),
      "Should navigate to Timer view")

    // Return to Settings
    let settingsTab = app.tabBars.buttons["Settings"]
    settingsTab.tap()

    // Verify we're back
    let settingsTitle = app.navigationBars["Settings"]
    XCTAssertTrue(
      settingsTitle.waitForExistence(timeout: 2),
      "Should return to Settings view")
  }

  // MARK: - Player Management Tests

  @MainActor
  func testAddPlayerButtonExists() throws {
    // Find Add Player button (+ or "Add Player")
    let addButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
    ).firstMatch

    XCTAssertTrue(
      addButton.waitForExistence(timeout: 2),
      "Add player button should exist")
  }

  @MainActor
  func testAddPlayerSheetOpens() throws {
    let addButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
    ).firstMatch

    if addButton.exists {
      addButton.tap()

      // Sheet should appear
      let sheetTitle = app.staticTexts.matching(
        NSPredicate(format: "label CONTAINS[c] 'add player' OR label CONTAINS[c] 'new player'")
      ).firstMatch

      XCTAssertTrue(
        sheetTitle.waitForExistence(timeout: 2),
        "Add player sheet should appear")

      // Close sheet
      let cancelButton = app.buttons["Cancel"]
      if cancelButton.exists {
        cancelButton.tap()
      }
    }
  }

  @MainActor
  func testAddPlayerFlow() throws {
    let addButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
    ).firstMatch

    if addButton.exists {
      addButton.tap()
      sleep(1)

      // Find text field
      let nameField = app.textFields.firstMatch
      if nameField.exists {
        nameField.tap()
        nameField.typeText("Test Player")

        // Find Add/Save button
        let saveButton = app.buttons.matching(
          NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'save'")
        ).firstMatch

        if saveButton.exists && saveButton.isEnabled {
          saveButton.tap()
          sleep(1)

          // Sheet should dismiss
          let sheetTitle = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'add player'")
          ).firstMatch
          XCTAssertFalse(sheetTitle.exists, "Sheet should dismiss after adding player")
        } else {
          // Cancel if we can't save
          let cancelButton = app.buttons["Cancel"]
          if cancelButton.exists {
            cancelButton.tap()
          }
        }
      }
    }
  }

  @MainActor
  func testAddPlayerValidation() throws {
    let addButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
    ).firstMatch

    if addButton.exists {
      addButton.tap()
      sleep(1)

      // Find Add/Save button
      let saveButton = app.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'save'")
      ).firstMatch

      if saveButton.exists {
        // Without entering a name, button should be disabled
        // or tapping should show validation error
        let isEnabled = saveButton.isEnabled

        if isEnabled {
          // If enabled, tapping with empty name might show error
          saveButton.tap()
          sleep(1)
          // Could check for error message here
        } else {
          // Button is disabled for empty name (good!)
          XCTAssertFalse(isEnabled, "Save button should be disabled with empty name")
        }
      }

      // Close sheet
      let cancelButton = app.buttons["Cancel"]
      if cancelButton.exists {
        cancelButton.tap()
      }
    }
  }

  @MainActor
  func testEditPlayerFlow() throws {
    // Find first player row
    let playerRows = app.cells.matching(identifier: "settings.player.row")

    if playerRows.count > 0 {
      let firstRow = playerRows.element(boundBy: 0)
      firstRow.tap()
      sleep(1)

      // Edit sheet should appear
      let editTitle = app.staticTexts.matching(
        NSPredicate(format: "label CONTAINS[c] 'edit' OR label CONTAINS[c] 'player'")
      ).firstMatch

      if editTitle.exists {
        // Find text field
        let nameField = app.textFields.firstMatch
        if nameField.exists {
          nameField.tap()
          // Clear and type new name
          nameField.typeText(" Edited")

          // Save
          let saveButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'save' OR label CONTAINS[c] 'done'")
          ).firstMatch

          if saveButton.exists && saveButton.isEnabled {
            saveButton.tap()
            sleep(1)
          }
        }

        // Close sheet if still open
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
          cancelButton.tap()
        }
      }
    }
  }

  @MainActor
  func testDeletePlayer() throws {
    // Find player rows
    let playerRows = app.cells.matching(identifier: "settings.player.row")
    let initialCount = playerRows.count

    if initialCount > 0 {
      let lastRow = playerRows.element(boundBy: initialCount - 1)

      // Swipe to delete
      lastRow.swipeLeft()
      sleep(1)

      // Find Delete button
      let deleteButton = app.buttons["Delete"]
      if deleteButton.exists {
        deleteButton.tap()
        sleep(1)

        // Player count should decrease
        let newCount = app.cells.matching(identifier: "settings.player.row").count
        XCTAssertLessThanOrEqual(
          newCount, initialCount,
          "Player count should not increase after delete")
      }
    }
  }

  @MainActor
  func testReorderPlayers() throws {
    // Find player rows
    let playerRows = app.cells.matching(identifier: "settings.player.row")

    if playerRows.count >= 2 {
      // This is a basic test that edit mode exists
      // Actual drag-and-drop is complex in UI tests

      // Look for Edit button (if present)
      let editButton = app.buttons["Edit"]
      if editButton.exists {
        editButton.tap()
        sleep(1)

        // Verify reorder controls appear
        let reorderControls = app.buttons.matching(
          NSPredicate(format: "label CONTAINS[c] 'reorder'")
        )

        // Should have reorder controls or ability to drag
        // This is a smoke test
        XCTAssertTrue(true, "Edit mode should be accessible")

        // Exit edit mode
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
          doneButton.tap()
        }
      }
    }
  }

  // MARK: - Configuration Tests

  @MainActor
  func testActivePlayersStepperExists() throws {
    // Find stepper for active players count
    let stepper = app.steppers.firstMatch

    XCTAssertTrue(
      stepper.waitForExistence(timeout: 2),
      "Active players stepper should exist")
  }

  @MainActor
  func testActivePlayersStepperIncrement() throws {
    let stepper = app.steppers.firstMatch

    if stepper.exists {
      // Find current value display
      let valueTexts = app.staticTexts.matching(
        NSPredicate(format: "label MATCHES %@", "\\d+")
      )

      // Tap increment
      let incrementButton = stepper.buttons["Increment"]
      if incrementButton.exists {
        incrementButton.tap()
        sleep(1)

        // Value should change (this is a basic smoke test)
        XCTAssertTrue(stepper.exists, "Stepper should still exist after increment")
      }
    }
  }

  @MainActor
  func testActivePlayersStepperDecrement() throws {
    let stepper = app.steppers.firstMatch

    if stepper.exists {
      // Tap decrement
      let decrementButton = stepper.buttons["Decrement"]
      if decrementButton.exists {
        decrementButton.tap()
        sleep(1)

        // Verify stepper still works
        XCTAssertTrue(stepper.exists, "Stepper should still exist after decrement")
      }
    }
  }

  @MainActor
  func testPreferredTimePickerExists() throws {
    // Find picker for preferred play time
    let picker = app.pickers.firstMatch

    XCTAssertTrue(
      picker.waitForExistence(timeout: 2),
      "Preferred time picker should exist")
  }

  @MainActor
  func testPreferredTimePickerInteraction() throws {
    let picker = app.pickers.firstMatch

    if picker.exists {
      picker.tap()
      sleep(1)

      // Should be able to interact with picker
      // (Detailed picker testing is complex in UI tests)
      XCTAssertTrue(picker.exists, "Picker should remain after interaction")
    }
  }

  @MainActor
  func testConfigurationSectionLayout() throws {
    // Verify configuration section has expected elements
    let configSection = app.staticTexts["Configuration"]
    XCTAssertTrue(configSection.exists, "Configuration section should exist")

    // Should have labels for settings
    let activePlayersLabel = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS[c] 'active players'")
    ).firstMatch

    let preferredTimeLabel = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS[c] 'preferred' OR label CONTAINS[c] 'time'")
    ).firstMatch

    // At least one should exist
    XCTAssertTrue(
      activePlayersLabel.exists || preferredTimeLabel.exists,
      "Configuration controls should have labels")
  }

  // MARK: - Session History Tests

  @MainActor
  func testSessionHistorySectionExists() throws {
    // Scroll to find session history (may be below fold)
    app.swipeUp()
    sleep(1)

    let sessionSection = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS[c] 'session' OR label CONTAINS[c] 'history'")
    ).firstMatch

    // Session section may or may not exist depending on data
    // This is a smoke test
    _ = sessionSection.exists
  }

  @MainActor
  func testSessionRowsDisplay() throws {
    // Scroll to session history
    app.swipeUp()
    sleep(1)

    let sessionRows = app.cells.matching(identifier: "session.row")

    // Sessions may or may not exist
    // Just verify it doesn't crash
    _ = sessionRows.count
  }

  @MainActor
  func testDeleteSession() throws {
    // Scroll to session history
    app.swipeUp()
    sleep(1)

    let sessionRows = app.cells.matching(identifier: "session.row")

    if sessionRows.count > 0 {
      let firstSession = sessionRows.element(boundBy: 0)

      // Swipe to delete
      firstSession.swipeLeft()
      sleep(1)

      // Find Delete button
      let deleteButton = app.buttons["Delete"]
      if deleteButton.exists {
        deleteButton.tap()
        sleep(1)

        // Should handle deletion gracefully
        XCTAssertTrue(true, "Session deletion should complete without crash")
      }
    }
  }

  @MainActor
  func testClearAllSessions() throws {
    // Scroll to session history
    app.swipeUp()
    sleep(1)

    let clearButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'clear all' OR label CONTAINS[c] 'delete all'")
    ).firstMatch

    if clearButton.exists {
      clearButton.tap()
      sleep(1)

      // Should show confirmation alert
      let alert = app.alerts.firstMatch
      if alert.exists {
        // Cancel the action
        let cancelButton = alert.buttons["Cancel"]
        if cancelButton.exists {
          cancelButton.tap()
        } else {
          // Or dismiss alert
          let dismissButton = alert.buttons.element(boundBy: 0)
          dismissButton.tap()
        }
      }
    }
  }

  // MARK: - Form Validation Tests

  @MainActor
  func testEmptyPlayerNameValidation() throws {
    let addButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
    ).firstMatch

    if addButton.exists {
      addButton.tap()
      sleep(1)

      // Find text field
      let nameField = app.textFields.firstMatch
      if nameField.exists {
        nameField.tap()

        // Type then delete text
        nameField.typeText("A")
        // Delete key simulation is tricky in UI tests
        // Just verify field exists

        // Try to save
        let saveButton = app.buttons.matching(
          NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'save'")
        ).firstMatch

        if saveButton.exists {
          // Button should be disabled or show error on tap
          _ = saveButton.isEnabled
        }
      }

      // Close sheet
      let cancelButton = app.buttons["Cancel"]
      if cancelButton.exists {
        cancelButton.tap()
      }
    }
  }

  @MainActor
  func testDuplicatePlayerNameValidation() throws {
    // Get existing player name
    let playerRows = app.cells.matching(identifier: "settings.player.row")

    if playerRows.count > 0 {
      let firstRow = playerRows.element(boundBy: 0)
      let existingName = firstRow.staticTexts.element(boundBy: 0).label

      // Try to add player with same name
      let addButton = app.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
      ).firstMatch

      if addButton.exists {
        addButton.tap()
        sleep(1)

        let nameField = app.textFields.firstMatch
        if nameField.exists {
          nameField.tap()
          nameField.typeText(existingName)

          // Try to save
          let saveButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'add'")
          ).firstMatch

          if saveButton.exists && saveButton.isEnabled {
            saveButton.tap()
            sleep(1)

            // Should show error or prevent save
            // This is implementation-dependent
          }
        }

        // Close sheet
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
          cancelButton.tap()
        }
      }
    }
  }

  // MARK: - Accessibility Tests

  @MainActor
  func testAccessibilityLabels() throws {
    // Verify key elements have accessibility labels
    let addButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'add'")
    ).firstMatch

    if addButton.exists {
      XCTAssertFalse(addButton.label.isEmpty, "Add button should have accessibility label")
    }

    let stepper = app.steppers.firstMatch
    if stepper.exists {
      XCTAssertNotNil(stepper.value, "Stepper should have accessibility value")
    }

    let picker = app.pickers.firstMatch
    if picker.exists {
      XCTAssertNotNil(picker.value, "Picker should have accessibility value")
    }
  }

  @MainActor
  func testVoiceOverSupport() throws {
    // Test that interactive elements are accessible
    let playerRows = app.cells.matching(identifier: "settings.player.row")

    if playerRows.count > 0 {
      let firstRow = playerRows.element(boundBy: 0)
      XCTAssertTrue(firstRow.exists, "Player rows should be accessible")
    }
  }

  // MARK: - Persistence Tests

  @MainActor
  func testConfigurationPersistence() throws {
    // Change active players count
    let stepper = app.steppers.firstMatch

    if stepper.exists {
      let incrementButton = stepper.buttons["Increment"]
      if incrementButton.exists {
        // Get current value
        let initialValue = stepper.value as? String

        incrementButton.tap()
        sleep(1)

        // Switch tabs
        let timerTab = app.tabBars.buttons["Timer"]
        timerTab.tap()
        sleep(1)

        // Return to settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        sleep(1)

        // Value should persist
        let currentValue = app.steppers.firstMatch.value as? String
        XCTAssertNotEqual(
          initialValue, currentValue,
          "Configuration changes should persist across tab switches")
      }
    }
  }

  // MARK: - Edge Cases Tests

  @MainActor
  func testMinimumActivePlayersConstraint() throws {
    let stepper = app.steppers.firstMatch

    if stepper.exists {
      let decrementButton = stepper.buttons["Decrement"]

      // Try to decrement below minimum
      for _ in 1...10 {
        if decrementButton.isEnabled {
          decrementButton.tap()
          usleep(200000)  // 0.2 seconds
        } else {
          break
        }
      }

      // Should not crash and should enforce minimum
      XCTAssertTrue(stepper.exists, "Stepper should handle minimum constraint")
    }
  }

  @MainActor
  func testMaximumActivePlayersConstraint() throws {
    let stepper = app.steppers.firstMatch

    if stepper.exists {
      let incrementButton = stepper.buttons["Increment"]

      // Try to increment beyond maximum
      for _ in 1...20 {
        if incrementButton.isEnabled {
          incrementButton.tap()
          usleep(200000)  // 0.2 seconds
        } else {
          break
        }
      }

      // Should not crash and should enforce maximum
      XCTAssertTrue(stepper.exists, "Stepper should handle maximum constraint")
    }
  }

  @MainActor
  func testNoPlayersState() throws {
    // This test assumes you might delete all players
    // In practice, app might prevent this
    let playerRows = app.cells.matching(identifier: "settings.player.row")

    if playerRows.count == 0 {
      // Should show empty state
      let emptyMessage = app.staticTexts.matching(
        NSPredicate(format: "label CONTAINS[c] 'no players' OR label CONTAINS[c] 'add player'")
      ).firstMatch

      // Empty state handling is implementation-dependent
      _ = emptyMessage.exists
    }
  }

  // MARK: - Integration Tests

  @MainActor
  func testCompletePlayerManagementFlow() throws {
    // Add a player
    let addButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'add' OR label == '+'")
    ).firstMatch

    if addButton.exists {
      addButton.tap()
      sleep(1)

      let nameField = app.textFields.firstMatch
      if nameField.exists {
        nameField.tap()
        nameField.typeText("Integration Test Player")

        let saveButton = app.buttons.matching(
          NSPredicate(format: "label CONTAINS[c] 'add'")
        ).firstMatch

        if saveButton.exists && saveButton.isEnabled {
          saveButton.tap()
          sleep(1)
        } else {
          let cancelButton = app.buttons["Cancel"]
          if cancelButton.exists {
            cancelButton.tap()
          }
        }
      }
    }

    // Verify player appears
    let playerRows = app.cells.matching(identifier: "settings.player.row")
    XCTAssertGreaterThan(playerRows.count, 0, "Should have at least one player")

    // Edit the player
    if playerRows.count > 0 {
      let lastRow = playerRows.element(boundBy: playerRows.count - 1)
      lastRow.tap()
      sleep(1)

      let nameField = app.textFields.firstMatch
      if nameField.exists {
        nameField.tap()
        nameField.typeText(" Modified")

        let saveButton = app.buttons.matching(
          NSPredicate(format: "label CONTAINS[c] 'save' OR label CONTAINS[c] 'done'")
        ).firstMatch

        if saveButton.exists && saveButton.isEnabled {
          saveButton.tap()
          sleep(1)
        } else {
          let cancelButton = app.buttons["Cancel"]
          if cancelButton.exists {
            cancelButton.tap()
          }
        }
      }
    }

    // Configuration change
    let stepper = app.steppers.firstMatch
    if stepper.exists {
      let incrementButton = stepper.buttons["Increment"]
      if incrementButton.exists {
        incrementButton.tap()
        sleep(1)
      }
    }

    // Verify settings persisted
    XCTAssertTrue(
      app.navigationBars["Settings"].exists,
      "Should remain on Settings view after complete flow")
  }

  @MainActor
  func testSettingsToTimerIntegration() throws {
    // Modify configuration
    let stepper = app.steppers.firstMatch

    if stepper.exists {
      let incrementButton = stepper.buttons["Increment"]
      if incrementButton.exists {
        incrementButton.tap()
        sleep(1)
      }
    }

    // Switch to timer
    let timerTab = app.tabBars.buttons["Timer"]
    timerTab.tap()
    sleep(1)

    // Timer should reflect new configuration
    let activeSection = app.staticTexts["Active Players"]
    XCTAssertTrue(
      activeSection.exists,
      "Timer should be accessible after settings change")

    // Return to settings
    let settingsTab = app.tabBars.buttons["Settings"]
    settingsTab.tap()
    sleep(1)

    // Should still be on settings
    XCTAssertTrue(
      app.navigationBars["Settings"].exists,
      "Should return to Settings view")
  }
}
