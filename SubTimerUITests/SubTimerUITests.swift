//
//  SubTimerUITests.swift
//  SubTimerUITests
//
//  Created by Eric Masiello on 2/13/26.
//
//  BASIC UI TESTS
//
//  This file contains basic launch and performance tests.
//
//  For comprehensive UI tests, see:
//  • TimerViewUITests.swift - Timer screen tests (20+ tests)
//  • SettingsViewUITests.swift - Settings screen tests (25+ tests)
//  • PlayerComponentsUITests.swift - Player component tests (20+ tests)
//
//  Total UI Test Coverage: 65+ tests across all files
//
//  Quick Start:
//  1. Add accessibility identifiers to views (see QUICK_START.md)
//  2. Run tests with Cmd+U or in Test Navigator (Cmd+6)
//  3. See README.md for detailed documentation
//

import XCTest

final class SubTimerUITests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  @MainActor
  func testExample() throws {
    // UI tests must launch the application that they test.
    let app = XCUIApplication()
    app.launch()

    // Use XCTAssert and related functions to verify your tests produce the correct results.
  }

  @MainActor
  func testLaunchPerformance() throws {
    // This measures how long it takes to launch your application.
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }
}
