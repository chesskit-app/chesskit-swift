//
//  EngineLANParserTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

class EngineLANParserTests: XCTestCase {

    func testCastling() {
        let p1 = Position(fen: "r3k3/8/8/8/8/8/8/4K2R w Kq - 0 1")!
        let shortCastle = EngineLANParser.parse(move: "e1g1", for: .white, in: p1)
        XCTAssertEqual(shortCastle?.result, .castle(.wK))

        let p2 = Position(fen: "r3k3/8/8/8/8/8/8/5RK1 b q - 0 1")!
        let longCastle = EngineLANParser.parse(move: "e8c8", for: .black, in: p2)
        XCTAssertEqual(longCastle?.result, .castle(.bQ))
    }

    func testPromotion() {
        let p = Position(fen: "8/P7/8/8/8/8/8/8 w - - 0 1")!

        let qPromotion = EngineLANParser.parse(move: "a7a8q", for: .white, in: p)
        let promotedQueen = Piece(.queen, color: .white, square: .a8)
        XCTAssertEqual(qPromotion?.promotedPiece, promotedQueen)

        let rPromotion = EngineLANParser.parse(move: "a7a8r", for: .white, in: p)
        let promotedRook = Piece(.rook, color: .white, square: .a8)
        XCTAssertEqual(rPromotion?.promotedPiece, promotedRook)

        let bPromotion = EngineLANParser.parse(move: "a7a8b", for: .white, in: p)
        let promotedBishop = Piece(.bishop, color: .white, square: .a8)
        XCTAssertEqual(bPromotion?.promotedPiece, promotedBishop)

        let nPromotion = EngineLANParser.parse(move: "a7a8n", for: .white, in: p)
        let promotedKnight = Piece(.knight, color: .white, square: .a8)
        XCTAssertEqual(nPromotion?.promotedPiece, promotedKnight)
    }

    func testValidLANButInvalidMove() {
        XCTAssertNil(EngineLANParser.parse(move: "a4b5", for: .white, in: .standard))
        XCTAssertNil(EngineLANParser.parse(move: "f8b5", for: .black, in: .standard))
    }

    func testInvalidLAN() {
        XCTAssertNil(EngineLANParser.parse(move: "bad move", for: .white, in: .standard))
    }

}
