//
//  MoveTree.swift
//  ChessKit
//

public class MoveTree {
    
    private var dictionary: [Index: Node] = [:]
    private var root: Node?
    
    /// Returns the move at the specified index.
    ///
    /// - parameter index: The move index to query.
    /// - returns: The move at the given index, or `nil` if no
    /// move exists at that index.
    ///
    public func move(at index: Index) -> Move? {
        dictionary[index]?.move
    }
    
    public subscript(_ index: Index) -> Move? {
        move(at: index)
    }
    
    /// The indices of all the moves stored in the tree, sorted ascending.
    public var indices: [Index] {
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
        toParentIndex moveIndex: Index? = nil
    ) -> Index {
        let newNode = Node(move: move)
        
        guard let root, let moveIndex else {
            let index = Index.minimum.next
            
            newNode.index = index
            self.root = newNode
            
            dictionary = [index: newNode]
            return index
        }
        
        let parent = dictionary[moveIndex] ?? root
        newNode.previous = parent
        
        var newIndex = moveIndex.next
        
        if parent.next == nil {
            parent.next = newNode
        } else {
            parent.children.append(newNode)
            while indices.contains(newIndex) {
                newIndex.variation += 1
            }
        }
        
        dictionary[newIndex] = newNode
        newNode.index = newIndex
        
        return newIndex
    }
    
    public func previousIndex(for index: Index) -> Index? {
        dictionary[index]?.previous?.index
    }
    
    public func nextIndex(for index: Index) -> Index? {
        dictionary[index]?.next?.index
    }
    
}

extension MoveTree {
    
    /// Object that represents a node in the move tree.
    private class Node {
        /// The move for this node.
        let move: Move
        /// The move index for this node.
        var index: Index = .minimum
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
    
}

extension MoveTree {
    
    /// Object that represents the index of a node in the move tree.
    public struct Index: Comparable, Hashable, CustomStringConvertible {
        
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
        
        /// The minimum value of `MoveTree.Index(number: 0, color: .black)`
        ///
        /// This represents the starting position of the game.
        ///
        /// i.e. `MoveTree.Index(number: 1, color: .white)` is returned by `MoveTree.Index.minimum.next`
        /// which is the first move of the game (played by white).
        public static let minimum = Index(number: 0, color: .black, variation: 0)
        
        /// The previous index.
        ///
        /// This assumes `variation` is constant.
        public var previous: Index {
            switch color {
            case .white:
                return Index(
                    number: number - 1,
                    color: .black,
                    variation: variation
                )
            case .black:
                return Index(
                    number: number,
                    color: .white,
                    variation: variation
                )
            }
        }
        
        /// The next index.
        ///
        /// This assumes `variation` is constant.
        public var next: Index {
            switch color {
            case .white:
                return Index(
                    number: number,
                    color: .black,
                    variation: variation
                )
            case .black:
                return Index(
                    number: number + 1,
                    color: .white,
                    variation: variation
                )
            }
        }
        
        public static func < (lhs: Index, rhs: Index) -> Bool {
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
    
}
