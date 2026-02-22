//
//  TimeFormattingTests.swift
//  SubTimerTests
//
//  Created by Eric Masiello on 2/13/26.
//

import Foundation
import SwiftData
import Testing

@testable import SubTimer

struct TimeFormattingTests {

  @Test func testTimeIntervalFormatting() async throws {
    func formatTime(_ timeInterval: TimeInterval) -> String {
      let hours = Int(timeInterval) / 3600
      let minutes = (Int(timeInterval) % 3600) / 60
      let seconds = Int(timeInterval) % 60

      if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
      } else {
        return String(format: "%d:%02d", minutes, seconds)
      }
    }

    #expect(formatTime(0) == "0:00")
    #expect(formatTime(30) == "0:30")
    #expect(formatTime(60) == "1:00")
    #expect(formatTime(90) == "1:30")
    #expect(formatTime(180) == "3:00")
    #expect(formatTime(3665) == "1:01:05")
  }
}
