//
//  TimerViewModelTests.swift
//  SubTimerTests
//
//  Created by SubTimer on 2/13/26.
//

import Foundation
@testable import SubTimer
import Testing

struct TimerViewModelTests {
    @Test func initialization() async {
        let players = [Player(name: "Player 1"), Player(name: "Player 2")]
        let viewModel = await TimerViewModel(players: players)

        #expect(viewModel.isRunning == false)
        #expect(viewModel.elapsedTime == 0)
        #expect(viewModel.timerStartDate == nil)
        #expect(viewModel.accumulatedTime == 0)
        #expect(viewModel.onTimerTick == nil)
    }

    @Test func testStartTimer() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()

        #expect(viewModel.isRunning == true)
        #expect(viewModel.timerStartDate != nil)
    }

    @Test func startTimerWhenAlreadyRunning() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        let firstStartDate = viewModel.timerStartDate
        #expect(viewModel.isRunning == true)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)
        #expect(viewModel.timerStartDate == firstStartDate)
    }

    @Test func testPauseTimer() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
        #expect(viewModel.timerStartDate == nil)
    }

    @Test func pauseFoldsTimeIntoAccumulatedTime() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()

        #expect(viewModel.accumulatedTime >= 1.0)
        #expect(viewModel.accumulatedTime < 3.0)
        #expect(viewModel.elapsedTime == viewModel.accumulatedTime)
    }

    @Test func pauseTimerWhenNotRunning() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        #expect(viewModel.isRunning == false)

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
        #expect(viewModel.accumulatedTime == 0)
    }

    @Test func testResetTimer() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        await viewModel.resetTimer()
        #expect(viewModel.isRunning == false)
        #expect(viewModel.elapsedTime == 0)
        #expect(viewModel.accumulatedTime == 0)
        #expect(viewModel.timerStartDate == nil)
    }

    @Test func resetTimerWhenNotRunning() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        #expect(viewModel.isRunning == false)

        await viewModel.resetTimer()
        #expect(viewModel.isRunning == false)
        #expect(viewModel.elapsedTime == 0)
        #expect(viewModel.accumulatedTime == 0)
    }

    @Test func startAfterReset() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        await viewModel.resetTimer()
        #expect(viewModel.isRunning == false)
        #expect(viewModel.elapsedTime == 0)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)
        #expect(viewModel.timerStartDate != nil)
    }

    @Test func timerTickCallback() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        var tickCount = 0
        viewModel.onTimerTick = {
            tickCount += 1
        }

        await viewModel.startTimer()

        try await Task.sleep(for: .seconds(2.5))

        #expect(tickCount >= 2)

        await viewModel.pauseTimer()
    }

    @Test func timerStopsTickingAfterPause() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        var tickCount = 0
        viewModel.onTimerTick = {
            tickCount += 1
        }

        await viewModel.startTimer()

        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()
        let ticksAfterPause = tickCount

        try await Task.sleep(for: .seconds(1.5))

        #expect(tickCount == ticksAfterPause)
    }

    @Test func timerStopsTickingAfterReset() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        var tickCount = 0
        viewModel.onTimerTick = {
            tickCount += 1
        }

        await viewModel.startTimer()

        try await Task.sleep(for: .seconds(1.5))

        await viewModel.resetTimer()
        let ticksAfterReset = tickCount

        try await Task.sleep(for: .seconds(1.5))

        #expect(tickCount == ticksAfterReset)
    }

    @Test func multiplePauseResumeCycles() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)
        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
        let firstPauseAccumulated = viewModel.accumulatedTime
        #expect(firstPauseAccumulated >= 1.0)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)
        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
        #expect(viewModel.accumulatedTime > firstPauseAccumulated)
    }

    @Test func resetClearsTimerCompletely() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        var tickCount = 0
        viewModel.onTimerTick = {
            tickCount += 1
        }

        await viewModel.startTimer()
        try await Task.sleep(for: .seconds(1.5))

        await viewModel.resetTimer()
        #expect(viewModel.isRunning == false)
        #expect(viewModel.elapsedTime == 0)
        #expect(viewModel.accumulatedTime == 0)

        let ticksAtReset = tickCount
        try await Task.sleep(for: .seconds(1.5))

        #expect(tickCount == ticksAtReset)
    }

    @Test func initializationWithMultiplePlayers() async {
        let players = [
            Player(name: "Player 1"),
            Player(name: "Player 2"),
            Player(name: "Player 3"),
        ]
        let viewModel = await TimerViewModel(players: players)

        #expect(viewModel.isRunning == false)
    }

    @Test func timerWithNoCallback() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
    }

    @Test func elapsedTimeComputedFromDates() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        try await Task.sleep(for: .seconds(2.0))

        let elapsed = viewModel.elapsedTime
        #expect(elapsed >= 1.5)
        #expect(elapsed < 4.0)

        await viewModel.pauseTimer()
    }

    @Test func elapsedTimeAccumulatesAcrossPauseResume() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        try await Task.sleep(for: .seconds(1.5))
        await viewModel.pauseTimer()
        let afterFirstPause = viewModel.elapsedTime

        await viewModel.startTimer()
        try await Task.sleep(for: .seconds(1.5))
        await viewModel.pauseTimer()
        let afterSecondPause = viewModel.elapsedTime

        #expect(afterSecondPause > afterFirstPause)
        #expect(afterSecondPause >= 2.0)
    }

    @Test func resetAfterPauseResumeClearsAll() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        try await Task.sleep(for: .seconds(1.0))
        await viewModel.pauseTimer()

        await viewModel.startTimer()
        try await Task.sleep(for: .seconds(1.0))
        await viewModel.pauseTimer()

        #expect(viewModel.accumulatedTime >= 1.5)

        await viewModel.resetTimer()
        #expect(viewModel.elapsedTime == 0)
        #expect(viewModel.accumulatedTime == 0)
        #expect(viewModel.timerStartDate == nil)
    }
}
