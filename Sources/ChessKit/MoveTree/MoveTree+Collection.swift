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

    public func index(before i: Index) -> Index {
        _previousIndex(for: i) ?? i
    }

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

    public func index(after i: Index) -> Index {
        _nextIndex(for: i) ?? i
    }

    public func hasIndex(after i: Index) -> Bool {
        _nextIndex(for: i) != nil
    }

    private func _nextIndex(for index: Index) -> Index? {
        if index == minimumIndex {
            dictionary[index.next]?.index
        } else {
            dictionary[index]?.next?.index
        }
    }

}
