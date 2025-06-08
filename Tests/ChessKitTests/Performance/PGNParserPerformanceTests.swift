//
//  PGNParserPerformanceTests.swift
//  ChessKit
//

@testable import ChessKit
import XCTest

final class PGNParserPerformanceTests: XCTestCase {

  func testPGNParserPerformance() throws {
    // Clock Monotonic Time: 0.011 s
    // CPU Cycles: 32097.649 kC
    // CPU Instructions Retired: 107155.368 kI
    // CPU Time: 0.010 s
    // Memory Peak Physical: 34026.138 kB
    // Memory Physical: 160.563 kB
    measure(
      metrics: [
        XCTClockMetric(),
        XCTCPUMetric(),
        XCTMemoryMetric()
      ],
      block: parsePGN
    )
  }

  private func parsePGN() {
    let parsedGame = try? PGNParser.parse(game: Game.fischerSpassky)
    XCTAssertNotNil(parsedGame)
  }

}
