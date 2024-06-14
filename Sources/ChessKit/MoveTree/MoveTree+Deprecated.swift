//
//  MoveTree+Deprecated.swift
//  ChessKit
//

extension MoveTree {
    /// Returns the move at the specified index.
    ///
    /// - parameter index: The move index to query.
    /// - returns: The move at the given index, or `nil` if no
    /// move exists at that index.
    ///
    /// This value can also be accessed using a subscript on
    /// the ``MoveTree`` directly,
    /// e.g. `tree[.init(number: 2, color: .white)]`
    @available(*, deprecated, renamed: "subscript(_:)")
    public func move(at index: Index) -> Move? {
        dictionary[index]?.move
    }

    /// Returns the index of the previous move given an `index`.
    @available(*, deprecated, renamed: "index(before:)")
    public func previousIndex(for index: Index) -> Index? {
        if index == minimumIndex.next {
            return minimumIndex
        } else {
            return dictionary[index]?.previous?.index
        }
    }

    /// Returns the index of the next move given an `index`.
    @available(*, deprecated, renamed: "index(after:)")
    public func nextIndex(for index: Index) -> Index? {
        if index == minimumIndex {
            return dictionary[minimumIndex.next]?.index
        } else {
            return dictionary[index]?.next?.index
        }
    }
}
