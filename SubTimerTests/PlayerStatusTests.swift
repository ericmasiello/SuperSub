//
//  PlayerStatusTests.swift
//  SubTimerTests
//
//  Created by Eric Masiello on 2/13/26.
//

import Foundation
import SwiftData
import Testing

@testable import SubTimer

struct PlayerStatusTests {

  @Test func testPlayerStatusEnum() async throws {
    let activeStatus = PlayerStatus.active
    let benchedStatus = PlayerStatus.benched
    let tempOutStatus = PlayerStatus.temporarilyOut

    #expect(activeStatus.rawValue == "active")
    #expect(benchedStatus.rawValue == "benched")
    #expect(tempOutStatus.rawValue == "temporarilyOut")
  }
}
