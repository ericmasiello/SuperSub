//
//  BenchManagerTests.swift
//  SubTimerTests
//
//  Created by Eric Masiello on 2/22/26.
//

import Foundation
@testable import SubTimer
import SwiftData
import Testing

struct BenchManagerTests {
    @Test func testDefault() {
        let bench = BenchManager()
        #expect(bench.count == 0)
    }
}
