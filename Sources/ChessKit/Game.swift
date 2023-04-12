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
    
    public init(turnNumber: Int = 1, white: Move, black: Move? = nil) {
        self.turnNumber = turnNumber
        self.white = white
        self.black = black
    }
    
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
    
    public func move(for color: Piece.Color) -> Move? {
        switch color {
        case .white:    return white
        case .black:    return black
        }
    }
}

public class Game: ObservableObject {
    
    @Published public var moves: [Int: MovePair]
    var positions: [Position]
    
    var currentPosition: Position? {
        positions.last
    }
    
    public init(startingWith position: Position) {
        moves = [:]
        positions = [position]
    }
    
    public init?(pgn: String) {
        guard let parsed = PGNParser.parse(game: pgn) else {
            return nil
        }
        
        moves = parsed.moves
        positions = parsed.positions
    }
    
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
    
    /// The FEN represenation of the game.
    public var pgn: String {
        PGNParser.convert(game: self)
    }
    
}
