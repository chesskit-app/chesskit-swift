//
//  BoardTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

final class BoardTests: XCTestCase {

  func testEnPassant() {
    var board = Board(position: .ep)
    let ep = board.position.enPassant!

    let capturingPiece = board.position.piece(at: .f4)!
    XCTAssertTrue(ep.couldBeCaptured(by: capturingPiece))

    let move = board.move(pieceAt: .f4, to: ep.captureSquare)!
    XCTAssertEqual(move.result, .capture(ep.pawn))
  }

  func testIllegalEnPassant() {
    // fen position contains illegal en passant move
    let board = Board(position: .init(fen: "1nbqkbnr/1pp1pppp/8/r1Pp3K/p7/5P2/PP1PP1PP/RNBQ1BNR w k d6 0 8")!)
    XCTAssertFalse(board.canMove(pieceAt: .c5, to: .d6))
  }

  func testDoubleEnPassant() {
    var board = Board(position: .init(fen: "kr6/2p5/8/1P1P4/8/1K6/8/8 b - - 0 1")!)
    board.move(pieceAt: .c7, to: .c5)
    // after this move only 1 out of 2 pawns can execute enPassant
    XCTAssertFalse(board.canMove(pieceAt: .b5, to: .c6))
    XCTAssertTrue(board.canMove(pieceAt: .d5, to: .c6))
    XCTAssertTrue(board.position.enPassantIsPossible)
  }

  @MainActor func testWhitePromotion() {
    let pawn = Piece(.pawn, color: .white, square: .e7)
    let queen = Piece(.queen, color: .white, square: .e8)
    var board = Board(position: .init(pieces: [pawn]))

    let willPromoteExpectation = self.expectation(
      description: "Board will promote"
    )
    let didPromoteExpecatation = self.expectation(
      description: "Board did promote"
    )

    let delegate = MockBoardDelegate(
      willPromote: { [weak willPromoteExpectation] move in
        let pawn = Piece(.pawn, color: .white, square: .e8)
        XCTAssertEqual(move.piece, pawn)
        XCTAssertNil(move.promotedPiece)
        willPromoteExpectation?.fulfill()
      },
      didPromote: { [weak didPromoteExpecatation] move in
        XCTAssertEqual(move.promotedPiece, queen)
        didPromoteExpecatation?.fulfill()
      }
    )
    board.delegate = delegate

    let move = board.move(pieceAt: .e7, to: .e8)!
    wait(for: [willPromoteExpectation], timeout: 1.0)

    let promotionMove = board.completePromotion(of: move, to: .queen)
    wait(for: [didPromoteExpecatation], timeout: 1.0)

    XCTAssertEqual(promotionMove.result, .move)
    XCTAssertEqual(promotionMove.promotedPiece, queen)
    XCTAssertEqual(promotionMove.end, .e8)
  }

  @MainActor func testBlackPromotion() {
    let pawn = Piece(.pawn, color: .black, square: .e2)
    let queen = Piece(.queen, color: .black, square: .e1)
    var board = Board(position: .init(pieces: [pawn]))

    let willPromoteExpectation = self.expectation(
      description: "Board will promote"
    )
    let didPromoteExpecatation = self.expectation(
      description: "Board did promote"
    )

    let delegate = MockBoardDelegate(
      willPromote: { [weak willPromoteExpectation] move in
        let pawn = Piece(.pawn, color: .black, square: .e1)
        XCTAssertEqual(move.piece, pawn)
        XCTAssertNil(move.promotedPiece)
        willPromoteExpectation?.fulfill()
      },
      didPromote: { [weak didPromoteExpecatation] move in
        XCTAssertEqual(move.promotedPiece, queen)
        didPromoteExpecatation?.fulfill()
      }
    )
    board.delegate = delegate

    let move = board.move(pieceAt: .e2, to: .e1)!
    wait(for: [willPromoteExpectation], timeout: 1.0)

    let promotionMove = board.completePromotion(of: move, to: .queen)
    wait(for: [didPromoteExpecatation], timeout: 1.0)

    XCTAssertEqual(promotionMove.result, .move)
    XCTAssertEqual(promotionMove.promotedPiece, queen)
    XCTAssertEqual(promotionMove.end, .e1)
  }

  @MainActor func testFiftyMoveRule() {
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

  @MainActor func testInsufficientMaterial() {
    var board = Board(position: .init(fen: "k7/b6P/8/8/8/8/8/K7 w - - 0 1")!)
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

      board.completePromotion(of: move, to: p)
      XCTAssertFalse(board.position.hasInsufficientMaterial)
    }

    for p in invalidPieces {
      var board = Board(position: .init(fen: fen)!)
      let move = board.move(pieceAt: .h7, to: .h8)!

      board.completePromotion(of: move, to: p)
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

  @MainActor func testThreefoldRepetition() {
    var board = Board(position: .standard)

    board.move(pieceAt: .e2, to: .e4)
    board.move(pieceAt: .e7, to: .e5)  // 1st time position occurs

    board.move(pieceAt: .g1, to: .f3)
    board.move(pieceAt: .g8, to: .f6)

    board.move(pieceAt: .f3, to: .g1)
    board.move(pieceAt: .f6, to: .g8)  // 2nd time position occurs

    board.move(pieceAt: .g1, to: .f3)
    board.move(pieceAt: .g8, to: .f6)

    board.move(pieceAt: .f3, to: .g1)

    nonisolated(unsafe) var expectation: XCTestExpectation? = self.expectation(description: "Board returns draw by repetition result")

    let delegate = MockBoardDelegate(didEnd: { result in
      if case .draw(let drawType) = result {
        if drawType == .repetition {
          expectation?.fulfill()
          expectation = nil
        }
      } else {
        XCTFail()
      }
    })

    board.delegate = delegate
    board.move(pieceAt: .f6, to: .g8)  // 3rd time position occurs

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

    let board2 = Board(position: Position(fen: "rnbqkbnr/p1p1p1pp/1pPp4/8/8/4PpP1/PP1P1P1P/RNBQKBNR w KQkq - 0 1")!)
    let legalF2PawnMoves = board2.legalMoves(forPieceAt: .f2)   // blocked white pawn
    XCTAssertTrue(legalF2PawnMoves.isEmpty)
    XCTAssertFalse(board2.canMove(pieceAt: .f2, to: .f3))
    XCTAssertFalse(board2.canMove(pieceAt: .f2, to: .f4))

    let legalC7PawnMoves = board2.legalMoves(forPieceAt: .c7)   // blocked black pawn
    XCTAssertTrue(legalC7PawnMoves.isEmpty)
    XCTAssertFalse(board2.canMove(pieceAt: .c7, to: .c6))
    XCTAssertFalse(board2.canMove(pieceAt: .c7, to: .c5))
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

    [.a4, .h1].forEach {
      XCTAssertTrue(board.canMove(pieceAt: .a1, to: $0))
    }

    XCTAssertFalse(board.canMove(pieceAt: .a1, to: .a5))

    [.a2, .b1, .b7, .h2].forEach {
      XCTAssertTrue(board.canMove(pieceAt: .b2, to: $0))
    }

    XCTAssertFalse(board.canMove(pieceAt: .b2, to: .b8))
  }

  func testLegalQueenMoves() {
    let position = Position(fen: "7k/8/2pP4/3qq3/3QQ3/4pP2/8/K7 w - - 0 1")!
    let board = Board(position: position)

    [.b2, .c3, .e5].forEach { XCTAssertTrue(board.canMove(pieceAt: .d4, to: $0)) }
    [.e3, .c4, .b4].forEach { XCTAssertFalse(board.canMove(pieceAt: .d4, to: $0)) }

    [.d4, .f6, .g7].forEach { XCTAssertTrue(board.canMove(pieceAt: .e5, to: $0)) }
    [.d6, .e6, .g6].forEach { XCTAssertFalse(board.canMove(pieceAt: .e5, to: $0)) }

    [.d4, .e4, .a2].forEach { XCTAssertTrue(board.canMove(pieceAt: .d5, to: $0)) }
    [.c6, .e5, .d7].forEach { XCTAssertFalse(board.canMove(pieceAt: .d5, to: $0)) }

    [.d5, .e5, .h7].forEach { XCTAssertTrue(board.canMove(pieceAt: .e4, to: $0)) }
    [.e2, .d4, .f3].forEach { XCTAssertFalse(board.canMove(pieceAt: .e4, to: $0)) }
  }

  func testLegalKingMoves() {
    let position = Position(fen: "8/8/8/4p3/4K3/8/8/8 w - - 0 1")!
    let board = Board(position: position)

    [.d3, .d5, .f3, .f5, .e3, .e5].forEach {
      XCTAssertTrue(board.canMove(pieceAt: .e4, to: $0))
    }

    [.d4, .f4].forEach {
      XCTAssertFalse(board.canMove(pieceAt: .e4, to: $0))
    }
  }

  func testCaptureMove() {
    var board = Board(position: .init(fen: "8/8/8/4p3/3P4/8/8/8 w - - 0 1")!)
    let move = board.move(pieceAt: .d4, to: .e5)

    let capturedPiece = Piece(.pawn, color: .black, square: .e5)
    XCTAssertEqual(move?.result, .capture(capturedPiece))
  }

  func testIllegalMove() {
    var board = Board(position: .standard)
    let move = board.move(pieceAt: .d2, to: .d5)
    XCTAssertNil(move)
  }

  @MainActor func testCheckMove() {
    var board = Board(position: .init(fen: "k7/7R/8/8/8/8/K7/8 w - - 0 1")!)

    nonisolated(unsafe) var expectation: XCTestExpectation? = self.expectation(description: "Board returns check result")

    let delegate = MockBoardDelegate(didCheckKing: { color in
      if color == .black {
        expectation?.fulfill()
        expectation = nil
      } else {
        XCTFail()
      }
    })

    board.delegate = delegate
    let move = board.move(pieceAt: .h7, to: .h8)
    XCTAssertEqual(move?.checkState, .check)

    waitForExpectations(timeout: 1.0)
  }

  @MainActor func testCheckmateMove() {
    var board = Board(position: .init(fen: "k7/7R/6R1/8/8/8/K7/8 w - - 0 1")!)

    nonisolated(unsafe) var expectation: XCTestExpectation? = self.expectation(description: "Board returns checkmate result")

    let delegate = MockBoardDelegate(didEnd: { result in
      if case .win(.white) = result {
        expectation?.fulfill()
        expectation = nil
      } else {
        XCTFail()
      }
    })

    board.delegate = delegate
    let move = board.move(pieceAt: .g6, to: .g8)
    XCTAssertEqual(move?.checkState, .checkmate)

    waitForExpectations(timeout: 1.0)
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
    XCTAssertEqual(
      String(describing: board),
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
    XCTAssertEqual(
      String(describing: board),
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
    XCTAssertEqual(
      bb.chessString(),
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

    XCTAssertEqual(
      bb.chessString(labelRanks: false, labelFiles: false),
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

// MARK: - Deprecated Tests

extension BoardTests {

  @available(*, deprecated)
  func testPrintDeprecated() {
    let board = Board()

    ChessKitConfiguration.printMode = .letter
    XCTAssertEqual(ChessKitConfiguration.printMode, .letter)
    XCTAssertEqual(
      String(describing: board),
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

    ChessKitConfiguration.printMode = .graphic
    XCTAssertEqual(ChessKitConfiguration.printMode, .graphic)
    XCTAssertEqual(
      String(describing: board),
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
  }

}
