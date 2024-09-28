//
//  PGNParserPerformanceTests.swift
//  ChessKit
//

@testable import ChessKit
import XCTest

final class PGNParserPerformanceTests: XCTestCase {

  func testBoardPerformance() {
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
    let parsedGame = PGNParser.parse(game: Game.fischerSpassky)
    XCTAssertNotNil(parsedGame)
  }

}
