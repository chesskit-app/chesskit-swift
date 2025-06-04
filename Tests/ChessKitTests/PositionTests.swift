//
//  PositionTests.swift
//  ChessKit
//

@testable import ChessKit
import Testing

struct PositionTests {

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

  @available(*, deprecated)
  @Test func legacyPositionInitializer() {
    let whitePawn = Piece(.pawn, color: .white, square: .e5)
    let blackPawn = Piece(.pawn, color: .black, square: .d5)

    let legacyPosition1 = Position(
      pieces: [whitePawn, blackPawn],
      sideToMove: .white,
      legalCastlings: .init(),
      enPassant: .init(pawn: blackPawn),
      enPassantIsPossible: true,
      clock: .init()
    )

    let position1 = Position(
      pieces: [whitePawn, blackPawn],
      sideToMove: .white,
      legalCastlings: .init(),
      enPassant: .init(pawn: blackPawn),
      clock: .init()
    )

    #expect(legacyPosition1 == position1)

    let legacyPosition2 = Position(
      pieces: [whitePawn, blackPawn],
      sideToMove: .white,
      legalCastlings: .init(),
      enPassant: nil,
      enPassantIsPossible: false,
      clock: .init()
    )

    let position2 = Position(
      pieces: [whitePawn, blackPawn],
      sideToMove: .white,
      legalCastlings: .init(),
      clock: .init()
    )

    #expect(legacyPosition2 == position2)
  }

}
