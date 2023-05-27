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
public class Game: ObservableObject {
    
    @Published public private(set) var moves: MoveTree
    private(set) var positions: [MoveTree.Index: Position]
    
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
    
    private var lastMainVariationIndex: MoveTree.Index {
        moves.indices.filter { $0.variation == 0 }.last ?? .minimum
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
    @discardableResult
    public func make(
        move: Move,
        from index: MoveTree.Index? = nil
    ) -> MoveTree.Index {
        let index = index ?? lastMainVariationIndex
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
            newPosition.move(pieceAt: castling.kingStart, to: castling.kingEnd)
            newPosition.move(pieceAt: castling.rookStart, to: castling.rookEnd)
        }
        
        if let promotedPiece = move.promotedPiece {
            newPosition.promote(pieceAt: move.end, to: promotedPiece.kind)
        }
        
        newPosition.toggleSideToMove()
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
        from index: MoveTree.Index? = nil
    ) -> MoveTree.Index {
        let index = index ?? lastMainVariationIndex
        
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
        from index: MoveTree.Index? = nil
    ) -> MoveTree.Index {
        var index = index ?? lastMainVariationIndex
        
        for moveString in moveStrings {
            index = make(move: moveString, from: index)
        }
        
        return index
    }
    
    /// The PGN represenation of the game.
    public var pgn: String {
        PGNParser.convert(game: self)
    }
    
}
