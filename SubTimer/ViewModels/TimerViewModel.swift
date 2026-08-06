//
//  TimerViewModel.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import Foundation
import SwiftData

@Observable
class TimerViewModel {
    var isRunning = false
    private(set) var elapsedTime: TimeInterval = 0
    var onTimerTick: (() -> Void)?

    private(set) var timerStartDate: Date?
    private(set) var accumulatedTime: TimeInterval = 0

    private var displayTimer: Timer?
    private var players: [Player]

    init(players: [Player]) {
        self.players = players
    }

    private func computeElapsedTime() -> TimeInterval {
        guard let start = timerStartDate else { return accumulatedTime }
        return accumulatedTime + Date().timeIntervalSince(start)
    }

    func startTimer() {
        guard !isRunning else { return }

        isRunning = true
        timerStartDate = Date()
        elapsedTime = computeElapsedTime()

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedTime = self.computeElapsedTime()
            self.onTimerTick?()
        }
        displayTimer = timer
        // ensures timer keeps counting even when scrolling
        RunLoop.current.add(timer, forMode: .common)
    }

    func pauseTimer() {
        if let start = timerStartDate {
            accumulatedTime += Date().timeIntervalSince(start)
        }
        isRunning = false
        timerStartDate = nil
        elapsedTime = accumulatedTime
        displayTimer?.invalidate()
        displayTimer = nil
    }

    func resetTimer() {
        isRunning = false
        accumulatedTime = 0
        timerStartDate = nil
        elapsedTime = 0
        displayTimer?.invalidate()
        displayTimer = nil
    }

    deinit {
        displayTimer?.invalidate()
    }
}
