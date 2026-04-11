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
        #expect(viewModel.onTimerTick == nil)
    }

    @Test func testStartTimer() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()

        #expect(viewModel.isRunning == true)
    }

    @Test func startTimerWhenAlreadyRunning() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        // Starting again should not change state
        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)
    }

    @Test func testPauseTimer() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
    }

    @Test func pauseTimerWhenNotRunning() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        #expect(viewModel.isRunning == false)

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
    }

    @Test func testResetTimer() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        await viewModel.resetTimer()
        #expect(viewModel.isRunning == false)
    }

    @Test func resetTimerWhenNotRunning() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        #expect(viewModel.isRunning == false)

        await viewModel.resetTimer()
        #expect(viewModel.isRunning == false)
    }

    @Test func startAfterReset() async {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        // Start, reset, then start again
        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        await viewModel.resetTimer()
        #expect(viewModel.isRunning == false)

        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)
    }

    @Test func timerTickCallback() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        var tickCount = 0
        viewModel.onTimerTick = {
            tickCount += 1
        }

        await viewModel.startTimer()

        // Wait for at least 2 seconds to ensure timer ticks
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

        // Wait for some ticks
        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()
        let ticksAfterPause = tickCount

        // Wait a bit more
        try await Task.sleep(for: .seconds(1.5))

        // Tick count should not have increased after pause
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

        // Wait for some ticks
        try await Task.sleep(for: .seconds(1.5))

        await viewModel.resetTimer()
        let ticksAfterReset = tickCount

        // Wait a bit more
        try await Task.sleep(for: .seconds(1.5))

        // Tick count should not have increased after reset
        #expect(tickCount == ticksAfterReset)
    }

    @Test func multiplePauseResumeCycles() async throws {
        let players = [Player(name: "Player 1")]
        let viewModel = await TimerViewModel(players: players)

        var tickCount = 0
        viewModel.onTimerTick = {
            tickCount += 1
        }

        // First cycle
        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)
        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
        let firstPauseTicks = tickCount

        // Second cycle
        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)
        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)

        // Should have more ticks after second cycle
        #expect(tickCount > firstPauseTicks)
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

        // Wait to ensure no ticks happen
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

        // Should not crash when starting timer without callback
        await viewModel.startTimer()
        #expect(viewModel.isRunning == true)

        try await Task.sleep(for: .seconds(1.5))

        await viewModel.pauseTimer()
        #expect(viewModel.isRunning == false)
    }
}
