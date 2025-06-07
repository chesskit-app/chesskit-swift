//
//  MoveTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct MoveTests {

  @Test func moveSANInit() {
    let move = Move(result: .move, piece: .init(.pawn, color: .white, square: .e4), start: .e2, end: .e4)
    let moveFromSAN = Move(san: "e4", position: .standard)

    #expect(move == moveFromSAN)
  }

  @Test func moveInvalidSANInit() {
    #expect(Move(san: "e5", position: .standard) == nil)
  }

  @Test func moveNotation() {
    let pawnD3 = Move(result: .move, piece: Piece(.pawn, color: .white, square: .d3), start: .d2, end: .d3)
    #expect(pawnD3.san == "d3")
    #expect(pawnD3.lan == "d2d3")

    let bishopF4 = Move(result: .move, piece: Piece(.bishop, color: .white, square: .f4), start: .c1, end: .f4)
    #expect(bishopF4.san == "Bf4")
    #expect(bishopF4.lan == "c1f4")
  }

  @Test func captureNotation() {
    let capturedPiece = Piece(.bishop, color: .black, square: .d5)
    let capturingPiece = Piece(.pawn, color: .white, square: .e4)
    let capture = Move(result: .capture(capturedPiece), piece: capturingPiece, start: .e4, end: .d5)
    #expect(capture.san == "exd5")
    #expect(capture.lan == "e4d5")
  }

  @Test func enPassantNotation() {
    let ep = EnPassant(pawn: Piece(.pawn, color: .black, square: .d5))
    let move = Move(result: .capture(ep.pawn), piece: Piece(.pawn, color: .white, square: .e5), start: .e5, end: .d6)
    #expect(move.san == "exd6")
    #expect(move.lan == "e5d6")
  }

  @Test func castlingNotation() {
    let shortCastle = Move(result: .castle(.bK), piece: Piece(.king, color: .black, square: .e8), start: .e8, end: .g8)
    #expect(shortCastle.san == "O-O")
    #expect(shortCastle.lan == "e8g8")

    let longCastle = Move(result: .castle(.bQ), piece: Piece(.king, color: .black, square: .e8), start: .e8, end: .c8, checkState: .checkmate)
    #expect(longCastle.san == "O-O-O#")
    #expect(longCastle.lan == "e8c8")
  }

  @Test func promotionsNotation() {
    let pawn = Piece(.pawn, color: .white, square: .e8)
    let queen = Piece(.queen, color: .white, square: .e8)
    let rook = Piece(.rook, color: .white, square: .e8)

    var queenPromo = Move(result: .move, piece: pawn, start: .e7, end: .e8)
    queenPromo.promotedPiece = queen
    #expect(queenPromo.san == "e8=Q")
    #expect(queenPromo.lan == "e7e8q")

    let capturedPiece = Piece(.bishop, color: .black, square: .f8)
    var rookCapturePromo = Move(result: .capture(capturedPiece), piece: pawn, start: .e7, end: .f8, checkState: .check)
    rookCapturePromo.promotedPiece = rook
    #expect(rookCapturePromo.san == "exf8=R+")
    #expect(rookCapturePromo.lan == "e7f8r")
  }

  @Test func checksNotation() {
    let check = Move(result: .move, piece: Piece(.queen, color: .white, square: .d4), start: .e3, end: .d4, checkState: .check)
    #expect(check.san == "Qd4+")
    #expect(check.lan == "e3d4")
  }

  @Test func checkmateNotation() {
    let checkmate = Move(result: .move, piece: Piece(.rook, color: .white, square: .g7), start: .g4, end: .g7, checkState: .checkmate)
    #expect(checkmate.san == "Rg7#")
    #expect(checkmate.lan == "g4g7")
  }

  @Test func moveAssessments() {
    #expect(Move.Assessment.null.notation == "")
    #expect(Move.Assessment.good.notation == "!")
    #expect(Move.Assessment.mistake.notation == "?")
    #expect(Move.Assessment.brilliant.notation == "!!")
    #expect(Move.Assessment.blunder.notation == "??")
    #expect(Move.Assessment.interesting.notation == "!?")
    #expect(Move.Assessment.dubious.notation == "?!")
    #expect(Move.Assessment.forced.notation == "□")
    #expect(Move.Assessment.singular.notation == "")
    #expect(Move.Assessment.worst.notation == "")

    #expect(Move.Assessment(notation: "!") == .good)
    #expect(Move.Assessment(notation: "?") == .mistake)
    #expect(Move.Assessment(notation: "!!") == .brilliant)
    #expect(Move.Assessment(notation: "??") == .blunder)
    #expect(Move.Assessment(notation: "!?") == .interesting)
    #expect(Move.Assessment(notation: "?!") == .dubious)
    #expect(Move.Assessment(notation: "□") == .forced)
  }

}
