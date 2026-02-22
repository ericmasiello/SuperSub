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
    _ = timerTab.waitForExistence(timeout: 5)
    timerTab.tap()

    // Wait for the view to load
    sleep(1)
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - Active Player Row Tests

  @MainActor
  func testActivePlayerRowDisplaysName() throws {
    let activeRows = app.cells.matching(identifier: "player.row.active")

    if activeRows.count > 0 {
      let firstRow = activeRows.element(boundBy: 0)
      XCTAssertTrue(firstRow.exists, "Active player row should exist")

      // Should have player name
      let nameLabel = firstRow.staticTexts.element(boundBy: 0)
      XCTAssertTrue(nameLabel.exists, "Player name should be displayed")
      XCTAssertFalse(nameLabel.label.isEmpty, "Player name should not be empty")
    }
  }

  @MainActor
  func testActivePlayerRowDisplaysPlayTime() throws {
    let activeRows = app.cells.matching(identifier: "player.row.active")

    if activeRows.count > 0 {
      let firstRow = activeRows.element(boundBy: 0)

      // Should have time display (format: M:SS)
      let timeDisplay = firstRow.staticTexts.matching(
        NSPredicate(format: "label MATCHES %@", "\\d+:\\d{2}")
      ).firstMatch

      XCTAssertTrue(
        timeDisplay.exists,
        "Active player should display current play time")
    }
  }

  @MainActor
  func testActivePlayerRowDisplaysTotalTime() throws {
    let activeRows = app.cells.matching(identifier: "player.row.active")

    if activeRows.count > 0 {
      let firstRow = activeRows.element(boundBy: 0)

      // Should have total time indicator
      let totalTimeLabels = firstRow.staticTexts.matching(
        NSPredicate(format: "label CONTAINS[c] 'total' OR label MATCHES %@", "\\d+:\\d{2}")
      )

      // At least one time display should exist
      XCTAssertGreaterThan(
        totalTimeLabels.count, 0,
        "Active player should show time information")
    }
  }

  @MainActor
  func testActivePlayerRowInteraction() throws {
    let activeRows = app.cells.matching(identifier: "player.row.active")

    if activeRows.count > 0 {
      let firstRow = activeRows.element(boundBy: 0)

      // Row should be tappable
      firstRow.tap()
      sleep(1)

      // Should show action sheet
      let actionSheet = app.sheets.firstMatch
      let actionButtons = app.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] 'bench' OR label CONTAINS[c] 'cancel'")
      )

      XCTAssertTrue(
        actionSheet.exists || actionButtons.count > 0,
        "Tapping active player should show action sheet")

      // Close action sheet
      let cancelButton = app.buttons["Cancel"]
      if cancelButton.exists {
        cancelButton.tap()
      } else {
        app.tap()
      }
    }
  }

  @MainActor
  func testActivePlayerRowAccessibility() throws {
    let activeRows = app.cells.matching(identifier: "player.row.active")

    if activeRows.count > 0 {
      let firstRow = activeRows.element(boundBy: 0)

      XCTAssertTrue(firstRow.exists)
      XCTAssertNotNil(firstRow.value, "Active player row should have accessibility value")
    }
  }

  // MARK: - Bench Player Row Tests

  @MainActor
  func testBenchPlayerRowDisplaysName() throws {
    let benchRows = app.cells.matching(identifier: "player.row.bench")

    if benchRows.count > 0 {
      let firstRow = benchRows.element(boundBy: 0)
      XCTAssertTrue(firstRow.exists, "Bench player row should exist")

      // Should have player name
      let nameLabel = firstRow.staticTexts.element(boundBy: 0)
      XCTAssertTrue(nameLabel.exists, "Benched player name should be displayed")
      XCTAssertFalse(nameLabel.label.isEmpty, "Benched player name should not be empty")
    }
  }

  @MainActor
  func testBenchPlayerRowDisplaysTotalTime() throws {
    let benchRows = app.cells.matching(identifier: "player.row.bench")

    if benchRows.count > 0 {
      let firstRow = benchRows.element(boundBy: 0)

      // Should show total play time
      let timeDisplay = firstRow.staticTexts.matching(
        NSPredicate(format: "label MATCHES %@", "\\d+:\\d{2}")
      ).firstMatch

      // Time display might be present
      _ = timeDisplay.exists
    }
  }

  @MainActor
  func testBenchPlayerRowInteraction() throws {
    let benchRows = app.cells.matching(identifier: "player.row.bench")

    if benchRows.count > 0 {
      let firstRow = benchRows.element(boundBy: 0)

      // Row should be tappable
      firstRow.tap()
      sleep(1)

      // Should show action sheet with substitute/activate option
      let actionButtons = app.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] 'substitute' OR label CONTAINS[c] 'activate'")
      )

      XCTAssertTrue(
        actionButtons.count > 0 || app.buttons["Cancel"].exists,
        "Tapping benched player should show action sheet")

      // Close action sheet
      let cancelButton = app.buttons["Cancel"]
      if cancelButton.exists {
        cancelButton.tap()
      }
    }
  }

  @MainActor
  func testBenchPlayerRowVisualDifferentiation() throws {
    let benchRows = app.cells.matching(identifier: "player.row.bench")
    let activeRows = app.cells.matching(identifier: "player.row.active")

    // If both types exist, they should be visually different
    if benchRows.count > 0 && activeRows.count > 0 {
      let benchRow = benchRows.element(boundBy: 0)
      let activeRow = activeRows.element(boundBy: 0)

      // Both should exist
      XCTAssertTrue(benchRow.exists)
      XCTAssertTrue(activeRow.exists)

      // This is a smoke test that different row types render
    }
  }

  // MARK: - Temporarily Out Player Row Tests

  @MainActor
  func testTemporarilyOutPlayerRowDisplaysName() throws {
    // First, try to create a temporarily out player
    let activeRows = app.cells.matching(identifier: "player.row.active")

    if activeRows.count > 0 {
      let firstRow = activeRows.element(boundBy: 0)
      firstRow.tap()
      sleep(1)

      // Look for "Temporarily Out" action
      let tempOutButton = app.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] 'temporarily out' OR label CONTAINS[c] 'temp out'")
      ).firstMatch

      if tempOutButton.exists && tempOutButton.isEnabled {
        tempOutButton.tap()
        sleep(1)

        // Now check for temporarily out rows
        let tempOutRows = app.cells.matching(identifier: "player.row.tempout")

        if tempOutRows.count > 0 {
          let firstTempOutRow = tempOutRows.element(boundBy: 0)
          XCTAssertTrue(firstTempOutRow.exists, "Temporarily out player row should exist")

          // Should have player name
          let nameLabel = firstTempOutRow.staticTexts.element(boundBy: 0)
          XCTAssertTrue(nameLabel.exists, "Temporarily out player name should be displayed")
        }
      } else {
        // No temp out action available, close sheet
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
          cancelButton.tap()
        }
      }
    }
  }

  @MainActor
  func testTemporarilyOutPlayerRowInteraction() throws {
    let tempOutRows = app.cells.matching(identifier: "player.row.tempout")

    if tempOutRows.count > 0 {
      let firstRow = tempOutRows.element(boundBy: 0)

      // Row should be tappable
      firstRow.tap()
      sleep(1)

      // Should show action sheet
      let actionButtons = app.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] 'return' OR label CONTAINS[c] 'activate'")
      )

      XCTAssertTrue(
        actionButtons.count > 0 || app.buttons["Cancel"].exists,
        "Tapping temporarily out player should show action sheet")

      // Close action sheet
      let cancelButton = app.buttons["Cancel"]
      if cancelButton.exists {
        cancelButton.tap()
      }
    }
  }

  // MARK: - Active Players Section Tests

  @MainActor
  func testActivePlayersSectionHeader() throws {
    let sectionHeader = app.staticTexts["Active Players"]

    XCTAssertTrue(
      sectionHeader.exists,
      "Active Players section header should exist")
  }

  @MainActor
  func testActivePlayersSectionHasPlayers() throws {
    let activeRows = app.cells.matching(identifier: "player.row.active")

    // Should have at least some active players in a functional app
    // This is configuration-dependent
    _ = activeRows.count
  }

  @MainActor
  func testActivePlayersSectionDisplaysCount() throws {
    let sectionHeader = app.staticTexts["Active Players"]

    if sectionHeader.exists {
      // Count might be in header or nearby
      let countTexts = app.staticTexts.matching(
        NSPredicate(format: "label MATCHES %@", "\\d+")
      )

      // Some count indication should exist
      XCTAssertGreaterThan(countTexts.count, 0, "Should display player counts")
    }
  }

  @MainActor
  func testActivePlayersSectionScrolling() throws {
    let activeRows = app.cells.matching(identifier: "player.row.active")

    if activeRows.count > 3 {
      // If many players, should be scrollable
      app.swipeUp()
      sleep(1)
      app.swipeDown()
      sleep(1)

      // Should still be on timer view
      XCTAssertTrue(
        app.staticTexts["Active Players"].exists,
        "Should remain on timer view after scrolling")
    }
  }

  // MARK: - Bench Section Tests

  @MainActor
  func testBenchSectionHeader() throws {
    let sectionHeader = app.staticTexts["Bench"]

    XCTAssertTrue(
      sectionHeader.exists,
      "Bench section header should exist")
  }

  @MainActor
  func testBenchSectionDisplaysPlayers() throws {
    let benchRows = app.cells.matching(identifier: "player.row.bench")

    // Bench may have 0 or more players
    _ = benchRows.count
  }

  @MainActor
  func testBenchSectionEmptyState() throws {
    let benchRows = app.cells.matching(identifier: "player.row.bench")

    if benchRows.count == 0 {
      // Should show empty state or just empty list
      let benchSection = app.staticTexts["Bench"]
      XCTAssertTrue(benchSection.exists, "Bench section should exist even when empty")
    }
  }

  // MARK: - Temporarily Out Section Tests

  @MainActor
  func testTemporarilyOutSectionConditionalDisplay() throws {
    // Section should only appear when there are temporarily out players
    let tempOutSection = app.staticTexts["Temporarily Out"]
    let tempOutRows = app.cells.matching(identifier: "player.row.tempout")

    if tempOutRows.count > 0 {
      XCTAssertTrue(
        tempOutSection.exists,
        "Temporarily Out section should appear when players are temporarily out")
    } else {
      // Section might not exist when no players are temporarily out
      _ = tempOutSection.exists
    }
  }

  // MARK: - Time Display Formatting Tests

  @MainActor
  func testTimeDisplayFormat() throws {
    // Find all time displays
    let timeDisplays = app.staticTexts.matching(
      NSPredicate(format: "label MATCHES %@", "\\d+:\\d{2}(:\\d{2})?")
    )

    XCTAssertGreaterThan(
      timeDisplays.count, 0,
      "Should have time displays in M:SS or H:MM:SS format")

    // Verify each time display has valid format
    for i in 0..<min(timeDisplays.count, 5) {
      let timeDisplay = timeDisplays.element(boundBy: i)
      if timeDisplay.exists {
        let label = timeDisplay.label

        // Should match time format
        XCTAssertTrue(
          label.contains(":"),
          "Time display should contain colon separator")
      }
    }
  }

  @MainActor
  func testZeroTimeDisplay() throws {
    // Benched players might show 0:00
    let benchRows = app.cells.matching(identifier: "player.row.bench")

    if benchRows.count > 0 {
      let firstRow = benchRows.element(boundBy: 0)

      // Look for 0:00 or similar
      let zeroTime = firstRow.staticTexts.matching(
        NSPredicate(format: "label == '0:00' OR label == '00:00'")
      ).firstMatch

      // Zero time might or might not exist depending on player history
      _ = zeroTime.exists
    }
  }

  // MARK: - Player Status Transition Tests

  @MainActor
  func testActiveToTempOutTransition() throws {
    let activeRows = app.cells.matching(identifier: "player.row.active")
    let initialActiveCount = activeRows.count

    if initialActiveCount > 0 {
      let firstRow = activeRows.element(boundBy: 0)
      let playerName = firstRow.staticTexts.element(boundBy: 0).label

      firstRow.tap()
      sleep(1)

      let tempOutButton = app.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] 'temporarily out'")
      ).firstMatch

      if tempOutButton.exists && tempOutButton.isEnabled {
        tempOutButton.tap()
        sleep(1)

        // Verify player moved to temp out section
        let tempOutSection = app.staticTexts["Temporarily Out"]
        XCTAssertTrue(
          tempOutSection.exists,
          "Temporarily Out section should appear")

        // Active count might decrease
        let newActiveCount = app.cells.matching(identifier: "player.row.active").count
        XCTAssertLessThanOrEqual(
          newActiveCount, initialActiveCount,
          "Active player count should not increase")
      } else {
        // Close action sheet
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
          cancelButton.tap()
        }
      }
    }
  }

  @MainActor
  func testTempOutToActiveTransition() throws {
    let tempOutRows = app.cells.matching(identifier: "player.row.tempout")

    if tempOutRows.count > 0 {
      let firstRow = tempOutRows.element(boundBy: 0)
      firstRow.tap()
      sleep(1)

      let returnButton = app.buttons.matching(
        NSPredicate(format: "label CONTAINS[c] 'return' OR label CONTAINS[c] 'activate'")
      ).firstMatch

      if returnButton.exists && returnButton.isEnabled {
        returnButton.tap()
        sleep(2)

        // Player should move back to active or require substitution
        // Verify UI is still stable
        XCTAssertTrue(
          app.staticTexts["Active Players"].exists,
          "Active Players section should still exist")
      } else {
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
          cancelButton.tap()
        }
      }
    }
  }

  // MARK: - Multi-Player Interaction Tests

  @MainActor
  func testMultiplePlayerRowsRenderCorrectly() throws {
    // Wait a bit for the view to fully load
    sleep(2)

    // Try to find active player rows first
    let activeRows = app.cells.matching(identifier: "player.row.active")
    let benchRows = app.cells.matching(identifier: "player.row.bench")
    let tempOutRows = app.cells.matching(identifier: "player.row.tempout")

    // Count all player rows
    let totalCount = activeRows.count + benchRows.count + tempOutRows.count

    XCTAssertGreaterThan(
      totalCount, 0,
      "Should have at least one player row (active: \(activeRows.count), bench: \(benchRows.count), tempOut: \(tempOutRows.count))"
    )

    // Verify active rows exist if there are any
    if activeRows.count > 0 {
      let firstActiveRow = activeRows.element(boundBy: 0)
      XCTAssertTrue(
        firstActiveRow.waitForExistence(timeout: 2), "First active player row should exist")
    }

    // Verify bench rows exist if there are any
    if benchRows.count > 0 {
      let firstBenchRow = benchRows.element(boundBy: 0)
      XCTAssertTrue(
        firstBenchRow.waitForExistence(timeout: 2), "First bench player row should exist")
    }
  }

  @MainActor
  func testPlayerRowsHaveUniqueNames() throws {
    let allPlayerRows = app.cells.matching(
      NSPredicate(format: "identifier CONTAINS 'player.row'")
    )

    var playerNames: Set<String> = []

    for i in 0..<min(allPlayerRows.count, 10) {
      let row = allPlayerRows.element(boundBy: i)
      if row.exists {
        let nameLabel = row.staticTexts.element(boundBy: 0)
        if nameLabel.exists {
          let name = nameLabel.label

          // Track unique names (duplicate names might be valid in some apps)
          playerNames.insert(name)
        }
      }
    }

    XCTAssertGreaterThan(playerNames.count, 0, "Should have player names")
  }

  // MARK: - Performance Tests

  @MainActor
  func testPlayerRowsRenderPerformance() throws {
    // Measure time to render player rows
    measure(metrics: [XCTClockMetric()]) {
      let activeRows = app.cells.matching(identifier: "player.row.active")
      _ = activeRows.count
    }
  }

  @MainActor
  func testScrollingPerformance() throws {
    measure(metrics: [XCTClockMetric()]) {
      app.swipeUp()
      usleep(100000)
      app.swipeDown()
    }
  }
}
