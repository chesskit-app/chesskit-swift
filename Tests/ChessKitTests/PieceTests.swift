//
//  PieceTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct PieceTests {

  @Test func notation() {
    let pawn = Piece.Kind.pawn
    #expect(pawn.notation == "")
    #expect(String(describing: pawn) == "Pawn")

    let bishop = Piece.Kind.bishop
    #expect(bishop.notation == "B")
    #expect(String(describing: bishop) == "Bishop")

    let knight = Piece.Kind.knight
    #expect(knight.notation == "N")
    #expect(String(describing: knight) == "Knight")

    let rook = Piece.Kind.rook
    #expect(rook.notation == "R")
    #expect(String(describing: rook) == "Rook")

    let queen = Piece.Kind.queen
    #expect(queen.notation == "Q")
    #expect(String(describing: queen) == "Queen")

    let king = Piece.Kind.king
    #expect(king.notation == "K")
    #expect(String(describing: king) == "King")
  }

  @Test func pieceColor() {
    let white = Piece.Color.white
    #expect(white.rawValue == "w")
    #expect(white.opposite == .black)
    #expect(String(describing: white) == "White")

    let black = Piece.Color.black
    #expect(black.rawValue == "b")
    #expect(black.opposite == .white)
    #expect(String(describing: black) == "Black")
  }

  @Test func fenRepresentation() {
    let sq = Square.a1

    let wP = Piece(fen: "P", square: sq)
    #expect(wP?.color == .white)
    #expect(wP?.kind == .pawn)
    #expect(wP?.square == sq)

    let wB = Piece(fen: "B", square: sq)
    #expect(wB?.color == .white)
    #expect(wB?.kind == .bishop)
    #expect(wB?.square == sq)

    let wN = Piece(fen: "N", square: sq)
    #expect(wN?.color == .white)
    #expect(wN?.kind == .knight)
    #expect(wN?.square == sq)

    let wR = Piece(fen: "R", square: sq)
    #expect(wR?.color == .white)
    #expect(wR?.kind == .rook)
    #expect(wR?.square == sq)

    let wQ = Piece(fen: "Q", square: sq)
    #expect(wQ?.color == .white)
    #expect(wQ?.kind == .queen)
    #expect(wQ?.square == sq)

    let wK = Piece(fen: "K", square: sq)
    #expect(wK?.color == .white)
    #expect(wK?.kind == .king)
    #expect(wK?.square == sq)

    let bP = Piece(fen: "p", square: sq)
    #expect(bP?.color == .black)
    #expect(bP?.kind == .pawn)
    #expect(bP?.square == sq)

    let bB = Piece(fen: "b", square: sq)
    #expect(bB?.color == .black)
    #expect(bB?.kind == .bishop)
    #expect(bB?.square == sq)

    let bN = Piece(fen: "n", square: sq)
    #expect(bN?.color == .black)
    #expect(bN?.kind == .knight)
    #expect(bN?.square == sq)

    let bR = Piece(fen: "r", square: sq)
    #expect(bR?.color == .black)
    #expect(bR?.kind == .rook)
    #expect(bR?.square == sq)

    let bQ = Piece(fen: "q", square: sq)
    #expect(bQ?.color == .black)
    #expect(bQ?.kind == .queen)
    #expect(bQ?.square == sq)

    let bK = Piece(fen: "k", square: sq)
    #expect(bK?.color == .black)
    #expect(bK?.kind == .king)
    #expect(bK?.square == sq)
  }

  @Test func invalidFenRepresentation() {
    let invalidFen = Piece(fen: "invalid", square: .a1)
    #expect(invalidFen == nil)
  }

}
