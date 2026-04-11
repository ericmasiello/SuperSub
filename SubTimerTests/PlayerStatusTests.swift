//
//  PlayerStatusTests.swift
//  SubTimerTests
//
//  Created by Eric Masiello on 2/13/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct PlayerStatusTests {
    @Test func playerStatusEnum() {
        let activeStatus = PlayerStatus.active
        let benchedStatus = PlayerStatus.benched
        let tempOutStatus = PlayerStatus.temporarilyOut

        #expect(activeStatus.rawValue == "active")
        #expect(benchedStatus.rawValue == "benched")
        #expect(tempOutStatus.rawValue == "temporarilyOut")
    }
}
