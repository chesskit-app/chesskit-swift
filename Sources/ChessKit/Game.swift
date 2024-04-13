//
//  Game.swift
//  ChessKit
//

import Foundation

/// Represents a chess game.
///
/// This object is the entry point for interacting with a full
/// chess game within `ChessKit`. It provides methods for
/// making moves and publishes the played moves in an observable way.
///
public class Game: Equatable, ObservableObject {

    /// The move tree representing all moves made in the game.
    @Published public private(set) var moves: MoveTree
    /// A dictionary of every position in the game, keyed by move index.
    public private(set) var positions: [MoveTree.Index: Position]

    /// Initialize a game with a starting position.
    ///
    /// - parameter position: The starting position of the game.
    /// Defaults to the starting position.
    ///
    public init(startingWith position: Position = .standard) {
        moves = MoveTree()
        positions = [.minimum: position]
    }

    /// Initialize a game with a PGN string.
    ///
    /// - parameter pgn: A string containing a PGN representation of
    /// a game.
    ///
    /// This initalizer fails if the PGN is invalid.
    public init?(pgn: String) {
        guard let parsed = PGNParser.parse(game: pgn) else {
            return nil
        }

        moves = parsed.moves
        positions = parsed.positions
    }

    /// Perform the provided move in the game.
    ///
    /// - parameter move: The move to perform.
    /// - parameter index: The current move index to make the move from.
    /// If this parameter is `nil` or omitted, the move is made from the
    /// last move in the main variation branch.
    /// - returns: The move index of the resulting position. If the
    /// move couldn't be made, the provided `index` is returned directly.
    ///
    /// This method does not make any move legality assumptions,
    /// it will attempt to make the move defined by `move` by moving
    /// pieces at the provided starting/ending squares and making any
    /// necessary captures, promotions, etc. It is the responsibility
    /// of the caller to ensure the move is legal, see the `Board` struct.
    ///
    /// If `move` is the same as the upcoming move in the
    /// current variation of `index`, the move is not made, otherwise
    /// another variation with the same first move as the existing one
    /// would be created.
    ///
    @discardableResult
    public func make(
        move: Move,
        from index: MoveTree.Index
    ) -> MoveTree.Index {
        if let existingMoveIndex = moves.nextIndex(containing: move, for: index) {
            // if attempted move already exists next in the variation,
            // skip making it and return the corresponding index
            return existingMoveIndex
        }

        let newIndex = moves.add(move: move, toParentIndex: index)

        guard let currentPosition = positions[index] else {
            return index
        }

        var newPosition = currentPosition

        switch move.result {
        case .move:
            newPosition.move(pieceAt: move.start, to: move.end)
            if move.piece.kind == .pawn { newPosition.resetHalfmoveClock() }
        case let .capture(capturedPiece):
            newPosition.remove(capturedPiece)
            newPosition.move(pieceAt: move.start, to: move.end)
            newPosition.resetHalfmoveClock()
        case let .castle(castling):
            newPosition.castle(castling)
        }

        if let promotedPiece = move.promotedPiece {
            newPosition.promote(pieceAt: move.end, to: promotedPiece.kind)
        }

        positions[newIndex] = newPosition
        return newIndex
    }

    /// Perform the provided move in the game.
    ///
    /// - parameter moveString: The SAN string of the move to perform.
    /// - parameter index: The current move index to make the move from.
    /// If this parameter is `nil` or omitted, the move is made from the
    /// last move in the main variation branch.
    /// - returns: The move index of the resulting position. If the
    /// move couldn't be made, the provided `index` is returned directly.
    ///
    /// This method does not make any move legality assumptions,
    /// it will attempt to make the move defined by `moveString` by moving
    /// pieces at the provided starting/ending squares and making any
    /// necessary captures, promotions, etc. It is the responsibility
    /// of the caller to ensure the move is legal, see the `Board` struct.
    ///
    @discardableResult
    public func make(
        move moveString: String,
        from index: MoveTree.Index
    ) -> MoveTree.Index {
        guard let position = positions[index],
              let move = SANParser.parse(move: moveString, in: position)
        else {
            return index
        }

        return make(move: move, from: index)
    }

    /// Perform the provided moves in the game.
    ///
    /// - parameter moveStrings: An array of SAN strings of the moves to perform.
    /// - parameter index: The current move index to make the moves from.
    /// If this parameter is `nil` or omitted, the move is made from the
    /// last move in the main variation branch.
    /// - returns: The move index of the resulting position. If the
    /// moves couldn't be made, the provided `index` is returned directly.
    ///
    /// This method does not make any move legality assumptions,
    /// it will attempt to make the moves defined by `moveStrings` by moving
    /// pieces at the provided starting/ending squares and making any
    /// necessary captures, promotions, etc. It is the responsibility
    /// of the caller to ensure the moves are legal, see the `Board` struct.
    ///
    @discardableResult
    public func make(
        moves moveStrings: [String],
        from index: MoveTree.Index
    ) -> MoveTree.Index {
        var index = index

        for moveString in moveStrings {
            index = make(move: moveString, from: index)
        }

        return index
    }

    /// The PGN represenation of the game.
    public var pgn: String {
        PGNParser.convert(game: self)
    }

    // MARK: Equatable
    public static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.moves == rhs.moves && lhs.positions == rhs.positions
    }

}
