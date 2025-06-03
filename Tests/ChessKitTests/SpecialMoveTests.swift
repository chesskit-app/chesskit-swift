//
//  SpecialMoveTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct SpecialMoveTests {

  @Test func legalCastlingInvalidationForKings() {
    let blackKing = Piece(.king, color: .black, square: .e8)
    let whiteKing = Piece(.king, color: .white, square: .e1)

    var legalCastlings = LegalCastlings()
    legalCastlings.invalidateCastling(for: blackKing)
    #expect(!legalCastlings.contains(.bK))
    #expect(!legalCastlings.contains(.bQ))
    #expect(legalCastlings.contains(.wK))
    #expect(legalCastlings.contains(.wQ))

    legalCastlings.invalidateCastling(for: whiteKing)
    #expect(!legalCastlings.contains(.bK))
    #expect(!legalCastlings.contains(.bQ))
    #expect(!legalCastlings.contains(.wK))
    #expect(!legalCastlings.contains(.wQ))
  }

  @Test func legalCastlingInvalidationForRooks() {
    let blackKingsideRook = Piece(.rook, color: .black, square: .h8)
    let blackQueensideRook = Piece(.rook, color: .black, square: .a8)
    let whiteKingsideRook = Piece(.rook, color: .white, square: .h1)
    let whiteQueensideRook = Piece(.rook, color: .white, square: .a1)

    var legalCastlings = LegalCastlings()
    legalCastlings.invalidateCastling(for: blackKingsideRook)
    #expect(!legalCastlings.contains(.bK))
    #expect(legalCastlings.contains(.bQ))
    #expect(legalCastlings.contains(.wK))
    #expect(legalCastlings.contains(.wQ))

    legalCastlings.invalidateCastling(for: blackQueensideRook)
    #expect(!legalCastlings.contains(.bK))
    #expect(!legalCastlings.contains(.bQ))
    #expect(legalCastlings.contains(.wK))
    #expect(legalCastlings.contains(.wQ))

    legalCastlings.invalidateCastling(for: whiteKingsideRook)
    #expect(!legalCastlings.contains(.bK))
    #expect(!legalCastlings.contains(.bQ))
    #expect(!legalCastlings.contains(.wK))
    #expect(legalCastlings.contains(.wQ))

    legalCastlings.invalidateCastling(for: whiteQueensideRook)
    #expect(!legalCastlings.contains(.bK))
    #expect(!legalCastlings.contains(.bQ))
    #expect(!legalCastlings.contains(.wK))
    #expect(!legalCastlings.contains(.wQ))
  }

  @Test func enPassantCaptureSquare() {
    let blackPawn = Piece(.pawn, color: .black, square: .d5)
    let blackEnPassant = EnPassant(pawn: blackPawn)
    #expect(blackEnPassant.captureSquare == Square.d6)
    #expect(blackEnPassant.couldBeCaptured(by: Piece(.pawn, color: .white, square: .e5)))
    #expect(blackEnPassant.couldBeCaptured(by: Piece(.pawn, color: .white, square: .c5)))
    #expect(!blackEnPassant.couldBeCaptured(by: Piece(.pawn, color: .black, square: .e5)))
    #expect(!blackEnPassant.couldBeCaptured(by: Piece(.pawn, color: .white, square: .f5)))
    #expect(!blackEnPassant.couldBeCaptured(by: Piece(.pawn, color: .white, square: .b5)))
    #expect(!blackEnPassant.couldBeCaptured(by: Piece(.bishop, color: .white, square: .c5)))

    let whitePawn = Piece(.pawn, color: .white, square: .d4)
    let whiteEnPassant = EnPassant(pawn: whitePawn)
    #expect(whiteEnPassant.captureSquare == Square.d3)
    #expect(whiteEnPassant.couldBeCaptured(by: Piece(.pawn, color: .black, square: .e4)))
    #expect(whiteEnPassant.couldBeCaptured(by: Piece(.pawn, color: .black, square: .c4)))
    #expect(!whiteEnPassant.couldBeCaptured(by: Piece(.pawn, color: .white, square: .e4)))
    #expect(!whiteEnPassant.couldBeCaptured(by: Piece(.pawn, color: .black, square: .f4)))
    #expect(!whiteEnPassant.couldBeCaptured(by: Piece(.pawn, color: .black, square: .b4)))
    #expect(!whiteEnPassant.couldBeCaptured(by: Piece(.bishop, color: .black, square: .c4)))
  }

}
