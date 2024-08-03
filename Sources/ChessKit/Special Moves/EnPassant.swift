//
//  EnPassant.swift
//  ChessKit
//

/// Structure that captures en passant moves.
struct EnPassant: Equatable, Hashable, Sendable {

    /// Pawn that is capable of being captured by en passant.
    var pawn: Piece

    /// The square that the capturing pawn will move to after the en passant.
    var captureSquare: Square {
        Square(pawn.square.file, pawn.color == .white ? 3 : 6)
    }

    /// Determines whether or not the pawn could be captured by en passant.
    ///
    /// - parameter capturingPiece: The piece that is capturing the contained pawn.
    /// - returns: Whether `capturingPiece` could capture `pawn`.
    ///
    /// `capturingPiece` must be an opposite color pawn that is on the
    /// same rank as the target pawn and exactly 1 file away from the
    /// target pawn for this method to return `true`, otherwise `false`
    /// is returned.
    func couldBeCaptured(by capturingPiece: Piece) -> Bool {
        capturingPiece.kind == .pawn &&
        capturingPiece.color == pawn.color.opposite &&
        capturingPiece.square.rank == pawn.square.rank &&
        abs(capturingPiece.square.file.number - pawn.square.file.number) == 1
    }

}
