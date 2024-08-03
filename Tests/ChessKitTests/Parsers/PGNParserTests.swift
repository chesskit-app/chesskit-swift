//
//  PGNParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

class PGNParserTests: XCTestCase {

    func testGameFromPGN() {
        let game = PGNParser.parse(game: Game.fischerSpassky)
        let gameFromPGN = Game(pgn: Game.fischerSpassky)

        XCTAssertEqual(game, gameFromPGN)
    }

    func testTagParsing() {
        let game = PGNParser.parse(game: Game.fischerSpassky)

        // tags
        XCTAssertEqual(game?.tags.event, "F/S Return Match")
        XCTAssertEqual(game?.tags.site, "Belgrade, Serbia JUG")
        XCTAssertEqual(game?.tags.date, "1992.11.04")
        XCTAssertEqual(game?.tags.round, "29")
        XCTAssertEqual(game?.tags.white, "Fischer, Robert J.")
        XCTAssertEqual(game?.tags.black, "Spassky, Boris V.")
        XCTAssertEqual(game?.tags.result, "1/2-1/2")
    }

    func testMoveTextParsing() {
        let game = PGNParser.parse(game: Game.fischerSpassky)

        // starting position + 85 ply
        XCTAssertEqual(game?.positions.keys.count, 86)
        
        XCTAssertEqual(game?.moves[.init(
            number: 1,
            color: .white
        )]?.assessment, .blunder)
        XCTAssertEqual(game?.moves[.init(
            number: 1,
            color: .black
        )]?.assessment, .brilliant)
        XCTAssertEqual(game?.moves[.init(
            number: 3,
            color: .black
        )]?.comment, "This opening is called the Ruy Lopez.")
        XCTAssertEqual(game?.moves[.init(
            number: 4,
            color: .white
        )]?.comment, "test comment")
        XCTAssertEqual(game?.moves[.init(
            number: 10,
            color: .white
        )]?.end, .d4)
        XCTAssertEqual(game?.moves[.init(
            number: 18,
            color: .black
        )]?.piece.kind, .queen)
        XCTAssertEqual(game?.moves[.init(
            number: 18,
            color: .black
        )]?.end, .e7)
        XCTAssertEqual(game?.moves[.init(
            number: 36,
            color: .white
        )]?.checkState, .check)
    }

}
