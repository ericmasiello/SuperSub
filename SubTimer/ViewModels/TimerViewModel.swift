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
  var onTimerTick: (() -> Void)?

  private var timer: Timer?
  private var players: [Player]

  init(players: [Player]) {
    self.players = players
  }

  func startTimer() {
    guard !isRunning else { return }

    isRunning = true
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.onTimerTick?()
    }
  }

  func pauseTimer() {
    isRunning = false
    timer?.invalidate()
    timer = nil
  }

  deinit {
    timer?.invalidate()
  }
}
