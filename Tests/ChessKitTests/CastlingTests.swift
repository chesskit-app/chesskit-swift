//
//  CastlingTests.swift
//  ChessKit
//

@testable import ChessKit
import Testing

struct CastlingTests {

  @Test func castling() {
    var board = Board(position: .castling)
    #expect(board.position.legalCastlings.contains(.bK))
    #expect(!board.position.legalCastlings.contains(.wK))
    #expect(!board.position.legalCastlings.contains(.bQ))
    #expect(board.position.legalCastlings.contains(.wQ))

    // white queenside castle
    let wQmove = board.move(pieceAt: .e1, to: .c1)!
    #expect(wQmove.result == .castle(.wQ))

    // black kingside castle
    let bkMove = board.move(pieceAt: .e8, to: .g8)!
    #expect(bkMove.result == .castle(.bK))
  }

  @Test func invalidCastling() {
    let position = Position(
      pieces: [
        .init(.queen, color: .black, square: .e8),
        .init(.king, color: .white, square: .e1),
        .init(.rook, color: .white, square: .h1)
      ]
    )
    var board = Board(position: position)

    // attempt to castle while in check
    #expect(!board.canMove(pieceAt: .e1, to: .g1))

    // attempt to castle through check
    board.move(pieceAt: .e8, to: .f8)
    #expect(!board.canMove(pieceAt: .e1, to: .g1))

    // valid castling move
    board.move(pieceAt: .f8, to: .h8)
    #expect(board.canMove(pieceAt: .e1, to: .g1))
  }

  @Test func invalidCastlingThroughPiece() {
    let position = Position(
      pieces: [
        .init(.bishop, color: .white, square: .f1),
        .init(.king, color: .white, square: .e1),
        .init(.rook, color: .white, square: .h1)
      ]
    )
    var board = Board(position: position)

    // attempt to castle through another piece
    #expect(!board.canMove(pieceAt: .e1, to: .g1))

    // valid castling move
    board.move(pieceAt: .f1, to: .c4)
    #expect(board.canMove(pieceAt: .e1, to: .g1))
  }

}
