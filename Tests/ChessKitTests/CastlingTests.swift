//
//  CastlingTests.swift
//  ChessKit
//

@testable import ChessKit
import XCTest

final class CastlingTests: XCTestCase {

    func testCastling() {
        var board = Board(position: .castling)
        XCTAssertTrue(board.position.legalCastlings.contains(.bK))
        XCTAssertFalse(board.position.legalCastlings.contains(.wK))
        XCTAssertFalse(board.position.legalCastlings.contains(.bQ))
        XCTAssertTrue(board.position.legalCastlings.contains(.wQ))

        // white queenside castle
        let wQmove = board.move(pieceAt: .e1, to: .c1)!
        XCTAssertEqual(wQmove.result, .castle(.wQ))

        // black kingside castle
        let bkMove = board.move(pieceAt: .e8, to: .g8)!
        XCTAssertEqual(bkMove.result, .castle(.bK))
    }

    func testInvalidCastling() {
        let position = Position(
            pieces: [
                .init(.queen, color: .black, square: .e8),
                .init(.king, color: .white, square: .e1),
                .init(.rook, color: .white, square: .h1)
            ]
        )
        var board = Board(position: position)

        // attempt to castle while in check
        XCTAssertFalse(board.canMove(pieceAt: .e1, to: .g1))

        // attempt to castle through check
        board.move(pieceAt: .e8, to: .f8)
        XCTAssertFalse(board.canMove(pieceAt: .e1, to: .g1))

        // valid castling move
        board.move(pieceAt: .f8, to: .h8)
        XCTAssertTrue(board.canMove(pieceAt: .e1, to: .g1))
    }

    func testInvalidCastlingThroughPiece() {
        let position = Position(
            pieces: [
                .init(.bishop, color: .white, square: .f1),
                .init(.king, color: .white, square: .e1),
                .init(.rook, color: .white, square: .h1)
            ]
        )
        var board = Board(position: position)

        // attempt to castle through another piece
        XCTAssertFalse(board.canMove(pieceAt: .e1, to: .g1))

        // valid castling move
        board.move(pieceAt: .f1, to: .c4)
        XCTAssertTrue(board.canMove(pieceAt: .e1, to: .g1))
    }

}
