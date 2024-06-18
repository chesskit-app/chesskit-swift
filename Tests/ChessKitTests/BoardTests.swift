//
//  BoardTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

/// Test positions
extension Position {
    static let standard = Position(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")!

    static let complex = Position(fen: "r1b1k1nr/p2p1pNp/n2B4/1p1NP2P/6P1/3P1Q2/P1P1K3/q5b1 b kq - 0 20")!

    static let ep = Position(fen: "rnbqkbnr/ppppp1pp/8/8/4Pp2/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")!

    static let castling = Position(fen: "4k2r/6r1/8/8/8/8/3R4/R3K3 w Qk - 0 1")!

    static let fiftyMove = Position(fen: "8/5k2/3p4/1p1Pp2p/pP2Pp1P/P4P1K/8/8 b - - 99 50")!

    static let insufficientMaterial = Position(fen: "k7/b6P/8/8/8/8/8/K7 w - - 0 1")!
}

final class MockBoardDelegate: BoardDelegate {
    private let didPromote: (@Sendable (Move) -> Void)?
    private let didEnd: (@Sendable (Board.EndResult) -> Void)?

    init(
        didPromote: (@Sendable (Move) -> Void)? = nil,
        didEnd: (@Sendable (Board.EndResult) -> Void)? = nil
    ) {
        self.didPromote = didPromote
        self.didEnd = didEnd
    }

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

    func testIllegalEnPassant() {
        // fen position contains illegal en passant move
        let board = Board(position: .init(fen: "1nbqkbnr/1pp1pppp/8/r1Pp3K/p7/5P2/PP1PP1PP/RNBQ1BNR w k d6 0 8")!)
        XCTAssertFalse(board.canMove(pieceAt: .c5, to: .d6))
    }

    func testPromotion() {
        let pawn = Piece(.pawn, color: .white, square: .e7)
        let queen = Piece(.queen, color: .white, square: .e8)
        var board = Board(position: .init(pieces: [pawn]))

        nonisolated(unsafe) var expectation: XCTestExpectation? = self.expectation(description: "Board returns promotion move")

        let delegate = MockBoardDelegate(didPromote: { move in
            let newPawn = Piece(.pawn, color: .white, square: .e8)
            XCTAssertEqual(move.piece, newPawn)
            expectation?.fulfill()
            expectation = nil
        })
        board.delegate = delegate

        let move = board.move(pieceAt: .e7, to: .e8)!
        waitForExpectations(timeout: 1.0)

        let promotionMove = board.completePromotion(of: move, to: .queen)
        XCTAssertEqual(promotionMove.result, .move)
        XCTAssertEqual(promotionMove.promotedPiece, queen)
        XCTAssertEqual(promotionMove.end, .e8)
    }

    func testFiftyMoveRule() {
        var board = Board(position: .fiftyMove)
        nonisolated(unsafe) var expectation: XCTestExpectation? = self.expectation(description: "Board returns fifty move draw result")

        let delegate = MockBoardDelegate(didEnd: { result in
            if case .draw(let drawType) = result {
                if drawType == .fiftyMoves {
                    expectation?.fulfill()
                    expectation = nil
                }
            } else {
                XCTFail()
            }
        })
        board.delegate = delegate

        board.move(pieceAt: .f7, to: .f8)
        waitForExpectations(timeout: 1.0)
    }

    func testInsufficientMaterial() {
        var board = Board(position: .insufficientMaterial)
        nonisolated(unsafe) var expectation: XCTestExpectation? = self.expectation(description: "Board returns insufficient material draw result")

        let delegate = MockBoardDelegate(didEnd: { result in
            if case .draw(let drawType) = result {
                if drawType == .insufficientMaterial {
                    expectation?.fulfill()
                    expectation = nil
                }
            } else {
                XCTFail()
            }
        })
        board.delegate = delegate

        let move = board.move(pieceAt: .h7, to: .h8)!
        board.completePromotion(of: move, to: .bishop)
        waitForExpectations(timeout: 1.0)
    }

    func testInsufficientMaterialScenarios() {
        // different promotions
        let fen = "k7/7P/8/8/8/8/8/K7 w - - 0 1"
        
        let validPieces: [Piece.Kind] = [.rook, .queen]
        let invalidPieces: [Piece.Kind] = [.bishop, .knight]
        
        for p in validPieces {
            var board = Board(position: .init(fen: fen)!)
            let move = board.move(pieceAt: .h7, to: .h8)!
            
            board.completePromotion(of: move , to: p)
            XCTAssertFalse(board.position.hasInsufficientMaterial)
        }
        
        for p in invalidPieces {
            var board = Board(position: .init(fen: fen)!)
            let move = board.move(pieceAt: .h7, to: .h8)!
            
            board.completePromotion(of: move , to: p)
            XCTAssertTrue(board.position.hasInsufficientMaterial)
        }
        
        // opposite color bishops VS same color bishops
        let fen2 = "k5B1/b7/1b6/8/8/8/8/K7 w - - 0 1"
        let fen3 = "k5B1/1b6/2b5/8/8/8/8/K7 w - - 0 1"

        let board2 = Board(position: .init(fen: fen2)!)
        let board3 = Board(position: .init(fen: fen3)!)

        XCTAssertFalse(board2.position.hasInsufficientMaterial)
        XCTAssertTrue(board3.position.hasInsufficientMaterial)

        // before and after king takes Queen
        let fen4 = "k7/1Q6/8/8/8/8/8/K7 w - - 0 1"
        var board4 = Board(position: .init(fen: fen4)!)

        XCTAssertFalse(board4.position.hasInsufficientMaterial)
        board4.move(pieceAt: .a8, to: .b7)
        XCTAssertTrue(board4.position.hasInsufficientMaterial)
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
        let position = Position(fen: "N6N/8/4N3/8/2N5/5N2/3N4/N6N w - - 0 1")!
        let board = Board(position: position)

        XCTAssertTrue(board.canMove(pieceAt: .a8, to: .b6))
        XCTAssertTrue(board.canMove(pieceAt: .a8, to: .c7))

        XCTAssertTrue(board.canMove(pieceAt: .h8, to: .f7))
        XCTAssertTrue(board.canMove(pieceAt: .h8, to: .g6))

        XCTAssertTrue(board.canMove(pieceAt: .a1, to: .b3))
        XCTAssertTrue(board.canMove(pieceAt: .a1, to: .c2))

        XCTAssertTrue(board.canMove(pieceAt: .h1, to: .f2))
        XCTAssertTrue(board.canMove(pieceAt: .h1, to: .g3))

        XCTAssertTrue(board.canMove(pieceAt: .c4, to: .a3))
        XCTAssertTrue(board.canMove(pieceAt: .c4, to: .a5))
        XCTAssertTrue(board.canMove(pieceAt: .c4, to: .b2))
        XCTAssertTrue(board.canMove(pieceAt: .c4, to: .b6))
        XCTAssertFalse(board.canMove(pieceAt: .c4, to: .d2))
        XCTAssertTrue(board.canMove(pieceAt: .c4, to: .d6))
        XCTAssertTrue(board.canMove(pieceAt: .c4, to: .e3))
        XCTAssertTrue(board.canMove(pieceAt: .c4, to: .e5))

        XCTAssertTrue(board.canMove(pieceAt: .d2, to: .b1))
        XCTAssertTrue(board.canMove(pieceAt: .d2, to: .b3))
        XCTAssertFalse(board.canMove(pieceAt: .d2, to: .c4))
        XCTAssertTrue(board.canMove(pieceAt: .d2, to: .e4))
        XCTAssertFalse(board.canMove(pieceAt: .d2, to: .f3))
        XCTAssertTrue(board.canMove(pieceAt: .d2, to: .f1))
    }

    func testLegalBishopMoves() {
        let position = Position(fen: "5bBb/8/8/pPpPpPpP/8/8/8/BbB5 w - - 0 1")!
        let board = Board(position: position)

        XCTAssertTrue(board.canMove(pieceAt: .a1, to: .d4))
        XCTAssertTrue(board.canMove(pieceAt: .a1, to: .e5))
        XCTAssertFalse(board.canMove(pieceAt: .a1, to: .f6))

        XCTAssertTrue(board.canMove(pieceAt: .b1, to: .e4))
        XCTAssertTrue(board.canMove(pieceAt: .b1, to: .f5))
        XCTAssertFalse(board.canMove(pieceAt: .b1, to: .g6))

        XCTAssertTrue(board.canMove(pieceAt: .c1, to: .f4))
        XCTAssertTrue(board.canMove(pieceAt: .c1, to: .g5))
        XCTAssertFalse(board.canMove(pieceAt: .c1, to: .h8))

        XCTAssertTrue(board.canMove(pieceAt: .f8, to: .d6))
        XCTAssertFalse(board.canMove(pieceAt: .f8, to: .c5))
        XCTAssertFalse(board.canMove(pieceAt: .f8, to: .b4))

        XCTAssertTrue(board.canMove(pieceAt: .g8, to: .e6))
        XCTAssertFalse(board.canMove(pieceAt: .g8, to: .d5))
        XCTAssertFalse(board.canMove(pieceAt: .g8, to: .c4))

        XCTAssertTrue(board.canMove(pieceAt: .h8, to: .f6))
        XCTAssertFalse(board.canMove(pieceAt: .h8, to: .e5))
        XCTAssertFalse(board.canMove(pieceAt: .h8, to: .d4))
    }

    func testLegalRookMoves() {
        let position = Position(fen: "r7/1r6/2r1p3/P7/p7/2R1P3/1R6/R7 w - - 0 1")!
        let board = Board(position: position)

        XCTAssertTrue(board.canMove(pieceAt: .a1, to: .a4))
        XCTAssertFalse(board.canMove(pieceAt: .a1, to: .a5))
        XCTAssertTrue(board.canMove(pieceAt: .a1, to: .h1))

        XCTAssertTrue(board.canMove(pieceAt: .b2, to: .b7))
        XCTAssertFalse(board.canMove(pieceAt: .b2, to: .b8))
        XCTAssertTrue(board.canMove(pieceAt: .b2, to: .h2))
        XCTAssertTrue(board.canMove(pieceAt: .b2, to: .b1))
        XCTAssertTrue(board.canMove(pieceAt: .b2, to: .a2))
    }

    func testLegalQueenMoves() {

    }

    func testLegalKingMoves() {
        let position = Position(fen: "8/8/8/4p3/4K3/8/8/8 w - - 0 1")!
        let board = Board(position: position)

        XCTAssertTrue(board.canMove(pieceAt: .e4, to: .d5))
        XCTAssertTrue(board.canMove(pieceAt: .e4, to: .d3))
        XCTAssertTrue(board.canMove(pieceAt: .e4, to: .f5))
        XCTAssertTrue(board.canMove(pieceAt: .e4, to: .f3))
        XCTAssertTrue(board.canMove(pieceAt: .e4, to: .e5))
        XCTAssertTrue(board.canMove(pieceAt: .e4, to: .e3))
        XCTAssertFalse(board.canMove(pieceAt: .e4, to: .d4))
        XCTAssertFalse(board.canMove(pieceAt: .e4, to: .f4))
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

        position.move(pieceAt: .e2, to: .e4)
        XCTAssertEqual(position.sideToMove, .black)
    }

    func testDisambiguation() {
        var board = Board(position: Position(fen: "3r3r/8/4B3/R2n4/2B1Q2Q/8/8/R6Q w - - 0 1")!)

        let r1a3 = board.move(pieceAt: .a1, to: .a3)
        let rdf8 = board.move(pieceAt: .d8, to: .f8)
        let qh4e1 = board.move(pieceAt: .h4, to: .e1)

        XCTAssertEqual(r1a3?.san, "R1a3")
        XCTAssertEqual(rdf8?.san, "Rdf8")
        XCTAssertEqual(qh4e1?.san, "Qh4e1")

        let bf7 = board.move(pieceAt: .e6, to: .f7)
        XCTAssertEqual(bf7?.san, "Bf7")

        let bfxd5 = board.move(pieceAt: .f7, to: .d5)
        XCTAssertEqual(bfxd5?.san, "Bfxd5")
    }

    func testPrint() {
        let board = Board()

        ChessKitConfiguration.printOptions.mode = .letter
        XCTAssertEqual(String(describing: board),
        """
        8 r n b q k b n r
        7 p p p p p p p p
        6 · · · · · · · ·
        5 · · · · · · · ·
        4 · · · · · · · ·
        3 · · · · · · · ·
        2 P P P P P P P P
        1 R N B Q K B N R
          a b c d e f g h
        """)

        ChessKitConfiguration.printOptions.mode = .graphic
        XCTAssertEqual(String(describing: board),
        """
        8 ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜
        7 ♟\u{FE0E} ♟\u{FE0E} ♟\u{FE0E} ♟\u{FE0E} ♟\u{FE0E} ♟\u{FE0E} ♟\u{FE0E} ♟\u{FE0E}
        6 · · · · · · · ·
        5 · · · · · · · ·
        4 · · · · · · · ·
        3 · · · · · · · ·
        2 ♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙
        1 ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖
          a b c d e f g h
        """)

        let bb = board.position.pieceSet.all
        XCTAssertEqual(bb.chessString(),
        """
        8 ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯
        7 ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯
        6 · · · · · · · ·
        5 · · · · · · · ·
        4 · · · · · · · ·
        3 · · · · · · · ·
        2 ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯
        1 ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯
          a b c d e f g h
        """)

        XCTAssertEqual(bb.chessString(labelRanks: false, labelFiles: false),
        """
        ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯
        ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯
        · · · · · · · ·
        · · · · · · · ·
        · · · · · · · ·
        · · · · · · · ·
        ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯
        ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯ ⨯
        """)
    }

}
