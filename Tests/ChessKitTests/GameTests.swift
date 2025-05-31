//
//  GameTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

final class GameTests: XCTestCase {

  private var game = Game()

  // MARK: - Indices used in tests

  private let nf3Index = MoveTree.Index(number: 2, color: .white, variation: 0)
  private let nc3Index = MoveTree.Index(number: 2, color: .white, variation: 1)
  private let nf6Index = MoveTree.Index(number: 2, color: .black, variation: 1)
  private let nc6Index = MoveTree.Index(number: 2, color: .black, variation: 2)
  private let nc6Index2 = MoveTree.Index(number: 2, color: .black, variation: 0)
  private let f5Index = MoveTree.Index(number: 2, color: .black, variation: 3)

  // MARK: - Setup

  override func setUp() {
    let minimum = MoveTree.Index.getMinimum()
    game.tags = Self.mockTags

    game.make(moves: ["e4", "e5", "Nf3", "Nc6", "Bc4"], from: minimum)

    // add 2. Nc3 ... variation to 2. Nf3
    game.make(moves: ["Nc3", "Nf6", "Bc4"], from: nf3Index.previous)

    // add 2... Nc6 ... variation to 2... Nf6
    game.make(moves: ["Nc6", "f4"], from: nf6Index.previous)

    // add another variation to 2... Nf6
    game.make(moves: ["f5", "exf5"], from: nc6Index2.previous)

    // make repeat moves to test proper handling
    game.make(move: "e4", from: minimum)
    game.make(move: "e5", from: minimum.next)
    game.make(moves: ["Nc3", "Nf6"], from: nf3Index.previous)
  }

  override func tearDown() {
    // reset game
    game = Game()
  }

  // MARK: - Test cases

  func testStartingPosition() {
    let game1 = Game(startingWith: .standard)
    XCTAssertEqual(
      game1.moves.startIndex,
      .init(number: 0, color: .black, variation: 0)
    )
    XCTAssertEqual(game1.startingPosition, .standard)

    let fen = "r1bqkb1r/pp1ppppp/2n2n2/8/2B1P3/2N2N2/PP3PPP/R1BQK2R b KQkq - 4 6"
    var game2 = Game(startingWith: .init(fen: fen)!)

    XCTAssertEqual(
      game2.moves.startIndex,
      .init(number: 1, color: .white, variation: 0)
    )
    XCTAssertEqual(game2.startingPosition, .init(fen: fen)!)
    game2.make(move: "O-O", from: game2.moves.startIndex)
    XCTAssertEqual(
      game2.moves.index(after: game2.moves.minimumIndex),
      .init(number: 1, color: .black, variation: 0)
    )
    XCTAssertEqual(
      game2.moves[.init(number: 1, color: .black, variation: 0)],
      .init(san: "O-O", position: .init(fen: fen)!)
    )
  }

  func testMakeMoves() {
    XCTAssertFalse(game.moves.isEmpty)
    XCTAssertEqual(game.moves[.init(number: 1, color: .white)]?.san, "e4")
    XCTAssertEqual(game.moves[.init(number: 1, color: .black)]?.san, "e5")
    XCTAssertEqual(game.moves[.init(number: 2, color: .white)]?.san, "Nf3")
    XCTAssertEqual(game.moves[.init(number: 2, color: .black)]?.san, "Nc6")
    XCTAssertEqual(game.moves[.init(number: 3, color: .white)]?.san, "Bc4")
  }

  func testMoveTree() {
    XCTAssertEqual(game.moves[nf3Index]?.san, "Nf3")
    XCTAssertEqual(game.moves[nc3Index]?.san, "Nc3")

    XCTAssertEqual(game.moves[nf6Index]?.san, "Nf6")
    XCTAssertEqual(game.moves[nc6Index]?.san, "Nc6")

    XCTAssertEqual(
      game.moves.index(
        before: nc6Index
      ),
      nc3Index
    )

    XCTAssertEqual(game.moves[nc6Index2]?.san, "Nc6")
    XCTAssertEqual(game.moves[f5Index]?.san, "f5")

    XCTAssertEqual(
      game.moves.index(
        before: f5Index
      ),
      nf3Index
    )
    let minimum = MoveTree.Index.getMinimum()
    XCTAssertEqual(game.moves.index(before: minimum.next), minimum)
    XCTAssertEqual(game.moves.index(after: nc3Index), nf6Index)
  }

  func testMoveAnnotation() {
    game.annotate(moveAt: nc3Index, assessment: .brilliant)
    game.annotate(moveAt: f5Index, comment: "Comment test")

    XCTAssertEqual(
      PGNParser.convert(game: game).split(separator: "\n").last,
      "1. e4 e5 2. Nf3 (2. Nc3 $3 Nf6 (2... Nc6 3. f4) 3. Bc4) Nc6 (2... f5 {Comment test} 3. exf5) 3. Bc4"
    )
  }

  func testMoveHistory() {
    let f5History = game.moves.history(for: f5Index)

    XCTAssertEqual(
      f5History,
      [
        .init(number: 1, color: .white, variation: 0),
        .init(number: 1, color: .black, variation: 0),
        .init(number: 2, color: .white, variation: 0),
        f5Index
      ]
    )
  }

  func testMoveFuture() {
    let f5Future = game.moves.future(for: f5Index)

    XCTAssertEqual(
      f5Future,
      [.init(number: 3, color: .white, variation: 3)]
    )
  }

  func testMoveFullVariation() {
    let f5History = game.moves.history(for: f5Index)
    let f5Future = game.moves.future(for: f5Index)

    let f5Full = game.moves.fullVariation(for: f5Index)
    XCTAssertEqual(f5History + f5Future, f5Full)
  }

  func testMoveTreeEmptyPath() {
    XCTAssertTrue(game.moves.path(from: nc3Index, to: nc3Index).isEmpty)
  }

  func testMoveTreeSimplePath() {
    // "1. e4 e5 2. Nf3 (2. Nc3 Nf6 (2... Nc6 3. f4) 3. Bc4) Nc6 (2... f5 3. exf5) 3. Bc4"
    let f4 = MoveTree.Index(number: 3, color: .white, variation: 2)
    let e5 = MoveTree.Index(number: 1, color: .black, variation: 0)

    // 3. f4 to 1. e5
    let path1 = game.moves.path(from: f4, to: e5)

    XCTAssertEqual(
      path1.map(\.direction),
      [.reverse, .reverse, .reverse]
    )

    XCTAssertEqual(
      path1.map(\.index),
      [
        f4,
        .init(number: 2, color: .black, variation: 2),
        .init(number: 2, color: .white, variation: 1)
      ]
    )

    // 1. e5 to 3. f4
    let path2 = game.moves.path(from: e5, to: f4)

    XCTAssertEqual(
      path2.map(\.direction),
      [.forward, .forward, .forward]
    )

    XCTAssertEqual(
      path2.map(\.index),
      [
        .init(number: 2, color: .white, variation: 1),
        .init(number: 2, color: .black, variation: 2),
        f4
      ]
    )
  }

  func testMoveTreeComplexPath() {
    // "1. e4 e5 2. Nf3 (2. Nc3 Nf6 (2... Nc6 3. f4) 3. Bc4) Nc6 (2... f5 3. exf5) 3. Bc4"
    // 3. f4 to 3. Bc4
    let f4 = MoveTree.Index(number: 3, color: .white, variation: 2)
    let Bc4 = MoveTree.Index(number: 3, color: .white, variation: 0)
    let path = game.moves.path(from: f4, to: Bc4)

    XCTAssertEqual(
      path.map(\.direction),
      [
        .reverse,
        .reverse,
        .reverse,
        .forward,
        .forward,
        .forward,
        .forward
      ]
    )

    XCTAssertEqual(
      path.map(\.index),
      [
        f4,
        .init(number: 2, color: .black, variation: 2),
        .init(number: 2, color: .white, variation: 1),
        .init(number: 1, color: .black, variation: 0),
        .init(number: 2, color: .white, variation: 0),
        .init(number: 2, color: .black, variation: 0),
        Bc4
      ]
    )
  }

  func testPGN() {
    let pgn =
      """
      [Event "Test Event"]
      [Site "Barrow, Alaska USA"]
      [Date "2000.01.01"]
      [Round "5"]
      [White "Player One"]
      [Black "Player Two"]
      [Result "1-0"]
      [Annotator "Annotator"]
      [PlyCount "15"]
      [TimeControl "40/7200:3600"]
      [Time "12:00"]
      [Termination "abandoned"]
      [Mode "OTB"]
      [FEN "\(Position.standard.fen)"]
      [SetUp "1"]
      [TestKey1 "Test Value 1"]
      [TestKey2 "Test Value 2"]

      1. e4 e5 2. Nf3 (2. Nc3 Nf6 (2... Nc6 3. f4) 3. Bc4) Nc6 (2... f5 3. exf5) 3. Bc4
      """

    XCTAssertEqual(game.pgn, pgn)
  }

  func testValidTagPairs() {
    let pgn =
      """
      [Event "Test Event"]
      [Site "Barrow, Alaska USA"]
      [Date "2000.01.01"]
      [Round "5"]
      [White "Player One"]
      [Black "Player Two"]
      [Result "1-0"]

      1. e4 e5 2. Nf3 (2. Nc3 Nf6 (2... Nc6 3. f4) 3. Bc4) Nc6 (2... f5 3. exf5) 3. Bc4
      """

    let game = Game(pgn: pgn)!
    XCTAssertTrue(game.tags.isValid)
  }

  func testInvalidTagPairs() {
    let pgn =
      """
      [Event "Test Event"]

      1. e4 e5 2. Nf3 (2. Nc3 Nf6 (2... Nc6 3. f4) 3. Bc4) Nc6 (2... f5 3. exf5) 3. Bc4
      """

    let game = Game(pgn: pgn)!
    XCTAssertFalse(game.tags.isValid)
    XCTAssertTrue(game.tags.$site.pgn.isEmpty)
  }

  func testInvalidGame() {

  }

}

extension GameTests {

  private static let mockTags = Game.Tags(
    event: "Test Event",
    site: "Barrow, Alaska USA",
    date: "2000.01.01",
    round: "5",
    white: "Player One",
    black: "Player Two",
    result: "1-0",
    annotator: "Annotator",
    plyCount: "15",
    timeControl: "40/7200:3600",
    time: "12:00",
    termination: "abandoned",
    mode: "OTB",
    fen: Position.standard.fen,
    setUp: "1",
    other: [
      "TestKey1": "Test Value 1",
      "TestKey2": "Test Value 2"
    ]
  )

}
