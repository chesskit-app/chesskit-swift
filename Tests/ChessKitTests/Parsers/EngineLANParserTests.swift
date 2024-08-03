//
//  EngineLANParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

class EngineLANParserTests: XCTestCase {

    func testCapture() {
        let position = Position(fen: "8/8/8/4p3/3P4/8/8/8 w - - 0 1")!
        let move = EngineLANParser.parse(move: "d4e5", for: .white, in: position)

        let capturedPiece = Piece(.pawn, color: .black, square: .e5)
        XCTAssertEqual(move?.result, .capture(capturedPiece))
    }

    func testCastling() {
        let p1 = Position(fen: "8/8/8/8/8/8/8/4K2R w KQ - 0 1")!
        let wShortCastle = EngineLANParser.parse(move: "e1g1", for: .white, in: p1)
        XCTAssertEqual(wShortCastle?.result, .castle(.wK))

        let p2 = Position(fen: "8/8/8/8/8/8/8/R3K3 w KQ - 0 1")!
        let wLongCastle = EngineLANParser.parse(move: "e1c1", for: .white, in: p2)
        XCTAssertEqual(wLongCastle?.result, .castle(.wQ))

        let p3 = Position(fen: "4k2r/8/8/8/8/8/8/8 b kq - 0 1")!
        let bShortCastle = EngineLANParser.parse(move: "e8g8", for: .black, in: p3)
        XCTAssertEqual(bShortCastle?.result, .castle(.bK))

        let p4 = Position(fen: "r3k3/8/8/8/8/8/8/8 b kq - 0 1")!
        let bLongCastle = EngineLANParser.parse(move: "e8c8", for: .black, in: p4)
        XCTAssertEqual(bLongCastle?.result, .castle(.bQ))
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
