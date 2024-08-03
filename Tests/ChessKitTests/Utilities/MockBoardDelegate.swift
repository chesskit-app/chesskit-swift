//
//  MockBoardDelegate.swift
//  ChessKit
//

@testable import ChessKit

final class MockBoardDelegate: BoardDelegate {
    private let didPromote: (@Sendable (Move) -> Void)?
    private let didEnd: (@Sendable (Board.EndResult) -> Void)?

    init(
        didPromote: (@Sendable (Move) -> Void)? = nil,
        didEnd: (@Sendable (Board.EndResult) -> Void)? = nil
    ) {
        self.didPromote = didPromote
        self.didEnd = didEnd
    }

    func didPromote(with move: Move) {
        didPromote?(move)
    }
    
    func didEnd(with result: Board.EndResult) {
        didEnd?(result)
    }
}
