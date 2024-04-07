//
//  MoveTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

class MoveTests: XCTestCase {
    
    func testMoveSANInit() {
        let move = Move(result: .move, piece: .init(.pawn, color: .white, square: .e4), start: .e2, end: .e4)
        let moveFromSAN = Move(san: "e4", color: .white, position: .standard)
        
        XCTAssertEqual(move, moveFromSAN)
    }
    
    func testMoveInvalidSANInit() {
        XCTAssertNil(Move(san: "e5", color: .white, position: .standard))
    }
    
    func testMoveNotation() {
        let pawnD3 = Move(result: .move, piece: Piece(.pawn, color: .white, square: .d3), start: .d2, end: .d3)
        XCTAssertEqual(pawnD3.san, "d3")
        XCTAssertEqual(pawnD3.lan, "d2d3")
        
        let bishopF4 = Move(result: .move, piece: Piece(.bishop, color: .white, square: .f4), start: .c1, end: .f4)
        XCTAssertEqual(bishopF4.san, "Bf4")
        XCTAssertEqual(bishopF4.lan, "c1f4")
    }
    
    func testCaptureNotation() {
        let capturedPiece = Piece(.bishop, color: .black, square: .d5)
        let capturingPiece = Piece(.pawn, color: .white, square: .e4)
        let capture = Move(result: .capture(capturedPiece), piece: capturingPiece, start: .e4, end: .d5)
        XCTAssertEqual(capture.san, "exd5")
        XCTAssertEqual(capture.lan, "e4d5")
    }
    
    func testEnPassantNotation() {
        let ep = EnPassant(pawn: Piece(.pawn, color: .black, square: .d5))
        let move = Move(result: .capture(ep.pawn), piece: Piece(.pawn, color: .white, square: .e5), start: .e5, end: .d6)
        XCTAssertEqual(move.san, "exd6")
        XCTAssertEqual(move.lan, "e5d6")
    }
    
    func testCastlingNotation() {
        let shortCastle = Move(result: .castle(.bK), piece: Piece(.king, color: .black, square: .e8), start: .e8, end: .g8)
        XCTAssertEqual(shortCastle.san, "O-O")
        XCTAssertEqual(shortCastle.lan, "e8g8")
        
        let longCastle = Move(result: .castle(.bQ), piece: Piece(.king, color: .black, square: .e8), start: .e8, end: .c8, checkState: .checkmate)
        XCTAssertEqual(longCastle.san, "O-O-O#")
        XCTAssertEqual(longCastle.lan, "e8c8")
    }
    
    func testPromotionsNotation() {
        let pawn = Piece(.pawn, color: .white, square: .e8)
        let queen = Piece(.queen, color: .white, square: .e8)
        let rook = Piece(.rook, color: .white, square: .e8)
        
        var queenPromo = Move(result: .move, piece: pawn, start: .e7, end: .e8)
        queenPromo.promotedPiece = queen
        XCTAssertEqual(queenPromo.san, "e8=Q")
        XCTAssertEqual(queenPromo.lan, "e7e8q")
        
        let capturedPiece = Piece(.bishop, color: .black, square: .f8)
        var rookCapturePromo = Move(result: .capture(capturedPiece), piece: pawn, start: .e7, end: .f8, checkState: .check)
        rookCapturePromo.promotedPiece = rook
        XCTAssertEqual(rookCapturePromo.san, "exf8=R+")
        XCTAssertEqual(rookCapturePromo.lan, "e7f8r")
    }
    
    func testChecksNotation() {
        let check = Move(result: .move, piece: Piece(.queen, color: .white, square: .d4), start: .e3, end: .d4, checkState: .check)
        XCTAssertEqual(check.san, "Qd4+")
        XCTAssertEqual(check.lan, "e3d4")
    }
    
    func testCheckmateNotation() {
        let checkmate = Move(result: .move, piece: Piece(.rook, color: .white, square: .g7), start: .g4, end: .g7, checkState: .checkmate)
        XCTAssertEqual(checkmate.san, "Rg7#")
        XCTAssertEqual(checkmate.lan, "g4g7")
    }
    
    func testMoveAssessments() {
        XCTAssertEqual(Move.Assessment.null.notation, "")
        XCTAssertEqual(Move.Assessment.good.notation, "!")
        XCTAssertEqual(Move.Assessment.mistake.notation, "?")
        XCTAssertEqual(Move.Assessment.brilliant.notation, "!!")
        XCTAssertEqual(Move.Assessment.blunder.notation, "??")
        XCTAssertEqual(Move.Assessment.interesting.notation, "!?")
        XCTAssertEqual(Move.Assessment.dubious.notation, "?!")
        XCTAssertEqual(Move.Assessment.forced.notation, "□")
        XCTAssertEqual(Move.Assessment.singular.notation, "")
        XCTAssertEqual(Move.Assessment.worst.notation, "")
    }
    
}
