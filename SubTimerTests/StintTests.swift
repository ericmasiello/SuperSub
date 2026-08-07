//
//  StintTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct StintTests {
    @Test func stintInitialization() {
        let stint = Stint()

        #expect(stint.endDate == nil)
        #expect(stint.position == nil)
        #expect(stint.player == nil)
        #expect(stint.game == nil)
    }

    @Test func stintWithPlayerAndGame() {
        let player = Player(name: "Alex")
        let game = Game()
        let stint = Stint(position: "Midfielder", player: player, game: game)

        #expect(stint.position == "Midfielder")
        #expect(stint.player === player)
        #expect(stint.game === game)
    }
}
