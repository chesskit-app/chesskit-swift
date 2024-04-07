//
//  SpecialMoveTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

class SpecialMoveTests: XCTestCase {

    func testLegalCastlingInvalidationForKings() {
        let blackKing = Piece(.king, color: .black, square: .e8)
        let whiteKing = Piece(.king, color: .white, square: .e1)

        var legalCastlings = LegalCastlings()
        legalCastlings.invalidateCastling(for: blackKing)
        XCTAssertFalse(legalCastlings.contains(.bK))
        XCTAssertFalse(legalCastlings.contains(.bQ))
        XCTAssertTrue(legalCastlings.contains(.wK))
        XCTAssertTrue(legalCastlings.contains(.wQ))

        legalCastlings.invalidateCastling(for: whiteKing)
        XCTAssertFalse(legalCastlings.contains(.bK))
        XCTAssertFalse(legalCastlings.contains(.bQ))
        XCTAssertFalse(legalCastlings.contains(.wK))
        XCTAssertFalse(legalCastlings.contains(.wQ))
    }

    func testLegalCastlingInvalidationForRooks() {
        let blackKingsideRook = Piece(.rook, color: .black, square: .h8)
        let blackQueensideRook = Piece(.rook, color: .black, square: .a8)
        let whiteKingsideRook = Piece(.rook, color: .white, square: .h1)
        let whiteQueensideRook = Piece(.rook, color: .white, square: .a1)

        var legalCastlings = LegalCastlings()
        legalCastlings.invalidateCastling(for: blackKingsideRook)
        XCTAssertFalse(legalCastlings.contains(.bK))
        XCTAssertTrue(legalCastlings.contains(.bQ))
        XCTAssertTrue(legalCastlings.contains(.wK))
        XCTAssertTrue(legalCastlings.contains(.wQ))

        legalCastlings.invalidateCastling(for: blackQueensideRook)
        XCTAssertFalse(legalCastlings.contains(.bK))
        XCTAssertFalse(legalCastlings.contains(.bQ))
        XCTAssertTrue(legalCastlings.contains(.wK))
        XCTAssertTrue(legalCastlings.contains(.wQ))

        legalCastlings.invalidateCastling(for: whiteKingsideRook)
        XCTAssertFalse(legalCastlings.contains(.bK))
        XCTAssertFalse(legalCastlings.contains(.bQ))
        XCTAssertFalse(legalCastlings.contains(.wK))
        XCTAssertTrue(legalCastlings.contains(.wQ))

        legalCastlings.invalidateCastling(for: whiteQueensideRook)
        XCTAssertFalse(legalCastlings.contains(.bK))
        XCTAssertFalse(legalCastlings.contains(.bQ))
        XCTAssertFalse(legalCastlings.contains(.wK))
        XCTAssertFalse(legalCastlings.contains(.wQ))
    }
    
    func testEnPassantCaptureSquare() {
        let blackPawn = Piece(.pawn, color: .black, square: .d5)
        let blackEnPassant = EnPassant(pawn: blackPawn)
        XCTAssertEqual(blackEnPassant.captureSquare, Square.d6)
        XCTAssertTrue(blackEnPassant.canBeCaptured(by: Piece(.pawn, color: .white, square: .e5)))
        XCTAssertTrue(blackEnPassant.canBeCaptured(by: Piece(.pawn, color: .white, square: .c5)))
        XCTAssertFalse(blackEnPassant.canBeCaptured(by: Piece(.pawn, color: .black, square: .e5)))
        XCTAssertFalse(blackEnPassant.canBeCaptured(by: Piece(.pawn, color: .white, square: .f5)))
        XCTAssertFalse(blackEnPassant.canBeCaptured(by: Piece(.pawn, color: .white, square: .b5)))
        XCTAssertFalse(blackEnPassant.canBeCaptured(by: Piece(.bishop, color: .white, square: .c5)))

        let whitePawn = Piece(.pawn, color: .white, square: .d4)
        let whiteEnPassant = EnPassant(pawn: whitePawn)
        XCTAssertEqual(whiteEnPassant.captureSquare, Square.d3)
        XCTAssertTrue(whiteEnPassant.canBeCaptured(by: Piece(.pawn, color: .black, square: .e4)))
        XCTAssertTrue(whiteEnPassant.canBeCaptured(by: Piece(.pawn, color: .black, square: .c4)))
        XCTAssertFalse(whiteEnPassant.canBeCaptured(by: Piece(.pawn, color: .white, square: .e4)))
        XCTAssertFalse(whiteEnPassant.canBeCaptured(by: Piece(.pawn, color: .black, square: .f4)))
        XCTAssertFalse(whiteEnPassant.canBeCaptured(by: Piece(.pawn, color: .black, square: .b4)))
        XCTAssertFalse(whiteEnPassant.canBeCaptured(by: Piece(.bishop, color: .black, square: .c4)))
    }

}
