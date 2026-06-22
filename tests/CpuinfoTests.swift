//
//  CpuinfoTests.swift
//  cpuinfoTests
//

import XCTest
// Cpuinfo.swift is compiled directly into this (logic) test bundle, so no
// @testable import of the app target is needed.

final class CpuinfoTests: XCTestCase {

  func testIdleSystemIsZeroUsage() {
    // No user/system/nice work, only idle ticks -> 0% usage.
    XCTAssertEqual(Cpuinfo.usageRatio(user: 0, system: 0, idle: 100, nice: 0), 0.0, accuracy: 1e-9)
  }

  func testFullyBusyIsFullUsage() {
    // No idle ticks -> 100% usage.
    XCTAssertEqual(Cpuinfo.usageRatio(user: 50, system: 30, idle: 0, nice: 20), 1.0, accuracy: 1e-9)
  }

  func testHalfBusy() {
    // user+system+nice == idle -> 50% usage.
    XCTAssertEqual(Cpuinfo.usageRatio(user: 30, system: 10, idle: 50, nice: 10), 0.5, accuracy: 1e-9)
  }

  func testNiceCountsAsBusy() {
    // nice time is part of the "used" numerator.
    XCTAssertEqual(Cpuinfo.usageRatio(user: 0, system: 0, idle: 0, nice: 10), 1.0, accuracy: 1e-9)
  }

  func testNoTicksDoesNotDivideByZero() {
    // Guard against division by zero when there is no elapsed time.
    XCTAssertEqual(Cpuinfo.usageRatio(user: 0, system: 0, idle: 0, nice: 0), 0.0, accuracy: 1e-9)
  }

  func testRatioIsWithinUnitRange() {
    let ratio = Cpuinfo.usageRatio(user: 12, system: 7, idle: 81, nice: 0)
    XCTAssertGreaterThanOrEqual(ratio, 0.0)
    XCTAssertLessThanOrEqual(ratio, 1.0)
  }
}
