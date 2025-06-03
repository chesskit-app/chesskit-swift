//
//  PGNParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct PGNParserTests {

  @Test func gameFromPGN() {
    let game = PGNParser.parse(game: Game.fischerSpassky)
    let gameFromPGN = Game(pgn: Game.fischerSpassky)

    #expect(game == gameFromPGN)
  }

  @Test func tagParsing() {
    let game = PGNParser.parse(game: Game.fischerSpassky)

    // tags
    #expect(game.tags.event == "F/S Return Match")
    #expect(game.tags.site == "Belgrade, Serbia JUG")
    #expect(game.tags.date == "1992.11.04")
    #expect(game.tags.round == "29")
    #expect(game.tags.white == "Fischer, Robert J.")
    #expect(game.tags.black == "Spassky, Boris V.")
    #expect(game.tags.result == "1/2-1/2")
  }

  @Test func customTagParsing() {
    // invalid pair
    let g1 = PGNParser.parse(game: "[a] 1. e4 e5")
    #expect(g1.tags.other["a"] == nil)

    // custom tag
    let g2 = PGNParser.parse(game: "[CustomTag \"Value\"] 1. e4 e5")
    #expect(g2.tags.other["CustomTag"] == "Value")

    // duplicate tags
    let g3 = PGNParser.parse(game: "[CustomTag \"Value\"] [CustomTag \"Value2\"] 1. e4 e5")
    #expect(g3.tags.other["CustomTag"] == "Value")
  }

  @Test func validResultParsing() {
    let g1 = PGNParser.parse(game: "1. e4 e5 1/2-1/2")
    #expect(g1.tags.result == "1/2-1/2")

    let g2 = PGNParser.parse(game: "1. e4 e5 1-0")
    #expect(g2.tags.result == "1-0")

    let g3 = PGNParser.parse(game: "1. e4 e5 0-1")
    #expect(g3.tags.result == "0-1")

    let g4 = PGNParser.parse(game: "1. e4 e5 *")
    #expect(g4.tags.result == "*")
  }

  @Test func invalidResultParsing() {
    let g1 = PGNParser.parse(game: "1. e4 e5 ***")
    #expect(g1.tags.result == "")

    let g2 = PGNParser.parse(game: "1. e4 e5 test")
    #expect(g2.tags.result == "")

    let g3 = PGNParser.parse(game: "1. e4 e5 1-00-1")
    #expect(g3.tags.result == "")
  }

  @Test func moveTextParsing() {
    let game = PGNParser.parse(game: Game.fischerSpassky)

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

}
