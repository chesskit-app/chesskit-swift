//
//  PieceTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

class PieceTests: XCTestCase {
    
    func testNotation() {
        let pawn = Piece.Kind.pawn
        XCTAssertEqual(pawn.value, 1)
        XCTAssertEqual(pawn.notation, "")
        
        let bishop = Piece.Kind.bishop
        XCTAssertEqual(bishop.value, 3)
        XCTAssertEqual(bishop.notation, "B")
        
        let knight = Piece.Kind.knight
        XCTAssertEqual(knight.value, 3)
        XCTAssertEqual(knight.notation, "N")
        
        let rook = Piece.Kind.rook
        XCTAssertEqual(rook.value, 5)
        XCTAssertEqual(rook.notation, "R")
        
        let queen = Piece.Kind.queen
        XCTAssertEqual(queen.value, 9)
        XCTAssertEqual(queen.notation, "Q")
        
        let king = Piece.Kind.king
        XCTAssertEqual(king.value, 0)
        XCTAssertEqual(king.notation, "K")
    }
    
    func testPieceColor() {
        let white = Piece.Color.white
        XCTAssertEqual(white.rawValue, "w")
        XCTAssertEqual(white.opposite, .black)
        
        let black = Piece.Color.black
        XCTAssertEqual(black.rawValue, "b")
        XCTAssertEqual(black.opposite, .white)
    }
    
    func testFenRepresentation() {
        let sq = Square.a1
        
        let wP = Piece(fen: "P", square: sq)
        XCTAssertEqual(wP?.color, .white)
        XCTAssertEqual(wP?.kind, .pawn)
        XCTAssertEqual(wP?.square, sq)
        
        let wB = Piece(fen: "B", square: sq)
        XCTAssertEqual(wB?.color, .white)
        XCTAssertEqual(wB?.kind, .bishop)
        XCTAssertEqual(wB?.square, sq)
        
        let wN = Piece(fen: "N", square: sq)
        XCTAssertEqual(wN?.color, .white)
        XCTAssertEqual(wN?.kind, .knight)
        XCTAssertEqual(wN?.square, sq)
        
        let wR = Piece(fen: "R", square: sq)
        XCTAssertEqual(wR?.color, .white)
        XCTAssertEqual(wR?.kind, .rook)
        XCTAssertEqual(wR?.square, sq)
        
        let wQ = Piece(fen: "Q", square: sq)
        XCTAssertEqual(wQ?.color, .white)
        XCTAssertEqual(wQ?.kind, .queen)
        XCTAssertEqual(wQ?.square, sq)
        
        let wK = Piece(fen: "K", square: sq)
        XCTAssertEqual(wK?.color, .white)
        XCTAssertEqual(wK?.kind, .king)
        XCTAssertEqual(wK?.square, sq)
        
        let bP = Piece(fen: "p", square: sq)
        XCTAssertEqual(bP?.color, .black)
        XCTAssertEqual(bP?.kind, .pawn)
        XCTAssertEqual(bP?.square, sq)
        
        let bB = Piece(fen: "b", square: sq)
        XCTAssertEqual(bB?.color, .black)
        XCTAssertEqual(bB?.kind, .bishop)
        XCTAssertEqual(bB?.square, sq)
        
        let bN = Piece(fen: "n", square: sq)
        XCTAssertEqual(bN?.color, .black)
        XCTAssertEqual(bN?.kind, .knight)
        XCTAssertEqual(bN?.square, sq)
        
        let bR = Piece(fen: "r", square: sq)
        XCTAssertEqual(bR?.color, .black)
        XCTAssertEqual(bR?.kind, .rook)
        XCTAssertEqual(bR?.square, sq)
        
        let bQ = Piece(fen: "q", square: sq)
        XCTAssertEqual(bQ?.color, .black)
        XCTAssertEqual(bQ?.kind, .queen)
        XCTAssertEqual(bQ?.square, sq)
        
        let bK = Piece(fen: "k", square: sq)
        XCTAssertEqual(bK?.color, .black)
        XCTAssertEqual(bK?.kind, .king)
        XCTAssertEqual(bK?.square, sq)
    }
    
    func testInvalidFenRepresentation() {
        let invalidFen = Piece(fen: "invalid", square: .a1)
        XCTAssertNil(invalidFen)
    }
    
}
