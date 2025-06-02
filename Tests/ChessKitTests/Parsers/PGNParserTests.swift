//
//  PGNParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

final class PGNParserTests: XCTestCase {

  func testGameFromPGN() {
    let game = PGNParser.parse(game: Game.fischerSpassky)
    let gameFromPGN = Game(pgn: Game.fischerSpassky)

    XCTAssertEqual(game, gameFromPGN)
  }

  func testTagParsing() {
    let game = PGNParser.parse(game: Game.fischerSpassky)

    // tags
    XCTAssertEqual(game.tags.event, "F/S Return Match")
    XCTAssertEqual(game.tags.site, "Belgrade, Serbia JUG")
    XCTAssertEqual(game.tags.date, "1992.11.04")
    XCTAssertEqual(game.tags.round, "29")
    XCTAssertEqual(game.tags.white, "Fischer, Robert J.")
    XCTAssertEqual(game.tags.black, "Spassky, Boris V.")
    XCTAssertEqual(game.tags.result, "1/2-1/2")
  }

  func testCustomTagParsing() {
    // invalid pair
    let g1 = PGNParser.parse(game: "[a] 1. e4 e5")
    XCTAssertNil(g1.tags.other["a"])

    // custom tag
    let g2 = PGNParser.parse(game: "[CustomTag \"Value\"] 1. e4 e5")
    XCTAssertEqual(g2.tags.other["CustomTag"], "Value")

    // duplicate tags
    let g3 = PGNParser.parse(game: "[CustomTag \"Value\"] [CustomTag \"Value2\"] 1. e4 e5")
    XCTAssertEqual(g3.tags.other["CustomTag"], "Value")
  }

  func testValidResultParsing() {
    let g1 = PGNParser.parse(game: "1. e4 e5 1/2-1/2")
    XCTAssertEqual(g1.tags.result, "1/2-1/2")

    let g2 = PGNParser.parse(game: "1. e4 e5 1-0")
    XCTAssertEqual(g2.tags.result, "1-0")

    let g3 = PGNParser.parse(game: "1. e4 e5 0-1")
    XCTAssertEqual(g3.tags.result, "0-1")

    let g4 = PGNParser.parse(game: "1. e4 e5 *")
    XCTAssertEqual(g4.tags.result, "*")
  }

  func testInvalidResultParsing() {
    let g1 = PGNParser.parse(game: "1. e4 e5 ***")
    XCTAssertEqual(g1.tags.result, "")

    let g2 = PGNParser.parse(game: "1. e4 e5 test")
    XCTAssertEqual(g2.tags.result, "")

    let g3 = PGNParser.parse(game: "1. e4 e5 1-00-1")
    XCTAssertEqual(g3.tags.result, "")
  }

  func testMoveTextParsing() {
    let game = PGNParser.parse(game: Game.fischerSpassky)

    // starting position + 85 ply
    XCTAssertEqual(game.positions.keys.count, 86)

    XCTAssertEqual(
      game.moves[
        .init(
          number: 1,
          color: .white
        )]?.assessment, .blunder)
    XCTAssertEqual(
      game.moves[
        .init(
          number: 1,
          color: .black
        )]?.assessment, .brilliant)
    XCTAssertEqual(
      game.moves[
        .init(
          number: 3,
          color: .black
        )]?.comment, "This opening is called the Ruy Lopez.")
    XCTAssertEqual(
      game.moves[
        .init(
          number: 4,
          color: .white
        )]?.comment, "test comment")
    XCTAssertEqual(
      game.moves[
        .init(
          number: 10,
          color: .white
        )]?.end, .d4)
    XCTAssertEqual(
      game.moves[
        .init(
          number: 18,
          color: .black
        )]?.piece.kind, .queen)
    XCTAssertEqual(
      game.moves[
        .init(
          number: 18,
          color: .black
        )]?.end, .e7)
    XCTAssertEqual(
      game.moves[
        .init(
          number: 36,
          color: .white
        )]?.checkState, .check)
  }

}
