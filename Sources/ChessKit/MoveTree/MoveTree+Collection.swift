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
                dictionary[index]?.move = newValue
            }
        }
    }

}

// MARK: - BidirectionalCollection

extension MoveTree: BidirectionalCollection {

    public func index(before i: Index) -> Index {
        if i == minimumIndex.next {
            minimumIndex
        } else {
            dictionary[i]?.previous?.index ?? i
        }
    }

    public func index(after i: Index) -> Index {
        if i == minimumIndex {
            dictionary[i.next]?.index ?? i
        } else {
            dictionary[i]?.next?.index ?? i
        }
    }

}
