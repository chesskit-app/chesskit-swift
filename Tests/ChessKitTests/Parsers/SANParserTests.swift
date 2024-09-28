//
//  SANParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

final class SANParserTests: XCTestCase {

  func testCastling() {
    let p1 = Position(fen: "r3k3/8/8/8/8/8/8/4K2R w Kq - 0 1")!
    let shortCastle = SANParser.parse(move: "O-O", in: p1)
    XCTAssertEqual(shortCastle?.result, .castle(.wK))

    let p2 = Position(fen: "r3k3/8/8/8/8/8/8/5RK1 b q - 0 1")!
    let longCastle = SANParser.parse(move: "O-O-O", in: p2)
    XCTAssertEqual(longCastle?.result, .castle(.bQ))
  }

  func testPromotion() {
    let p = Position(fen: "8/P7/8/8/8/8/8/8 w - - 0 1")!
    let promotion = SANParser.parse(move: "a8=Q", in: p)

    let promotedPiece = Piece(.queen, color: .white, square: .a8)
    XCTAssertEqual(promotion?.promotedPiece, promotedPiece)
  }

  func testChecksAndMates() {
    let p1 = Position(fen: "8/k7/7Q/6R1/8/8/8/8 w - - 0 1")!

    let check = SANParser.parse(move: "Rg7+", in: p1)
    XCTAssertEqual(check?.checkState, .check)

    let p2 = Position(fen: "8/k5R1/7Q/8/8/8/8/8 b - - 0 1")!

    let kingMove = SANParser.parse(move: "Ka8", in: p2)
    XCTAssertEqual(kingMove?.checkState, Move.CheckState.none)

    let p3 = Position(fen: "k7/6R1/7Q/8/8/8/8/8 w - - 0 1")!

    let checkmate = SANParser.parse(move: "Qh8#", in: p3)
    XCTAssertEqual(checkmate?.checkState, .checkmate)
  }

  func testDisambiguation() {
    let pw = Position(fen: "3r3r/8/8/R7/4Q2Q/8/8/R6Q w - - 0 1")!
    let pb = Position(fen: "3r3r/8/8/R7/4Q2Q/8/8/R6Q b - - 0 1")!

    let rookFileMove = SANParser.parse(move: "R1a3", in: pw)
    XCTAssertEqual(rookFileMove?.result, .move)
    XCTAssertEqual(rookFileMove?.piece.kind, .rook)
    XCTAssertEqual(rookFileMove?.disambiguation, .byRank(1))
    XCTAssertEqual(rookFileMove?.start, .a1)
    XCTAssertEqual(rookFileMove?.end, .a3)
    XCTAssertEqual(rookFileMove?.promotedPiece, nil)
    XCTAssertEqual(rookFileMove?.checkState, Move.CheckState.none)

    let rookRankMove = SANParser.parse(move: "Rdf8", in: pb)
    XCTAssertEqual(rookRankMove?.result, .move)
    XCTAssertEqual(rookRankMove?.piece.kind, .rook)
    XCTAssertEqual(rookRankMove?.disambiguation, .byFile(.d))
    XCTAssertEqual(rookRankMove?.start, .d8)
    XCTAssertEqual(rookRankMove?.end, .f8)
    XCTAssertEqual(rookRankMove?.promotedPiece, nil)
    XCTAssertEqual(rookRankMove?.checkState, Move.CheckState.none)

    let queenMove = SANParser.parse(move: "Qh4e1", in: pw)
    XCTAssertEqual(queenMove?.result, .move)
    XCTAssertEqual(queenMove?.piece.kind, .queen)
    XCTAssertEqual(queenMove?.disambiguation, .bySquare(.h4))
    XCTAssertEqual(queenMove?.start, .h4)
    XCTAssertEqual(queenMove?.end, .e1)
    XCTAssertEqual(queenMove?.promotedPiece, nil)
    XCTAssertEqual(queenMove?.checkState, Move.CheckState.none)
  }

  func testValidSANButInvalidMove() {
    XCTAssertNil(SANParser.parse(move: "axb5", in: .standard))
    XCTAssertNil(SANParser.parse(move: "Bb5", in: .standard))
  }

  func testInvalidSAN() {
    XCTAssertNil(SANParser.parse(move: "bad move", in: .standard))
  }

}
