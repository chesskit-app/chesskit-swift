//
//  PositionTests.swift
//  ChessKit
//

@testable import ChessKit
import Testing

struct PositionTests {

  @Test func initializer() {
    let whitePawn = Piece(.pawn, color: .white, square: .e5)
    let blackPawn = Piece(.pawn, color: .black, square: .d5)

    let position1 = Position(
      pieces: [whitePawn, blackPawn],
      sideToMove: .white,
      legalCastlings: .init(),
      enPassant: .init(pawn: blackPawn),
      clock: .init()
    )

    #expect(position1.enPassantIsPossible)

    let position2 = Position(
      pieces: [whitePawn, blackPawn],
      sideToMove: .white,
      legalCastlings: .init(),
      clock: .init()
    )

    #expect(!position2.enPassantIsPossible)
  }

  @Test func sideToMove() {
    var position = Position.standard
    #expect(position.sideToMove == .white)

    position.move(pieceAt: .e2, to: .e4)
    #expect(position.sideToMove == .black)

    position.move(pieceAt: .e7, to: .e5)
    #expect(position.sideToMove == .white)
  }

  @Test func moveNonexistentPieces() {
    var position = Position.standard

    #expect(position.move(pieceAt: .a3, to: .a4) == nil)
    #expect(position.move(.init(.pawn, color: .white, square: .a3), to: .a4) == nil)
  }

}

// MARK: - Deprecated Tests
extension PositionTests {

  @available(*, deprecated)
  @Test func positionToggleSideToMove() {
    var position = Position.standard
    let initialSideToMove = position.sideToMove
    position.toggleSideToMove()
    #expect(initialSideToMove == position.sideToMove)
  }

}
