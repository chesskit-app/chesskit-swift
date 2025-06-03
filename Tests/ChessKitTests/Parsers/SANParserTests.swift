//
//  SANParserTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct SANParserTests {

  @Test func castling() {
    let p1 = Position(fen: "r3k3/8/8/8/8/8/8/4K2R w Kq - 0 1")!
    let shortCastle = SANParser.parse(move: "O-O", in: p1)
    #expect(shortCastle?.result == .castle(.wK))

    let p2 = Position(fen: "r3k3/8/8/8/8/8/8/5RK1 b q - 0 1")!
    let longCastle = SANParser.parse(move: "O-O-O", in: p2)
    #expect(longCastle?.result == .castle(.bQ))
  }

  @Test func promotion() {
    let p = Position(fen: "8/P7/8/8/8/8/8/8 w - - 0 1")!
    let promotion = SANParser.parse(move: "a8=Q", in: p)

    let promotedPiece = Piece(.queen, color: .white, square: .a8)
    #expect(promotion?.promotedPiece == promotedPiece)
  }

  @Test func checksAndMates() {
    let p1 = Position(fen: "8/k7/7Q/6R1/8/8/8/8 w - - 0 1")!

    let check = SANParser.parse(move: "Rg7+", in: p1)
    #expect(check?.checkState == .check)

    let p2 = Position(fen: "8/k5R1/7Q/8/8/8/8/8 b - - 0 1")!

    let kingMove = SANParser.parse(move: "Ka8", in: p2)
    #expect(kingMove?.checkState == Move.CheckState.none)

    let p3 = Position(fen: "k7/6R1/7Q/8/8/8/8/8 w - - 0 1")!

    let checkmate = SANParser.parse(move: "Qh8#", in: p3)
    #expect(checkmate?.checkState == .checkmate)
  }

  @Test func disambiguation() {
    let pw = Position(fen: "3r3r/8/8/R7/4Q2Q/8/8/R6Q w - - 0 1")!
    let pb = Position(fen: "3r3r/8/8/R7/4Q2Q/8/8/R6Q b - - 0 1")!

    let rookFileMove = SANParser.parse(move: "R1a3", in: pw)
    #expect(rookFileMove?.result == .move)
    #expect(rookFileMove?.piece.kind == .rook)
    #expect(rookFileMove?.disambiguation == .byRank(1))
    #expect(rookFileMove?.start == .a1)
    #expect(rookFileMove?.end == .a3)
    #expect(rookFileMove?.promotedPiece == nil)
    #expect(rookFileMove?.checkState == Move.CheckState.none)

    let rookRankMove = SANParser.parse(move: "Rdf8", in: pb)
    #expect(rookRankMove?.result == .move)
    #expect(rookRankMove?.piece.kind == .rook)
    #expect(rookRankMove?.disambiguation == .byFile(.d))
    #expect(rookRankMove?.start == .d8)
    #expect(rookRankMove?.end == .f8)
    #expect(rookRankMove?.promotedPiece == nil)
    #expect(rookRankMove?.checkState == Move.CheckState.none)

    let queenMove = SANParser.parse(move: "Qh4e1", in: pw)
    #expect(queenMove?.result == .move)
    #expect(queenMove?.piece.kind == .queen)
    #expect(queenMove?.disambiguation == .bySquare(.h4))
    #expect(queenMove?.start == .h4)
    #expect(queenMove?.end == .e1)
    #expect(queenMove?.promotedPiece == nil)
    #expect(queenMove?.checkState == Move.CheckState.none)
  }

  @Test func testValidSANButInvalidMove() {
    #expect(SANParser.parse(move: "axb5", in: .standard) == nil)
    #expect(SANParser.parse(move: "Bb5", in: .standard) == nil)
  }

  @Test func invalidSAN() {
    #expect(SANParser.parse(move: "e44", in: .standard) == nil)
    #expect(SANParser.parse(move: "aNf3", in: .standard) == nil)
    #expect(SANParser.parse(move: "bad move", in: .standard) == nil)
  }

}
