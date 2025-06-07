//
//  PGNParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

@Suite(.serialized)
struct PGNParserTests {

  @Test func gameFromPGN() throws {
    let game = try PGNParser.parse(game: Game.fischerSpassky)
    let gameFromPGN = try Game(pgn: Game.fischerSpassky)

    #expect(game == gameFromPGN)
  }

  @Test func tagParsing() throws {
    let game = try PGNParser.parse(game: Game.fischerSpassky)

    // tags
    #expect(game.tags.event == "F/S Return Match")
    #expect(game.tags.site == "Belgrade, Serbia JUG")
    #expect(game.tags.date == "1992.11.04")
    #expect(game.tags.round == "29")
    #expect(game.tags.white == "Fischer, Robert J.")
    #expect(game.tags.black == "Spassky, Boris V.")
    #expect(game.tags.result == "1/2-1/2")
  }

  @Test func customTagParsing() throws {
    // invalid pair
    #expect(throws: PGNParser.Error.invalidTagFormat) {
      try PGNParser.parse(game: "[a]\n\n1. e4 e5")
    }

    // custom tag
    let g2 = try PGNParser.parse(game: "[CustomTag \"Value\"]\n\n1. e4 e5")
    #expect(g2.tags.other["CustomTag"] == "Value")

    // duplicate tags
    let g3 = try PGNParser.parse(game: "[CustomTag \"Value\"] [CustomTag \"Value2\"]\n\n1. e4 e5")
    #expect(g3.tags.other["CustomTag"] == "Value")
  }

  @Test func moveTextParsing() throws {
    let game = try PGNParser.parse(game: Game.fischerSpassky)

    // starting position + 85 ply
    #expect(game.positions.keys.count == 86)

    #expect(game.moves[.init(number: 1, color: .white)]?.assessment == .blunder)
    #expect(game.moves[.init(number: 1, color: .black)]?.assessment == .brilliant)
    #expect(game.moves[.init(number: 3, color: .black)]?.comment == "This opening is called the Ruy Lopez.")
    #expect(game.moves[.init(number: 4, color: .white)]?.comment == "test comment")
    #expect(game.moves[.init(number: 10, color: .white)]?.end == .d4)
    #expect(game.moves[.init(number: 18, color: .black)]?.piece.kind == .queen)
    #expect(game.moves[.init(number: 18, color: .black)]?.end == .e7)
    #expect(game.moves[.init(number: 36, color: .white)]?.checkState == .check)
  }

  @Test func moveVariationParsing() throws {
    let game = try PGNParser.parse(game: "1. e4 e5 (1... c6)")

    // starting position + 3 ply
    #expect(game.positions.keys.count == 4)

    #expect(game.moves[.init(number: 1, color: .white)]?.san == "e4")
    #expect(game.moves[.init(number: 1, color: .black)]?.san == "e5")
    #expect(game.moves[.init(number: 1, color: .black, variation: 1)]?.san == "c6")
  }

  @Test func moveVariationError() throws {
    #expect(throws: PGNParser.Error.unpairedVariationDelimiter) {
      try PGNParser.parse(game: "1. e4 e5 )1... c6)")
    }
  }

}

// MARK: - Deprecated Tests
extension PGNParserTests {

  @available(*, deprecated)
  @Test func legacyParsing() throws {
    #expect(
      try PGNParser.parse(
        game: Game.fischerSpassky
      )
        == PGNParser.parse(
          game: Game.fischerSpassky,
          startingWith: .standard
        )
    )
  }

}
