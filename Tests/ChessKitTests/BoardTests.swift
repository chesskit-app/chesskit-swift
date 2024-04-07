//
//  BoardTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

/// Test positions
extension Position {
    static let standard = Position(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")!

    static let complex = Position(fen: "r1b1k1nr/p2p1pNp/n2B4/1p1NP2P/6P1/3P1Q2/P1P1K3/q5b1 b kq - 0 20")!

    static let ep = Position(fen: "rnbqkbnr/ppppp1pp/8/8/4Pp2/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")!

    static let castling = Position(fen: "4k2r/6r1/8/8/8/8/3R4/R3K3 w Qk - 0 1")!

    static let fiftyMove = Position(fen: "8/5k2/3p4/1p1Pp2p/pP2Pp1P/P4P1K/8/8 b - - 99 50")!
}

class MockBoardDelegate: BoardDelegate {
    var didPromote: ((Move) -> Void)?
    var didEnd: ((Board.EndResult) -> Void)?

    func didPromote(with move: Move) {
        didPromote?(move)
    }

    func didEnd(with result: Board.EndResult) {
        didEnd?(result)
    }
}

class BoardTests: XCTestCase {

    func testEnPassant() {
        var board = Board(position: .ep)
        let ep = board.position.enPassant!

        let capturingPiece = board.position.piece(at: .f4)!
        XCTAssertTrue(ep.canBeCaptured(by: capturingPiece))

        let move = board.move(pieceAt: .f4, to: ep.captureSquare)!
        XCTAssertEqual(move.result, .capture(ep.pawn))
    }

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

    func testPromotion() {
        let pawn = Piece(.pawn, color: .white, square: .e7)
        let queen = Piece(.queen, color: .white, square: .e8)
        var board = Board(position: .init(pieces: [pawn]))

        let delegate = MockBoardDelegate()
        board.delegate = delegate

        var expectation: XCTestExpectation? = self.expectation(description: "Board returns promotion move")

        delegate.didPromote = { move in
            let newPawn = Piece(.pawn, color: .white, square: .e8)
            XCTAssertEqual(move.piece, newPawn)
            expectation?.fulfill()
            expectation = nil
        }

        let move = board.move(pieceAt: .e7, to: .e8)!
        waitForExpectations(timeout: 1.0)

        let promotionMove = board.completePromotion(of: move, to: .queen)
        XCTAssertEqual(promotionMove.result, .move)
        XCTAssertEqual(promotionMove.promotedPiece, queen)
        XCTAssertEqual(promotionMove.end, .e8)
    }

    func testFiftyMoveRule() {
        var board = Board(position: .fiftyMove)
        let delegate = MockBoardDelegate()
        board.delegate = delegate

        var expectation: XCTestExpectation? = self.expectation(description: "Board returns fifty move draw result")

        delegate.didEnd = { result in
            if case .draw(let drawType) = result {
                if drawType == .fiftyMoves {
                    expectation?.fulfill()
                    expectation = nil
                }
            } else {
                XCTFail()
            }
        }

        board.move(pieceAt: .f7, to: .f8)
        waitForExpectations(timeout: 1.0)
    }

    func testLegalMovesForNonexistentPiece() {
        let board = Board(position: .standard)
        // no piece at d4
        let legalMoves = board.legalMoves(forPieceAt: .d4)
        XCTAssertEqual(legalMoves.count, 0)
    }

    func testLegalPawnMoves() {
        let board = Board(position: .standard)
        let legalC2PawnMoves = board.legalMoves(forPieceAt: .c2)
        XCTAssertEqual(legalC2PawnMoves.count, 2)
        XCTAssertTrue(legalC2PawnMoves.contains(.c3))
        XCTAssertTrue(legalC2PawnMoves.contains(.c4))
        XCTAssertTrue(board.canMove(pieceAt: .c2, to: .c3))
        XCTAssertTrue(board.canMove(pieceAt: .c2, to: .c4))
        XCTAssertFalse(board.canMove(pieceAt: .c2, to: .c5))

        let legalF7PawnMoves = board.legalMoves(forPieceAt: .f7)
        XCTAssertEqual(legalF7PawnMoves.count, 2)
        XCTAssertTrue(legalF7PawnMoves.contains(.f6))
        XCTAssertTrue(legalF7PawnMoves.contains(.f5))
        XCTAssertTrue(board.canMove(pieceAt: .f7, to: .f6))
        XCTAssertTrue(board.canMove(pieceAt: .f7, to: .f5))
        XCTAssertFalse(board.canMove(pieceAt: .f7, to: .f4))
    }

    func testLegalKnightMoves() {
        
    }

    func testLegalBishopMoves() {
        
    }

    func testLegalRookMoves() {
        
    }

    func testLegalQueenMoves() {

    }

    func testLegalKingMoves() {

    }

    func testLegalMovePiece() {

    }

    func testCaptureMove() {

    }

    func testIllegalMove() {
        var board = Board(position: .standard)
        let move = board.move(pieceAt: .d2, to: .d5)
        XCTAssertNil(move)
    }

    func testCheckMove() {

    }

    func testCheckmateMove() {

    }
    
    func testSideToMove() {
        var position = Position.standard
        XCTAssertEqual(position.sideToMove, .white)
        
        position.toggleSideToMove()
        XCTAssertEqual(position.sideToMove, .black)
    }

    func testDisambiguation() {
        var board = Board(position: Position(fen: "3r3r/8/8/R7/4Q2Q/8/8/R7/7Q w - - 0 1")!)

        let whiteRookMove = board.move(pieceAt: .a1, to: .a3)
        let blackRookMove = board.move(pieceAt: .d8, to: .f8)
        let queenMove = board.move(pieceAt: .h4, to: .e1)

        XCTAssertEqual(whiteRookMove?.san, "R1a3")
        XCTAssertEqual(blackRookMove?.san, "Rdf8")
        XCTAssertEqual(queenMove?.san, "Qh4e1")
    }

}
