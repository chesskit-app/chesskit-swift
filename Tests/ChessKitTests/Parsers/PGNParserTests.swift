//
//  PGNParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

@Suite(.serialized)
struct PGNParserTests {

  @Test func emptyPGN() throws {
    #expect(try PGNParser.parse(game: "") == .init(startingWith: .standard))
  }

  @Test func gameFromPGN() throws {
    let game = try PGNParser.parse(game: Game.fischerSpassky)
    let gameFromPGN = try Game(pgn: Game.fischerSpassky)

    #expect(game == gameFromPGN)
  }

  // MARK: Tags

  @Test func tagParsing() throws {
    let game = try PGNParser.parse(game: Game.fischerSpassky)
    #expect(game.tags.event == "F/S Return Match")
    #expect(game.tags.site == "Belgrade, Serbia JUG")
    #expect(game.tags.date == "1992.11.04")
    #expect(game.tags.round == "29")
    #expect(game.tags.white == "Fischer, Robert J.")
    #expect(game.tags.black == "Spassky, Boris V.")
    #expect(game.tags.result == "1/2-1/2")
    #expect(game.tags.annotator == "Mr. Annotator")
    #expect(game.tags.plyCount == "85")
    #expect(game.tags.timeControl == "?")
    #expect(game.tags.time == "??:??:??")
    #expect(game.tags.termination == "normal")
    #expect(game.tags.mode == "OTB")
  }

  @Test func tagParsingIrregularWhitespace() throws {
    let game = try PGNParser.parse(
      game: """
            [Tag1 "A"     ]
        [      Tag2   "B"]
            [ Tag3"C"      ]

        1. e4 e5
        """)

    #expect(game.tags.other["Tag1"] == "A")
    #expect(game.tags.other["Tag2"] == "B")
    #expect(game.tags.other["Tag3"] == "C")
  }

  @Test func customTagParsing() throws {
    // invalid pair
    #expect(throws: PGNParser.Error.invalidTagFormat) {
      try PGNParser.parse(game: "[a]\n\n1. e4 e5")
    }

    // custom tag
    let g2 = try PGNParser.parse(game: "[Custom_Tag \"Value\"]\n\n1. e4 e5")
    #expect(g2.tags.other["Custom_Tag"] == "Value")

    // duplicate tags
    let g3 = try PGNParser.parse(game: "[CustomTag \"Value\"] [CustomTag \"Value2\"]\n\n1. e4 e5")
    #expect(g3.tags.other["CustomTag"] == "Value")
  }

  // MARK: MoveText

  @Test func moveTextParsing() throws {
    let game = try PGNParser.parse(game: Game.fischerSpassky)

    // starting position + 85 ply
    #expect(game.positions.keys.count == 86)

    #expect(game.moves[.init(number: 1, color: .white)]?.assessment == .blunder)
    #expect(game.moves[.init(number: 1, color: .black)]?.assessment == .brilliant)
    #expect(game.moves[.init(number: 3, color: .black)]?.comment == "This opening is called the Ruy Lopez.")
    #expect(game.moves[.init(number: 4, color: .white)]?.comment == "test comment")
    #expect(game.positions[.init(number: 7, color: .black)]?.assessment == .blackHasDecisiveCounterplay)
    #expect(game.moves[.init(number: 10, color: .white)]?.end == .d4)
    #expect(game.moves[.init(number: 18, color: .black)]?.piece.kind == .queen)
    #expect(game.moves[.init(number: 18, color: .black)]?.end == .e7)
    #expect(game.moves[.init(number: 36, color: .white)]?.checkState == .check)
  }

  @Test func numberlessMoveTextParsing() throws {
    let game = try PGNParser.parse(game: "e4 e5 Nf3")
    #expect(game.moves[.init(number: 1, color: .white)]?.san == "e4")
    #expect(game.moves[.init(number: 1, color: .black)]?.san == "e5")
    #expect(game.moves[.init(number: 2, color: .white)]?.san == "Nf3")
  }

  @Test func startWithBlack() throws {
    let g1 = try PGNParser.parse(game: "[FEN \"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1\"][SetUp \"1\"]\n\n1... e5 2. Nf3 Nc6")
    #expect(g1.moves[.init(number: 1, color: .white)] == nil)
    #expect(g1.moves[.init(number: 1, color: .black)]?.san == "e5")
    #expect(g1.moves[.init(number: 2, color: .white)]?.san == "Nf3")
    #expect(g1.moves[.init(number: 2, color: .black)]?.san == "Nc6")

    let g2 = try PGNParser.parse(game: "[FEN \"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1\"][SetUp \"1\"]\n\ne5 Nf3 Nc6")
    #expect(g2.moves[.init(number: 1, color: .white)] == nil)
    #expect(g2.moves[.init(number: 1, color: .black)]?.san == "e5")
    #expect(g2.moves[.init(number: 2, color: .white)]?.san == "Nf3")
    #expect(g2.moves[.init(number: 2, color: .black)]?.san == "Nc6")
  }

  @Test func variationParsing() throws {
    let game = try PGNParser.parse(game: "1. e4 e5 (1... c6)")

    // starting position + 3 ply
    #expect(game.positions.keys.count == 4)

    #expect(game.moves[.init(number: 1, color: .white)]?.san == "e4")
    #expect(game.moves[.init(number: 1, color: .black)]?.san == "e5")
    #expect(game.moves[.init(number: 1, color: .black, variation: 1)]?.san == "c6")
  }

  // MARK: Errors

  @Test func tooManyLineBreaksError() throws {
    #expect(throws: PGNParser.Error.tooManyLineBreaks) {
      try PGNParser.parse(game: "[Round \"1\"]\n\n1.e4 e5\n\n2. Nf3 Nc6")
    }
  }

  @Test func invalidSetUpOrFENError() throws {
    #expect(throws: PGNParser.Error.invalidSetUpOrFEN) {
      try PGNParser.parse(game: "[SetUp \"2\"]\n\n1. e4 e5")
    }

    #expect(throws: PGNParser.Error.invalidSetUpOrFEN) {
      try PGNParser.parse(game: "[FEN \"invalid\"] [SetUp \"1\"]\n\n1. e4 e5")
    }
  }

  @Test func unexpectedCharacterError() throws {
    #expect(throws: PGNParser.Error.unexpectedTagCharacter("%")) {
      try PGNParser.parse(game: "[Tag% \"Value\"]\n\n1. e4 e5")
    }
  }

  @Test func tagTokenErrors() throws {
    #expect(throws: PGNParser.Error.mismatchedTagBrackets) {
      try PGNParser.parse(game: "][Tag \"Value\"\n\n1.e4 e5")
    }

    #expect(throws: PGNParser.Error.tagSymbolNotFound) {
      try PGNParser.parse(game: "[\"Tag\" \"Value\"]\n\n1.e4 e5")
    }

    #expect(throws: PGNParser.Error.tagStringNotFound) {
      try PGNParser.parse(game: "[Tag Value ]\n\n1.e4 e5")
    }
  }

  @Test func unexpectedMoveTextTokenError() throws {
    #expect(throws: PGNParser.Error.unexpectedMoveTextToken) {
      try PGNParser.parse(game: "$0 1. e4 abc123 2. Nc6")
    }
  }

  @Test func invalidMoveError() throws {
    #expect(throws: PGNParser.Error.invalidMove("abc123")) {
      try PGNParser.parse(game: "1. e4 abc123 2. Nc6")
    }

    #expect(throws: PGNParser.Error.invalidMove("abc123")) {
      try PGNParser.parse(game: "abc123 e5 Nc6")
    }
  }

  @Test func invalidAnnotationError() throws {
    #expect(throws: PGNParser.Error.invalidAnnotation("$$0")) {
      try PGNParser.parse(game: "1. e4 e5 $$0 2. Nc6")
    }

    #expect(throws: PGNParser.Error.invalidAnnotation("$999")) {
      try PGNParser.parse(game: "1. e4 e5 $999 2. Nc6")
    }

    #expect(throws: PGNParser.Error.invalidAnnotation("!!!")) {
      try PGNParser.parse(game: "1. e4 e5!!! 2. Nc6")
    }

    #expect(throws: PGNParser.Error.invalidAnnotation("□□")) {
      try PGNParser.parse(game: "1. e4 e5□□ 2. Nc6")
    }
  }

  @Test func unpairedCommentDelimiterError() throws {
    #expect(throws: PGNParser.Error.unpairedCommentDelimiter) {
      try PGNParser.parse(game: "1. e4 e5 2. c6 } { this is a comment }")
    }
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
    // remove position assessment as it was not supported
    // in legacy parser
    let pgn = Game.fischerSpassky.replacingOccurrences(of: "$135 ", with: "")

    #expect(
      try PGNParser.parse(game: pgn) == PGNParser.parse(game: pgn, startingWith: .standard)
    )
  }

}
