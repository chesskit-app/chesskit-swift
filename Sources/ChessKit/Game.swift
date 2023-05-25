//
//  Game.swift
//  ChessKit
//

import Foundation

public class MoveTree {
    
    private class Node {
        
        /// The move for this node.
        let move: Move
        /// The move index for this node.
        var index: MoveIndex = .minimum
        /// The previous node.
        var previous: Node?
        /// The next node.
        weak var next: Node?
        /// Children nodes (i.e. variation moves)
        var children: [Node] = []
        
        init(move: Move) {
            self.move = move
        }
        
    }
    
    private var dictionary: [MoveIndex: Node] = [:]
    private var root: Node?
    
    /// Returns the move at the specified index.
    ///
    /// - parameter index: The move index to query.
    /// - returns: The move at the given index, or `nil` if no
    /// move exists at that index.
    ///
    public func move(at index: MoveIndex) -> Move? {
        dictionary[index]?.move
    }
    
    public subscript(_ index: MoveIndex) -> Move? {
        move(at: index)
    }
    
    /// The indices of all the moves stored in the tree, sorted ascending.
    public var indices: [MoveIndex] {
        dictionary.keys.sorted(by: <)
    }
    
    /// Adds a move to the move tree.
    ///
    /// - parameter move: The move to add to the tree.
    /// - parameter moveIndex: The `MoveIndex` of the parent move, if applicable.
    /// If `moveIndex` is `nil`, the move tree is cleared and the provided
    /// move is set to the `head` of the move tree.
    ///
    /// - returns: The move index resulting from the addition of the move.
    @discardableResult
    public func add(
        move: Move,
        toParentIndex moveIndex: MoveIndex? = nil
    ) -> MoveIndex {
        let newNode = Node(move: move)
        
        guard let root, let moveIndex else {
            let index = MoveIndex.minimum.next
            
            newNode.index = index
            self.root = newNode
            
            dictionary = [index: newNode]
            return index
        }
        
        let parent = dictionary[moveIndex] ?? root
        newNode.previous = parent
        
        var newIndex = moveIndex.next
        
        print("=====")
        print(move.san)
        print(parent.move.san)
        
        if parent.next == nil {
            parent.next = newNode
        } else {
            parent.children.append(newNode)
            
            while indices.contains(newIndex) {
                newIndex.variation += 1
                print(newIndex)
            }
        }
        
        dictionary[newIndex] = newNode
        newNode.index = newIndex
        
        return newIndex
    }
    
    public func previousIndex(for index: MoveIndex) -> MoveIndex? {
        dictionary[index]?.previous?.index
    }
    
    public func nextIndex(for index: MoveIndex) -> MoveIndex? {
        dictionary[index]?.next?.index
    }
    
}

public struct MoveIndex: Comparable, Hashable, CustomStringConvertible {
    
    public var description: String {
        "[\(number), \(color), #\(variation)]"
    }
    
    public let number: Int
    public let color: Piece.Color
    public var variation: Int
    
    public init(number: Int, color: Piece.Color, variation: Int) {
        self.number = number
        self.color = color
        self.variation = variation
    }
    
    /// The minimum value of `MoveIndex(number: 0, color: .black)`
    ///
    /// This represents the starting position of the game.
    ///
    /// i.e. `MoveIndex(number: 1, color: .white)` is returned by `MoveIndex.minimum.next`
    /// which is the first move of the game (played by white).
    public static let minimum = MoveIndex(number: 0, color: .black, variation: 0)
    
    /// The previous index.
    ///
    /// This assumes `variation` is constant.
    public var previous: MoveIndex {
        switch color {
        case .white:
            return MoveIndex(
                number: number - 1,
                color: .black,
                variation: variation
            )
        case .black:
            return MoveIndex(
                number: number,
                color: .white,
                variation: variation
            )
        }
    }
    
    /// The next index.
    ///
    /// This assumes `variation` is constant.
    public var next: MoveIndex {
        switch color {
        case .white:
            return MoveIndex(
                number: number,
                color: .black,
                variation: variation
            )
        case .black:
            return MoveIndex(
                number: number + 1,
                color: .white,
                variation: variation
            )
        }
    }
    
    public static func < (lhs: MoveIndex, rhs: MoveIndex) -> Bool {
        if lhs.variation == rhs.variation {
            return lhs.number < rhs.number || (
                lhs.number == rhs.number &&
                lhs.color == .white && rhs.color == .black
            )
        } else {
            if lhs.number == rhs.number {
                return lhs.variation < rhs.variation
            } else {
                return lhs.number < rhs.number || (
                    lhs.number == rhs.number &&
                    lhs.color == .white && rhs.color == .black
                )
            }
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
    
    @Published public private(set) var moves: MoveTree
    private(set) var positions: [MoveIndex: Position]
    
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
    
    private var lastMainVariationIndex: MoveIndex {
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
    public func make(move: Move, from index: MoveIndex? = nil) -> MoveIndex {
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
    
    @discardableResult
    public func make(move moveString: String, from index: MoveIndex? = nil) -> MoveIndex {
        let index = index ?? lastMainVariationIndex
        
        guard let position = positions[index],
              let move = SANParser.parse(move: moveString, in: position)
        else {
            return index
        }
        
        return make(move: move, from: index)
    }
    
    @discardableResult
    public func make(moves moveStrings: [String], from index: MoveIndex? = nil) -> MoveIndex {
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
