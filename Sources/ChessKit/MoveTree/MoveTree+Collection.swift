//
//  MoveTree+Collection.swift
//  ChessKit
//

// MARK: - Collection
extension MoveTree: Collection {

  public var startIndex: Index { minimumIndex }

  public var endIndex: Index { lastMainVariationIndex }

  public subscript(_ index: Index) -> Move? {
    get {
      dictionary[index]?.move
    }
    set {
      if let newValue {
        add(move: newValue, toParentIndex: index.previous)
      }
    }
  }

}

// MARK: - BidirectionalCollection
extension MoveTree: BidirectionalCollection {

  /// Returns the previous index in the move tree based on `i`.
  ///
  /// If there is no previous index, `i` is returned.
  /// Use `hasIndex(before:)` to check whether a valid index
  /// before `i` exists.
  public func index(before i: Index) -> Index {
    _previousIndex(for: i) ?? i
  }

  /// Returns `true` if a valid index before `i` exists.
  public func hasIndex(before i: Index) -> Bool {
    _previousIndex(for: i) != nil
  }

  private func _previousIndex(for index: Index) -> Index? {
    if index == minimumIndex.next {
      minimumIndex
    } else {
      dictionary[index]?.previous?.index
    }
  }

  /// Returns the next index in the move tree based on `i`.
  ///
  /// If there is no next index, `i` is returned.
  /// Use `hasIndex(after:)` to check whether a valid index
  /// after `i` exists.
  public func index(after i: Index) -> Index {
    _nextIndex(for: i) ?? i
  }

  /// Returns `true` if a valid index after `i` exists.
  public func hasIndex(after i: Index) -> Bool {
    _nextIndex(for: i) != nil
  }

  private func _nextIndex(for index: Index) -> Index? {
    if index == minimumIndex {
      dictionary[minimumIndex.next]?.index
    } else {
      dictionary[index]?.next?.index
    }
  }

}
