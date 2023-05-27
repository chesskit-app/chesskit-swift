//
//  MoveTree.swift
//  ChessKit
//

/// A tree-like data structure that represents the moves of a chess game.
///
/// The tree maintains the move order including variations and
/// provides index-based access for any element in the tree.
public class MoveTree: Equatable {
    
    public static func == (lhs: MoveTree, rhs: MoveTree) -> Bool {
        lhs.dictionary == rhs.dictionary
    }
    
    /// Dictionary representation of the tree for faster access.
    private var dictionary: [Index: Node] = [:]
    /// The root node of the tree.
    private var root: Node?
    
    /// Returns the move at the specified index.
    ///
    /// - parameter index: The move index to query.
    /// - returns: The move at the given index, or `nil` if no
    /// move exists at that index.
    ///
    /// This value can also be accessed using a subscript on
    /// the `MoveTree` directly,
    /// e.g. `tree[.init(number: 2, color: .white)]`
    ///
    public func move(at index: Index) -> Move? {
        dictionary[index]?.move
    }
    
    /// Subscript implementation for `MoveTree`.
    ///
    /// This method returns the same value as `move(at:)`.
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
    
    /// Returns the index of the previous move given an `index`.
    public func previousIndex(for index: Index) -> Index? {
        dictionary[index]?.previous?.index
    }
    
    /// Returns the index of the next move given an `index`.
    public func nextIndex(for index: Index) -> Index? {
        dictionary[index]?.next?.index
    }
    
    public func history(for index: Index) -> [MoveTree.Index] {
        var currentNode = dictionary[index]
        var history: [MoveTree.Index] = []
        
        while (currentNode != nil) {
            if let node = currentNode?.previous {
                history.append(node.index)
                currentNode = node
            }
        }
        
        return history
    }
    
    public var isEmpty: Bool {
        root == nil
    }
    
    public func annotate(moveAt index: MoveTree.Index, assessment: Move.Assessment, comment: String = "") {
        dictionary[index]?.move.assessment = assessment
        dictionary[index]?.move.comment = comment
    }
    
    public enum PGNElement {
        /// e.g. `1.`
        case whiteNumber(Int)
        /// e.g. `1...`
        case blackNumber(Int)
        /// e.g. `e4`
        case whiteMove(Move)
        /// e.g. `e5`
        case blackMove(Move)
        /// e.g. `(`
        case variationStart
        /// e.g. `)`
        case variationEnd
    }
    
    private func pgn(for node: Node?) -> [PGNElement] {
        guard let node else { return [] }
        var result: [PGNElement] = []
        
        switch node.index.color {
        case .white:
            result.append(.whiteNumber(node.index.number))
            result.append(.whiteMove(node.move))
        case .black:
            result.append(.blackNumber(node.index.number))
            result.append(.blackMove(node.move))
        }
        
        var currentNode = node.next
        var previousIndex = node.index
        
        while currentNode != nil {
            guard let currentIndex = currentNode?.index else { break }
            
            switch (previousIndex.number, currentIndex.number) {
            case let (x, y) where x < y:
                result.append(.whiteNumber(currentIndex.number))
            default:
                break
            }
            
            if let move = currentNode?.move {
                switch currentIndex.color {
                case .white:    result.append(.whiteMove(move))
                case .black:    result.append(.blackMove(move))
                }
            }
            
            for child in currentNode?.previous?.children ?? [] {
                result.append(.variationStart)
                // recursively generate PGN for all child nodes
                result.append(contentsOf: pgn(for: child))
                result.append(.variationEnd)
            }
            
            previousIndex = currentIndex
            currentNode = currentNode?.next
        }
        
        return result
    }
    
    public var pgnRepresentation: [PGNElement] {
        pgn(for: root)
    }
    
}

extension MoveTree {
    
    /// Object that represents a node in the move tree.
    private class Node: Equatable {
        
        static func == (lhs: MoveTree.Node, rhs: MoveTree.Node) -> Bool {
            lhs.move == rhs.move &&
            lhs.index == rhs.index &&
            lhs.previous == rhs.previous &&
            lhs.next == rhs.next &&
            lhs.children == rhs.children
        }
        
        /// The move for this node.
        var move: Move
        /// The move index for this node.
        var index: MoveTree.Index = .minimum
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
