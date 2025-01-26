//
//  MoveTree.swift
//  ChessKit
//

import Foundation

/// A tree-like data structure that represents the moves of a chess game.
///
/// The tree maintains the move order including variations and
/// provides index-based access for any element in the tree.
public struct MoveTree: Hashable, Sendable {

  /// The index of the root of the move tree.
  ///
  /// Defaults to `MoveTree.Index.minimum`.
  var minimumIndex: Index = .minimum

  /// The last index of the main variation of the move tree.
  private(set) var lastMainVariationIndex: Index = .minimum

  /// Dictionary representation of the tree for faster access.
  private(set) var dictionary: [Index: Node] = [:]
  /// The root node of the tree.
  private var root: Node?

  /// A set containing the indices of all the moves stored in the tree.
  public var indices: [Index] {
    Array(dictionary.keys)
  }

  /// Lock to restrict modification of tree nodes
  /// to ensure `Sendable` conformance for ``Node``.
  private static let nodeLock = NSLock()

  /// Adds a move to the move tree.
  ///
  /// - parameter move: The move to add to the tree.
  /// - parameter moveIndex: The `MoveIndex` of the parent move, if applicable.
  /// If `moveIndex` is `nil`, the move tree is cleared and the provided
  /// move is set to the `head` of the move tree.
  ///
  /// - returns: The move index resulting from the addition of the move.
  ///
  @discardableResult
  public mutating func add(
    move: Move,
    toParentIndex moveIndex: Index? = nil
  ) -> Index {
    let newNode = Node(move: move)

    guard let root, let moveIndex else {
      let index = minimumIndex.next

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

    Self.nodeLock.withLock {
      dictionary[newIndex] = newNode
    }
    newNode.index = newIndex

    if newIndex.variation == Index.mainVariation {
      lastMainVariationIndex = newIndex
    }

    return newIndex
  }

  /// Returns the index matching `move` in the next or child moves of the
  /// move contained at `index`.
  public func nextIndex(containing move: Move, for index: Index) -> Index? {
    guard let node = dictionary[index] else {
      if index == minimumIndex, let root, root.move == move {
        return root.index
      } else {
        return nil
      }
    }

    if let next = node.next, next.move == move {
      return next.index
    } else {
      return node.children.filter { $0.move == move }.first?.index
    }
  }

  /// Provides a single history for a given index.
  ///
  /// - parameter index: The index from which to generate the history.
  /// - returns: An array of move indices sorted from beginning to end with
  /// the end being the provided `index`.
  ///
  /// For chess this would represent an array of all the move indices
  /// from the starting move until the move defined by `index`, accounting
  /// for any branching variations in between.
  public func history(for index: Index) -> [Index] {
    let index = index == .minimum ? .minimum.next : index
    var currentNode = dictionary[index]
    var history: [Index] = []

    while currentNode != nil {
      if let node = currentNode {
        history.append(node.index)
      }

      currentNode = currentNode?.previous
    }

    return history.reversed()
  }

  /// Provides a single future for a given index.
  ///
  /// - parameter index: The index from which to generate the future.
  /// - returns: An array of move indices sorted from beginning to end.
  ///
  /// For chess this would represent an array of all the move indices
  /// from the move after the move defined by `index` to the last move
  /// of the variation.
  public func future(for index: Index) -> [Index] {
    let index = index == .minimum ? .minimum.next : index
    var currentNode = dictionary[index]
    var future: [Index] = []

    while currentNode != nil {
      currentNode = currentNode?.next

      if let node = currentNode {
        future.append(node.index)
      }
    }

    return future
  }

  /// Returns the full variation for a move at the provided `index`.
  ///
  /// This returns the sum of `history(for:)` and `future(for:)`.
  public func fullVariation(for index: Index) -> [Index] {
    history(for: index) + future(for: index)
  }

  private func indices(between start: Index, and end: Index) -> [Index] {
    var result = [Index]()

    let endNode = dictionary[end]
    var currentNode = dictionary[start]

    while currentNode != endNode {
      if let currentNode {
        result.append(currentNode.index)
      }

      currentNode = currentNode?.previous
    }

    return result
  }

  /// Provides the shortest path through the move tree
  /// from the given start and end indices.
  ///
  /// - parameter startIndex: The starting index of the path.
  /// - parameter endIndex: The ending index of the path.
  /// - returns: An array of indices starting with the index after `startIndex`
  /// and ending with `endIndex`. If `startIndex` and `endIndex`
  /// are the same, an empty array is returned.
  ///
  /// The purpose of this path is return the indices of the moves required to
  /// go from the current position at `startIndex` and end up with the
  /// final position at `endIndex`, so `startIndex` is included in the returned
  /// array, but `endIndex` is not. The path direction included with the index
  /// indicates the direction to move to get to the next index.
  public func path(
    from startIndex: Index,
    to endIndex: Index
  ) -> [(direction: PathDirection, index: Index)] {
    var results = [(PathDirection, Index)]()
    let startHistory = history(for: startIndex)
    let endHistory = history(for: endIndex)

    if startIndex == endIndex {
      // keep results array empty
    } else if startHistory.contains(endIndex) {
      results = indices(between: startIndex, and: endIndex)
        .map { (.reverse, $0) }
    } else if endHistory.contains(startIndex) {
      results = indices(between: endIndex, and: startIndex)
        .map { (.forward, $0) }
        .reversed()
    } else {
      // lowest common ancestor
      guard
        let lca = zip(startHistory, endHistory)
          .filter({ $0 == $1 })
          .last?.0
      else {
        return []
      }

      guard
        let startLCAIndex = startHistory.firstIndex(where: { $0 == lca }),
        let endLCAIndex = endHistory.firstIndex(where: { $0 == lca })
      else {
        return []
      }

      let startToLCAPath = startHistory[startLCAIndex...]
        .reversed()  // reverse since history is in ascending order
        .dropLast()  // drop LCA; to be included in the next array
        .map { (PathDirection.reverse, $0) }

      let LCAtoEndPath = endHistory[endLCAIndex...]
        .map { (PathDirection.forward, $0) }

      results = startToLCAPath + LCAtoEndPath
    }

    return results
  }

  /// The direction of the ``MoveTree`` path.
  public enum PathDirection: Sendable {
    /// Move forward (i.e. perform a move).
    case forward
    /// Move backward (i.e. undo a move).
    case reverse
  }

  /// Whether the tree is empty or not.
  public var isEmpty: Bool {
    root == nil
  }

  /// Annotates the move at the provided index.
  ///
  /// - parameter index: The index of the move to annotate.
  /// - parameter assessment: The move to annotate the move with.
  /// - parameter comment: The comment to annotate the move with.
  ///
  /// - returns: The move updated with the given annotations.
  ///
  @discardableResult
  public mutating func annotate(
    moveAt index: Index,
    assessment: Move.Assessment = .null,
    comment: String = ""
  ) -> Move? {
    Self.nodeLock.withLock {
      dictionary[index]?.move.assessment = assessment
      dictionary[index]?.move.comment = comment
    }
    return dictionary[index]?.move
  }

  /// Appends a promoted piece to a move at a given index.
  ///
  /// - parameter promotedPiece: the piece to append to the move.
  /// - parameter index: The index of the move to promote.
  ///
  /// - returns: The move updated with the given promoted piece.
  ///
  mutating func promotePiece(
    _ promotedPiece: Piece,
    at index: Index
  ) -> Move? {
    Self.nodeLock.withLock {
      dictionary[index]?.move.promotedPiece = promotedPiece
    }
    return dictionary[index]?.move.promotedPiece != nil ? dictionary[index]?.move : nil
  }
  // MARK: - PGN

  /// An element for representing the ``MoveTree`` in
  /// PGN (Portable Game Notation) format.
  public enum PGNElement: Hashable, Sendable {
    /// e.g. `1.`
    case whiteNumber(Int)
    /// e.g. `1...`
    case blackNumber(Int)
    /// e.g. `e4`
    case move(Move, Index)
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
    case .black:
      result.append(.blackNumber(node.index.number))
    }

    result.append(.move(node.move, node.index))

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
        result.append(.move(move, currentIndex))
      }

      // recursively generate PGN for all child nodes
      for child in currentNode?.previous?.children ?? [] {
        result.append(.variationStart)
        result.append(contentsOf: pgn(for: child))
        result.append(.variationEnd)
      }

      previousIndex = currentIndex
      currentNode = currentNode?.next
    }

    return result
  }

  /// Returns the ``MoveTree`` as an array of PGN
  /// (Portable Game Format) elements.
  public var pgnRepresentation: [PGNElement] {
    pgn(for: root)
  }

}

// MARK: - Equatable
extension MoveTree: Equatable {

  public static func == (lhs: MoveTree, rhs: MoveTree) -> Bool {
    lhs.dictionary == rhs.dictionary
  }

}

extension MoveTree {

  /// Object that represents a node in the move tree.
  class Node: Hashable, @unchecked Sendable {

    /// The move for this node.
    var move: Move
    /// The index for this node.
    fileprivate(set) var index: Index = .minimum
    /// The previous node.
    fileprivate(set) var previous: Node?
    /// The next node.
    fileprivate(set) weak var next: Node?
    /// Children nodes (i.e. variation moves).
    fileprivate var children: [Node] = []

    fileprivate init(move: Move) {
      self.move = move
    }

    // MARK: Equatable
    static func == (lhs: Node, rhs: Node) -> Bool {
      lhs.index == rhs.index && lhs.move == rhs.move
    }

    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
      hasher.combine(move)
      hasher.combine(index)
      hasher.combine(previous)
      hasher.combine(next)
      hasher.combine(children)
    }

  }

}
