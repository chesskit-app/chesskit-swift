//
//  FENParserTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

class FENParserTests: XCTestCase {

    func testStandardStartingPosition() {
        let p = Position.standard
        
        XCTAssertEqual(p.pieces.count, 32)
        XCTAssertEqual(p.sideToMove, .white)
        XCTAssertEqual(p.legalCastlings, LegalCastlings(legal: [.bK, .wK, .bQ, .wQ]))
        XCTAssertNil(p.enPassant)
        XCTAssertEqual(p.clock.halfmoves, 0)
        XCTAssertEqual(p.clock.fullmoves, 1)
    }
    
    func testComplexPiecePlacement() {
        let p = Position.complex
        
        XCTAssertEqual(p.pieces.count, 24)
        XCTAssertEqual(p.sideToMove, .black)
        XCTAssertEqual(p.legalCastlings, LegalCastlings(legal: [.bK, .bQ]))
        XCTAssertNil(p.enPassant)
        XCTAssertEqual(p.clock.halfmoves, 0)
        XCTAssertEqual(p.clock.fullmoves, 20)
        
        // pieces
        XCTAssertTrue(p.pieces.contains(Piece(.rook,   color: .black, square: .a8)))
        XCTAssertTrue(p.pieces.contains(Piece(.bishop, color: .black, square: .c8)))
        XCTAssertTrue(p.pieces.contains(Piece(.king,   color: .black, square: .e8)))
        XCTAssertTrue(p.pieces.contains(Piece(.knight, color: .black, square: .g8)))
        XCTAssertTrue(p.pieces.contains(Piece(.rook,   color: .black, square: .h8)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .black, square: .a7)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .black, square: .d7)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .black, square: .f7)))
        XCTAssertTrue(p.pieces.contains(Piece(.knight, color: .white, square: .g7)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .black, square: .h7)))
        XCTAssertTrue(p.pieces.contains(Piece(.knight, color: .black, square: .a6)))
        XCTAssertTrue(p.pieces.contains(Piece(.bishop, color: .white, square: .d6)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .black, square: .b5)))
        XCTAssertTrue(p.pieces.contains(Piece(.knight, color: .white, square: .d5)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .white, square: .e5)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .white, square: .h5)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .white, square: .g4)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .white, square: .d3)))
        XCTAssertTrue(p.pieces.contains(Piece(.queen,  color: .white, square: .f3)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .white, square: .a2)))
        XCTAssertTrue(p.pieces.contains(Piece(.pawn,   color: .white, square: .c2)))
        XCTAssertTrue(p.pieces.contains(Piece(.king,   color: .white, square: .e2)))
        XCTAssertTrue(p.pieces.contains(Piece(.queen,  color: .black, square: .a1)))
        XCTAssertTrue(p.pieces.contains(Piece(.bishop, color: .black, square: .g1)))
    }
    
    func testEnPassantPosition() {
        let whiteEP = Position(fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")!
        
        XCTAssertEqual(whiteEP.sideToMove, .black)
        XCTAssertEqual(whiteEP.enPassant, EnPassant(pawn: Piece(.pawn, color: .white, square: .e4)))
        
        let blackEP = Position(fen: "rnbqkbnr/pppppppp/8/4P3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2")!
        
        XCTAssertEqual(blackEP.sideToMove, .white)
        XCTAssertEqual(blackEP.enPassant, EnPassant(pawn: Piece(.pawn, color: .black, square: .e5)))
    }
    
    func testInvalidFen() {
        let p = Position(fen: "invalid")
        XCTAssertNil(p)
        
        let invalidSideToMove = Position(fen: "8/8/8/4p1K1/2k1P3/8/8/8 B - - 0 1")!
        XCTAssertEqual(invalidSideToMove.sideToMove, .white)
    }
    
    func testConvertPosition() {
        let standardFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        XCTAssertEqual(Position.standard.fen, standardFen)
        
        let complexFen = "r1b1k1nr/p2p1pNp/n2B4/1p1NP2P/6P1/3P1Q2/P1P1K3/q5b1 b kq - 0 20"
        XCTAssertEqual(Position.complex.fen, complexFen)
        
        let epFen = "rnbqkbnr/ppppp1pp/8/8/4Pp2/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        XCTAssertEqual(Position.ep.fen, epFen)
        
        let castlingFen = "4k2r/6r1/8/8/8/8/3R4/R3K3 w Qk - 0 1"
        XCTAssertEqual(Position.castling.fen, castlingFen)
        
        let fiftyMoveFen = "8/5k2/3p4/1p1Pp2p/pP2Pp1P/P4P1K/8/8 b - - 99 50"
        XCTAssertEqual(Position.fiftyMove.fen, fiftyMoveFen)
    }
    
}
