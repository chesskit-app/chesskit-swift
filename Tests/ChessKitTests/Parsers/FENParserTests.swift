//
//  FENParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct FENParserTests {

  @Test func standardStartingPosition() {
    let p = Position.standard

    #expect(p.pieces.count == 32)
    #expect(p.sideToMove == .white)
    #expect(p.legalCastlings == LegalCastlings(legal: [.bK, .wK, .bQ, .wQ]))
    #expect(p.enPassant == nil)
    #expect(p.clock.halfmoves == 0)
    #expect(p.clock.fullmoves == 1)
  }

  @Test func complexPiecePlacement() {
    let p = Position.complex

    #expect(p.pieces.count == 24)
    #expect(p.sideToMove == .black)
    #expect(p.legalCastlings == LegalCastlings(legal: [.bK, .bQ]))
    #expect(p.enPassant == nil)
    #expect(p.clock.halfmoves == 0)
    #expect(p.clock.fullmoves == 20)

    // pieces
    #expect(p.pieces.contains(Piece(.rook, color: .black, square: .a8)))
    #expect(p.pieces.contains(Piece(.bishop, color: .black, square: .c8)))
    #expect(p.pieces.contains(Piece(.king, color: .black, square: .e8)))
    #expect(p.pieces.contains(Piece(.knight, color: .black, square: .g8)))
    #expect(p.pieces.contains(Piece(.rook, color: .black, square: .h8)))
    #expect(p.pieces.contains(Piece(.pawn, color: .black, square: .a7)))
    #expect(p.pieces.contains(Piece(.pawn, color: .black, square: .d7)))
    #expect(p.pieces.contains(Piece(.pawn, color: .black, square: .f7)))
    #expect(p.pieces.contains(Piece(.knight, color: .white, square: .g7)))
    #expect(p.pieces.contains(Piece(.pawn, color: .black, square: .h7)))
    #expect(p.pieces.contains(Piece(.knight, color: .black, square: .a6)))
    #expect(p.pieces.contains(Piece(.bishop, color: .white, square: .d6)))
    #expect(p.pieces.contains(Piece(.pawn, color: .black, square: .b5)))
    #expect(p.pieces.contains(Piece(.knight, color: .white, square: .d5)))
    #expect(p.pieces.contains(Piece(.pawn, color: .white, square: .e5)))
    #expect(p.pieces.contains(Piece(.pawn, color: .white, square: .h5)))
    #expect(p.pieces.contains(Piece(.pawn, color: .white, square: .g4)))
    #expect(p.pieces.contains(Piece(.pawn, color: .white, square: .d3)))
    #expect(p.pieces.contains(Piece(.queen, color: .white, square: .f3)))
    #expect(p.pieces.contains(Piece(.pawn, color: .white, square: .a2)))
    #expect(p.pieces.contains(Piece(.pawn, color: .white, square: .c2)))
    #expect(p.pieces.contains(Piece(.king, color: .white, square: .e2)))
    #expect(p.pieces.contains(Piece(.queen, color: .black, square: .a1)))
    #expect(p.pieces.contains(Piece(.bishop, color: .black, square: .g1)))
  }

  @Test func enPassantPosition() {
    let whiteEP = Position(fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")!

    #expect(whiteEP.sideToMove == .black)
    #expect(whiteEP.enPassant == EnPassant(pawn: Piece(.pawn, color: .white, square: .e4)))

    let blackEP = Position(fen: "rnbqkbnr/pppppppp/8/4P3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2")!

    #expect(blackEP.sideToMove == .white)
    #expect(blackEP.enPassant == EnPassant(pawn: Piece(.pawn, color: .black, square: .e5)))
  }

  @Test func invalidFen() {
    let p = Position(fen: "invalid")
    #expect(p == nil)

    let invalidSideToMove = Position(fen: "8/8/8/4p1K1/2k1P3/8/8/8 B - - 0 1")!
    #expect(invalidSideToMove.sideToMove == .white)
  }

  @Test func convertPosition() {
    let standardFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    #expect(Position.standard.fen == standardFen)

    let complexFen = "r1b1k1nr/p2p1pNp/n2B4/1p1NP2P/6P1/3P1Q2/P1P1K3/q5b1 b kq - 0 20"
    #expect(Position.complex.fen == complexFen)

    let epFen = "rnbqkbnr/ppppp1pp/8/8/4Pp2/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    #expect(Position.ep.fen == epFen)

    let castlingFen = "4k2r/6r1/8/8/8/8/3R4/R3K3 w Qk - 0 1"
    #expect(Position.castling.fen == castlingFen)

    let fiftyMoveFen = "8/5k2/3p4/1p1Pp2p/pP2Pp1P/P4P1K/8/8 b - - 99 50"
    #expect(Position.fiftyMove.fen == fiftyMoveFen)
  }

}
