//
//  BoardDelegate.swift
//  ChessKit
//

/// Delegate protocol that allows the implementer to receive
/// events related to changes in position on the board such
/// as pawn promotions and end results.
@available(*, deprecated, message: "Monitor `state` property of `Board` instead.")
public protocol BoardDelegate: AnyObject, Sendable {
  /// Called when a pawn reaches the promotion square.
  func willPromote(with move: Move)
  /// Called after a pawn has promoted to a new `Piece.Kind`.
  ///
  /// `move` will have its `promotedPiece` set when this is called.
  func didPromote(with move: Move)
  /// Called when the king with `color` is placed in check.
  func didCheckKing(ofColor color: Piece.Color)
  /// Called when the board has reached an end state.
  ///
  /// For example, checkmate, stalemate, etc.
  func didEnd(with result: Board.EndResult)
}
