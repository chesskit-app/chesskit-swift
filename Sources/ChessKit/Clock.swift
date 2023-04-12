//
//  Clock.swift
//  ChessKit
//

/// Tracks the number of moves in a game for
/// the purposes of regulating the 50 move rule.
///
public struct Clock {
    
    /// The maximum number of half moves before
    /// a draw by the fifty move rule should be called.
    static var halfMoveMaximum = 100
    
    /// The number of halfmoves, incremented after each move.
    /// It is reset to zero after each capture or pawn move.
    var halfmoves = 0
    
    /// The number of fullmoves, incremented after each Black move.
    var fullmoves = 1
    
}
