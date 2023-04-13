//
//  Game.swift
//  ChessKit
//

import Foundation

/// Contains a pair of moves (white and black) and the associated turn number.
public struct MovePair: Hashable {
    /// The turn number of the move.
    public var turnNumber: Int
    /// The white move.
    public var white: Move
    /// The black move.
    ///
    /// This is optional since black goes second and may not have
    /// made a move yet, or the game ended after white's move.
    public var black: Move?
    
    /// Initialize a `MovePair` with the given moves and turn number.
    ///
    /// - parameter turnNumber: The number of the current move.
    /// - parameter white: The white move in the pair.
    /// - parameter black: The black move in the pair, if applicable.
    ///
    /// Each turn has a white move but not necessarily a black move
    /// if black hasn't moved yet.
    ///
    public init(turnNumber: Int = 1, white: Move, black: Move? = nil) {
        self.turnNumber = turnNumber
        self.white = white
        self.black = black
    }
    
    /// Update the attribute of a particular move.
    ///
    /// - parameter color: The color of the move in the pair to update.
    /// - parameter keyPath: The key path of the move to update.
    /// - parameter newValue: The new value to set the key path to.
    ///
    public mutating func updateMove<T>(
        with color: Piece.Color,
        keyPath: WritableKeyPath<Move, T>,
        newValue: T
    ) {
        switch color {
        case .white:    white[keyPath: keyPath] = newValue
        case .black:    black?[keyPath: keyPath] = newValue
        }
    }
    
    /// Returns the move within the move pair corresponding to the
    /// provided color.
    ///
    /// - parameter color: The color of the requested move.
    /// - returns: The move corresponding to `color`, or `nil`
    /// if a move of that color doesn't exist (only applicable
    /// for `Piece.Color.black`).
    public func move(for color: Piece.Color) -> Move? {
        switch color {
        case .white:    return white
        case .black:    return black
        }
    }
}

/// Represents a chess game.
///
/// This object is the entry point for interacting with a full
/// chess game within `ChessKit`. It provides methods for
/// making moves and publishes the played moves in an observable way.
///
public class Game: ObservableObject {
    
    @Published public private(set) var moves: [Int: MovePair]
    var positions: [Position]
    
    var currentPosition: Position? {
        positions.last
    }
    
    /// Initialize a game with a starting position.
    ///
    /// - parameter position: The starting position of the game.
    /// Defaults to the starting position.
    ///
    public init(startingWith position: Position = .standard) {
        moves = [:]
        positions = [position]
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
    /// - parameter turn: The turn of the move.
    /// - parameter color: The color of the piece that is performing the move.
    ///
    public func make(move: Move, turn: Int, for color: Piece.Color) {
        guard let currentPosition = positions.last else { return }
        
        switch color {
        case .white:
            moves[turn] = MovePair(turnNumber: turn, white: move, black: nil)
        case .black:
            moves[turn]?.black = move
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
        
        positions.append(newPosition)
    }
    
    /// The PGN represenation of the game.
    public var pgn: String {
        PGNParser.convert(game: self)
    }
    
}
