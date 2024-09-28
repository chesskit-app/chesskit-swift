//
//  MockBoardDelegate.swift
//  ChessKit
//

@testable import ChessKit

final class MockBoardDelegate: BoardDelegate {
  private let didPromote: (@Sendable (Move) -> Void)?
  private let didCheckKing: (@Sendable (Piece.Color) -> Void)?
  private let didEnd: (@Sendable (Board.EndResult) -> Void)?

  init(
    didPromote: (@Sendable (Move) -> Void)? = nil,
    didCheckKing: (@Sendable (Piece.Color) -> Void)? = nil,
    didEnd: (@Sendable (Board.EndResult) -> Void)? = nil
  ) {
    self.didPromote = didPromote
    self.didCheckKing = didCheckKing
    self.didEnd = didEnd
  }

  func didPromote(with move: Move) {
    didPromote?(move)
  }

  func didCheckKing(ofColor color: Piece.Color) {
    didCheckKing?(color)
  }

  func didEnd(with result: Board.EndResult) {
    didEnd?(result)
  }
}
