//
//  SubTimerUITests.swift
//  SubTimerUITests
//
//  Created by Eric Masiello on 2/13/26.
//
//  Measures app launch performance. See TimerViewUITests.swift,
//  SettingsViewUITests.swift, and PlayerComponentsUITests.swift for the
//  per-screen UI test suites; see SubTimerUITestsLaunchTests.swift for the
//  launch smoke test.
//

import XCTest

final class SubTimerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
