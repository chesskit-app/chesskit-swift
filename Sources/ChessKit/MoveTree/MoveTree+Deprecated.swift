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
    @available(
        *, deprecated,
         renamed: "index(before:)",
         message: "Use index(before:) to obtain the previous index or hasIndex(before:) to check if a valid previous index exists."
    )
    public func previousIndex(for index: Index) -> Index? {
        if index == minimumIndex.next {
            minimumIndex
        } else {
            dictionary[index]?.previous?.index
        }
    }

    /// Returns the index of the next move given an `index`.
    @available(
        *, deprecated,
         renamed: "index(after:)",
         message: "Use index(after:) to obtain the next index or hasIndex(after:) to check if a valid next index exists."
    )
    public func nextIndex(for index: Index) -> Index? {
        if index == minimumIndex {
            dictionary[minimumIndex.next]?.index
        } else {
            dictionary[index]?.next?.index
        }
    }
}
