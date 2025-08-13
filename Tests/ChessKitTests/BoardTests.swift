//
//  BoardTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct BoardTests {

  @Test func updatePosition() {
    var board = Board()
    #expect(board.position == .standard)
    #expect(board.state == .active)

    board.update(position: .complex)
    #expect(board.position == .complex)
    #expect(board.state == .active)

    board.update(position: .test)
    board.update(position: .test)
    board.update(position: .test)
    #expect(board.position == .test)
    #expect(board.state == .draw(reason: .repetition))

    board.update(position: .test, resetPositionCounts: true)
    #expect(board.state == .active)
  }

  @Test func enPassant() {
    var board = Board(position: .ep)
    let ep = board.position.enPassant!

    let capturingPiece = board.position.piece(at: .f4)!
    #expect(ep.couldBeCaptured(by: capturingPiece))

    let move = board.move(pieceAt: .f4, to: ep.captureSquare)!
    #expect(move.result == .capture(ep.pawn))
  }

  @Test func illegalEnPassant() {
    // fen position contains illegal en passant move
    let board = Board(position: .init(fen: "1nbqkbnr/1pp1pppp/8/r1Pp3K/p7/5P2/PP1PP1PP/RNBQ1BNR w k d6 0 8")!)
    #expect(!board.canMove(pieceAt: .c5, to: .d6))
  }

  @Test func doubleEnPassant() {
    var board = Board(position: .init(fen: "kr6/2p5/8/1P1P4/8/1K6/8/8 b - - 0 1")!)
    board.move(pieceAt: .c7, to: .c5)
    // after this move only 1 out of 2 pawns can execute enPassant
    #expect(!board.canMove(pieceAt: .b5, to: .c6))
    #expect(board.canMove(pieceAt: .d5, to: .c6))
    #expect(board.position.enPassantIsPossible)
  }

  @Test(arguments: Piece.Color.allCases)
  func promotion(color: Piece.Color) {
    let pawnStart = color == .white ? Square.e7 : .e2
    let pawnEnd = color == .white ? Square.e8 : .e1

    let king = Piece(.pawn, color: color.opposite, square: .a7)
    let pawn = Piece(.pawn, color: color, square: pawnStart)
    let queen = Piece(.queen, color: color, square: pawnEnd)
    var board = Board(position: .init(pieces: [pawn, king], sideToMove: color))

    let attemptedMove = board.move(pieceAt: pawnStart, to: pawnEnd)

    if case let .promotion(move: move) = board.state {
      let promotionMove = board.completePromotion(of: move, to: .queen)
      #expect(promotionMove.result == .move)
      #expect(promotionMove.promotedPiece == queen)
      #expect(promotionMove.end == pawnEnd)
      #expect(board.state == .active)
    } else {
      Issue.record("Failed to trigger promotion for \(attemptedMove!)")
    }
  }

  @Test(arguments: Piece.Color.allCases)
  func initializeWithPromotion(color: Piece.Color) {
    let pawnSquare = color == .white ? Square.e8 : .e1

    let king = Piece(.pawn, color: color.opposite, square: .a7)
    let pawn = Piece(.pawn, color: color, square: pawnSquare)
    let queen = Piece(.queen, color: color, square: pawnSquare)
    var board = Board(position: .init(pieces: [pawn, king], sideToMove: color))

    if case let .promotion(move: move) = board.state {
      let promotionMove = board.completePromotion(of: move, to: .queen)
      #expect(promotionMove.result == .move)
      #expect(promotionMove.promotedPiece == queen)
      #expect(promotionMove.end == pawnSquare)
      #expect(board.state == .active)
    } else {
      Issue.record("Failed to identify promotion on \(pawnSquare)")
    }
  }

  @Test func fiftyMoveRule() {
    var board = Board(position: .fiftyMove)
    board.move(pieceAt: .f7, to: .f8)
    #expect(board.state == .draw(reason: .fiftyMoves))
  }

  @Test func insufficientMaterial() {
    var board = Board(position: .init(fen: "k7/b6P/8/8/8/8/8/K7 w - - 0 1")!)
    let attemptedMove = board.move(pieceAt: .h7, to: .h8)
    if case let .promotion(move: move) = board.state {
      board.completePromotion(of: move, to: .bishop)
      #expect(board.state == .draw(reason: .insufficientMaterial))
    } else {
      Issue.record("Failed to trigger promotion for \(attemptedMove!)")
    }
  }

  @Test func insufficientMaterialScenarios() {
    // different promotions
    let fen = "k7/7P/8/8/8/8/8/K7 w - - 0 1"

    let validPieces: [Piece.Kind] = [.rook, .queen]
    let invalidPieces: [Piece.Kind] = [.bishop, .knight]

    for p in validPieces {
      var board = Board(position: .init(fen: fen)!)
      let move = board.move(pieceAt: .h7, to: .h8)!

      board.completePromotion(of: move, to: p)
      #expect(!board.position.hasInsufficientMaterial)
      #expect(board.state == .check(color: .black))
    }

    for p in invalidPieces {
      var board = Board(position: .init(fen: fen)!)
      let move = board.move(pieceAt: .h7, to: .h8)!

      board.completePromotion(of: move, to: p)
      #expect(board.position.hasInsufficientMaterial)
      #expect(board.state == .draw(reason: .insufficientMaterial))
    }

    // opposite color bishops vs same color bishops
    let fen2 = "k5B1/b7/1b6/8/8/8/8/K7 w - - 0 1"
    let fen3 = "k5B1/1b6/2b5/8/8/8/8/K7 w - - 0 1"

    let board2 = Board(position: .init(fen: fen2)!)
    let board3 = Board(position: .init(fen: fen3)!)

    #expect(!board2.position.hasInsufficientMaterial)
    #expect(board2.state == .active)
    #expect(board3.position.hasInsufficientMaterial)
    #expect(board3.state == .draw(reason: .insufficientMaterial))

    // before and after king takes Queen
    let fen4 = "k7/1Q6/8/8/8/8/8/K7 w - - 0 1"
    var board4 = Board(position: .init(fen: fen4)!)

    #expect(!board4.position.hasInsufficientMaterial)
    #expect(board4.state == .check(color: .black))
    board4.move(pieceAt: .a8, to: .b7)
    #expect(board4.position.hasInsufficientMaterial)
    #expect(board4.state == .draw(reason: .insufficientMaterial))
  }

  @Test func threefoldRepetition() {
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
    board.move(pieceAt: .f6, to: .g8)  // 3rd time position occurs

    #expect(board.state == .draw(reason: .repetition))
  }

  @Test func legalMovesForNonexistentPiece() {
    let board = Board(position: .standard)
    // no piece at d4
    let legalMoves = board.legalMoves(forPieceAt: .d4)
    #expect(legalMoves.isEmpty)
  }

  @Test func legalPawnMoves() {
    let board = Board(position: .standard)
    let legalC2PawnMoves = board.legalMoves(forPieceAt: .c2)
    #expect(legalC2PawnMoves.count == 2)
    #expect(legalC2PawnMoves.contains(.c3))
    #expect(legalC2PawnMoves.contains(.c4))
    #expect(board.canMove(pieceAt: .c2, to: .c3))
    #expect(board.canMove(pieceAt: .c2, to: .c4))
    #expect(!board.canMove(pieceAt: .c2, to: .c5))

    let legalF7PawnMoves = board.legalMoves(forPieceAt: .f7)
    #expect(legalF7PawnMoves.count == 2)
    #expect(legalF7PawnMoves.contains(.f6))
    #expect(legalF7PawnMoves.contains(.f5))
    #expect(board.canMove(pieceAt: .f7, to: .f6))
    #expect(board.canMove(pieceAt: .f7, to: .f5))
    #expect(!board.canMove(pieceAt: .f7, to: .f4))

    // test pawns on starting rank can't hop over pieces
    let position = Position(fen: "rnbqkbnr/p1p1p1pp/1pPp4/8/8/4PpP1/PP1P1P1P/RNBQKBNR w KQkq - 0 1")!
    let b2 = Board(position: position)
    let legalF2PawnMoves = b2.legalMoves(forPieceAt: .f2)
    #expect(legalF2PawnMoves.isEmpty)

    let legalC7PawnMoves = b2.legalMoves(forPieceAt: .c7)
    #expect(legalC7PawnMoves.isEmpty)
  }

  @Test func legalKnightMoves() {
    let position = Position(fen: "N6N/8/4N3/8/2N5/5N2/3N4/N6N w - - 0 1")!
    let board = Board(position: position)

    #expect(board.canMove(pieceAt: .a8, to: .b6))
    #expect(board.canMove(pieceAt: .a8, to: .c7))

    #expect(board.canMove(pieceAt: .h8, to: .f7))
    #expect(board.canMove(pieceAt: .h8, to: .g6))

    #expect(board.canMove(pieceAt: .a1, to: .b3))
    #expect(board.canMove(pieceAt: .a1, to: .c2))

    #expect(board.canMove(pieceAt: .h1, to: .f2))
    #expect(board.canMove(pieceAt: .h1, to: .g3))

    #expect(board.canMove(pieceAt: .c4, to: .a3))
    #expect(board.canMove(pieceAt: .c4, to: .a5))
    #expect(board.canMove(pieceAt: .c4, to: .b2))
    #expect(board.canMove(pieceAt: .c4, to: .b6))
    #expect(!board.canMove(pieceAt: .c4, to: .d2))
    #expect(board.canMove(pieceAt: .c4, to: .d6))
    #expect(board.canMove(pieceAt: .c4, to: .e3))
    #expect(board.canMove(pieceAt: .c4, to: .e5))

    #expect(board.canMove(pieceAt: .d2, to: .b1))
    #expect(board.canMove(pieceAt: .d2, to: .b3))
    #expect(!board.canMove(pieceAt: .d2, to: .c4))
    #expect(board.canMove(pieceAt: .d2, to: .e4))
    #expect(!board.canMove(pieceAt: .d2, to: .f3))
    #expect(board.canMove(pieceAt: .d2, to: .f1))
  }

  @Test func legalBishopMoves() {
    let position = Position(fen: "5bBb/8/8/pPpPpPpP/8/8/8/BbB5 w - - 0 1")!
    let board = Board(position: position)

    #expect(board.canMove(pieceAt: .a1, to: .d4))
    #expect(board.canMove(pieceAt: .a1, to: .e5))
    #expect(!board.canMove(pieceAt: .a1, to: .f6))

    #expect(board.canMove(pieceAt: .b1, to: .e4))
    #expect(board.canMove(pieceAt: .b1, to: .f5))
    #expect(!board.canMove(pieceAt: .b1, to: .g6))

    #expect(board.canMove(pieceAt: .c1, to: .f4))
    #expect(board.canMove(pieceAt: .c1, to: .g5))
    #expect(!board.canMove(pieceAt: .c1, to: .h8))

    #expect(board.canMove(pieceAt: .f8, to: .d6))
    #expect(!board.canMove(pieceAt: .f8, to: .c5))
    #expect(!board.canMove(pieceAt: .f8, to: .b4))

    #expect(board.canMove(pieceAt: .g8, to: .e6))
    #expect(!board.canMove(pieceAt: .g8, to: .d5))
    #expect(!board.canMove(pieceAt: .g8, to: .c4))

    #expect(board.canMove(pieceAt: .h8, to: .f6))
    #expect(!board.canMove(pieceAt: .h8, to: .e5))
    #expect(!board.canMove(pieceAt: .h8, to: .d4))
  }

  @Test func legalRookMoves() {
    let position = Position(fen: "r7/1r6/2r1p3/P7/p7/2R1P3/1R6/R7 w - - 0 1")!
    let board = Board(position: position)

    [.a4, .h1].forEach {
      #expect(board.canMove(pieceAt: .a1, to: $0))
    }

    #expect(!board.canMove(pieceAt: .a1, to: .a5))

    [.a2, .b1, .b7, .h2].forEach {
      #expect(board.canMove(pieceAt: .b2, to: $0))
    }

    #expect(!board.canMove(pieceAt: .b2, to: .b8))
  }

  @Test func legalQueenMoves() {
    let position = Position(fen: "7k/8/2pP4/3qq3/3QQ3/4pP2/8/K7 w - - 0 1")!
    let board = Board(position: position)

    [.b2, .c3, .e5].forEach { #expect(board.canMove(pieceAt: .d4, to: $0)) }
    [.e3, .c4, .b4].forEach { #expect(!board.canMove(pieceAt: .d4, to: $0)) }

    [.d4, .f6, .g7].forEach { #expect(board.canMove(pieceAt: .e5, to: $0)) }
    [.d6, .e6, .g6].forEach { #expect(!board.canMove(pieceAt: .e5, to: $0)) }

    [.d4, .e4, .a2].forEach { #expect(board.canMove(pieceAt: .d5, to: $0)) }
    [.c6, .e5, .d7].forEach { #expect(!board.canMove(pieceAt: .d5, to: $0)) }

    [.d5, .e5, .h7].forEach { #expect(board.canMove(pieceAt: .e4, to: $0)) }
    [.e2, .d4, .f3].forEach { #expect(!board.canMove(pieceAt: .e4, to: $0)) }
  }

  @Test func legalKingMoves() {
    let position = Position(fen: "8/8/8/4p3/4K3/8/8/8 w - - 0 1")!
    let board = Board(position: position)

    [.d3, .d5, .f3, .f5, .e3, .e5].forEach {
      #expect(board.canMove(pieceAt: .e4, to: $0))
    }

    [.d4, .f4].forEach {
      #expect(!board.canMove(pieceAt: .e4, to: $0))
    }
  }

  @Test func captureMove() {
    var board = Board(position: .init(fen: "8/8/8/4p3/3P4/8/8/8 w - - 0 1")!)
    let move = board.move(pieceAt: .d4, to: .e5)

    let capturedPiece = Piece(.pawn, color: .black, square: .e5)
    #expect(move?.result == .capture(capturedPiece))
  }

  @Test func illegalMove() {
    var board = Board(position: .standard)
    let move = board.move(pieceAt: .d2, to: .d5)
    #expect(move == nil)
  }

  @Test func checkMove() {
    var board = Board(position: .init(fen: "k7/7R/8/8/8/8/K7/8 w - - 0 1")!)
    let move = board.move(pieceAt: .h7, to: .h8)
    #expect(move?.checkState == .check)
    #expect(board.state == .check(color: .black))
  }

  @Test func checkmateMove() {
    var board = Board(position: .init(fen: "k7/7R/6R1/8/8/8/K7/8 w - - 0 1")!)
    let move = board.move(pieceAt: .g6, to: .g8)
    #expect(move?.checkState == .checkmate)
    #expect(board.state == .checkmate(color: .black))
  }

  @Test func sideToMove() {
    var position = Position.standard
    #expect(position.sideToMove == .white)

    position.move(pieceAt: .e2, to: .e4)
    #expect(position.sideToMove == .black)
  }

  @Test func disambiguation() {
    var board = Board(position: Position(fen: "3r3r/8/4B3/R2n4/2B1Q2Q/8/8/R6Q w - - 0 1")!)

    let r1a3 = board.move(pieceAt: .a1, to: .a3)
    let rdf8 = board.move(pieceAt: .d8, to: .f8)
    let qh4e1 = board.move(pieceAt: .h4, to: .e1)

    #expect(r1a3?.san == "R1a3")
    #expect(rdf8?.san == "Rdf8")
    #expect(qh4e1?.san == "Qh4e1")

    let bf7 = board.move(pieceAt: .e6, to: .f7)
    #expect(bf7?.san == "Bf7")

    let bfxd5 = board.move(pieceAt: .f7, to: .d5)
    #expect(bfxd5?.san == "Bfxd5")
  }

  @Test func print() {
    let board = Board()

    ChessKitConfiguration.printOptions.mode = .letter
    #expect(
      String(describing: board) == """
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
    #expect(
      String(describing: board) == """
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
    #expect(
      bb.chessString() == """
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

    #expect(
      bb.chessString(labelRanks: false, labelFiles: false) == """
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
  @Test func printDeprecated() {
    let board = Board()

    ChessKitConfiguration.printMode = .letter
    #expect(ChessKitConfiguration.printMode == .letter)
    #expect(
      String(describing: board) == """
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
    #expect(ChessKitConfiguration.printMode == .graphic)
    #expect(
      String(describing: board) == """
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

  @available(*, deprecated)
  @Test(arguments: Piece.Color.allCases)
  func legacyPromotion(color: Piece.Color) async throws {
    let pawnStart = color == .white ? Square.e7 : .e2
    let pawnEnd = color == .white ? Square.e8 : .e1

    let pawn = Piece(.pawn, color: color, square: pawnStart)
    let queen = Piece(.queen, color: color, square: pawnEnd)
    var board = Board(position: .init(pieces: [pawn]))

    try await confirmation("\(pawn) promotes to \(queen)", expectedCount: 2) { confirm in
      nonisolated(unsafe) var willPromoteDidRun = false

      let delegate = MockBoardDelegate(
        willPromote: { move in
          let pawn = Piece(.pawn, color: color, square: pawnEnd)
          #expect(move.piece == pawn)
          #expect(move.promotedPiece == nil)
          willPromoteDidRun = true
          confirm()
        },
        didPromote: { move in
          if !willPromoteDidRun {
            Issue.record("BoardDelegate.willPromote() did not run.")
          }

          #expect(move.promotedPiece == queen)
          confirm()
        }
      )
      board.delegate = delegate

      let attemptedMove = board.move(pieceAt: pawnStart, to: pawnEnd)
      let move = try #require(attemptedMove)
      let promotionMove = board.completePromotion(of: move, to: .queen)

      #expect(promotionMove.result == .move)
      #expect(promotionMove.promotedPiece == queen)
      #expect(promotionMove.end == pawnEnd)
    }
  }

  @available(*, deprecated)
  @Test func legacyFiftyMoveRule() async {
    var board = Board(position: .fiftyMove)

    await confirmation("Board returns fifty move draw result") { confirm in
      let delegate = MockBoardDelegate(didEnd: { result in
        if case let .draw(drawType) = result {
          if drawType == .fiftyMoves {
            confirm()
          }
        }
      })

      board.delegate = delegate
      board.move(pieceAt: .f7, to: .f8)
    }
  }

  @available(*, deprecated)
  @Test func legacyInsufficientMaterial() async throws {
    var board = Board(position: .init(fen: "k7/b6P/8/8/8/8/8/K7 w - - 0 1")!)

    try await confirmation("Board returns insufficient material draw result") { confirm in
      let delegate = MockBoardDelegate(didEnd: { result in
        if case let .draw(drawType) = result {
          if drawType == .insufficientMaterial {
            confirm()
          }
        }
      })
      board.delegate = delegate

      let attemptedMove = board.move(pieceAt: .h7, to: .h8)
      let move = try #require(attemptedMove)
      board.completePromotion(of: move, to: .bishop)
    }
  }

  @available(*, deprecated)
  @Test func legacyInsufficientMaterialScenarios() {
    // different promotions
    let fen = "k7/7P/8/8/8/8/8/K7 w - - 0 1"

    let validPieces: [Piece.Kind] = [.rook, .queen]
    let invalidPieces: [Piece.Kind] = [.bishop, .knight]

    for p in validPieces {
      var board = Board(position: .init(fen: fen)!)
      let move = board.move(pieceAt: .h7, to: .h8)!

      board.completePromotion(of: move, to: p)
      #expect(!board.position.hasInsufficientMaterial)
    }

    for p in invalidPieces {
      var board = Board(position: .init(fen: fen)!)
      let move = board.move(pieceAt: .h7, to: .h8)!

      board.completePromotion(of: move, to: p)
      #expect(board.position.hasInsufficientMaterial)
    }

    // opposite color bishops vs same color bishops
    let fen2 = "k5B1/b7/1b6/8/8/8/8/K7 w - - 0 1"
    let fen3 = "k5B1/1b6/2b5/8/8/8/8/K7 w - - 0 1"

    let board2 = Board(position: .init(fen: fen2)!)
    let board3 = Board(position: .init(fen: fen3)!)

    #expect(!board2.position.hasInsufficientMaterial)
    #expect(board3.position.hasInsufficientMaterial)

    // before and after king takes Queen
    let fen4 = "k7/1Q6/8/8/8/8/8/K7 w - - 0 1"
    var board4 = Board(position: .init(fen: fen4)!)

    #expect(!board4.position.hasInsufficientMaterial)
    board4.move(pieceAt: .a8, to: .b7)
    #expect(board4.position.hasInsufficientMaterial)
  }

  @available(*, deprecated)
  @Test func legacyThreefoldRepetition() async {
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

    await confirmation("Board returns draw by repetition result") { confirm in
      let delegate = MockBoardDelegate(didEnd: { result in
        if case let .draw(drawType) = result {
          if drawType == .repetition {
            confirm()
          }
        }
      })

      board.delegate = delegate
      board.move(pieceAt: .f6, to: .g8)  // 3rd time position occurs
    }
  }

  @available(*, deprecated)
  @Test func legacyCheckMove() async {
    var board = Board(position: .init(fen: "k7/7R/8/8/8/8/K7/8 w - - 0 1")!)

    await confirmation("Board returns check result") { confirm in
      let delegate = MockBoardDelegate(didCheckKing: { color in
        if color == .black {
          confirm()
        }
      })

      board.delegate = delegate
      let move = board.move(pieceAt: .h7, to: .h8)
      #expect(move?.checkState == .check)
    }
  }

  @available(*, deprecated)
  @Test func legacyCheckmateMove() async {
    var board = Board(position: .init(fen: "k7/7R/6R1/8/8/8/K7/8 w - - 0 1")!)

    await confirmation("Board returns checkmate result") { confirm in
      let delegate = MockBoardDelegate(didEnd: { result in
        if case .win(.white) = result {
          confirm()
        }
      })

      board.delegate = delegate
      let move = board.move(pieceAt: .g6, to: .g8)
      #expect(move?.checkState == .checkmate)
    }
  }

}
