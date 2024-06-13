//
//  MoveTreeIndex.swift
//  ChessKit
//

/// Object that represents the index of a node in the move tree.
public struct MoveTreeIndex: Hashable {

    /// The move number.
    public let number: Int
    /// The color of the piece moved on this move.
    public let color: Piece.Color
    /// The variation number of the move.
    ///
    /// If multiple moves occur for the same move number and piece color,
    /// the `variation` is incremented.
    ///
    /// `variation = 0` is assumed to be the main variation in a move tree.
    public var variation: Int = 0

    /// Creates a `MoveTreeIndex` with a given `number`, `color`,
    /// and `variation` (default is `0`).
    public init(number: Int, color: Piece.Color, variation: Int = 0) {
        self.number = number
        self.color = color
        self.variation = variation
    }

    /// The minimum value of `MoveTreeIndex(number: 0, color: .black)`
    ///
    /// This represents the starting position of the game.
    ///
    /// i.e. `MoveTreeIndex(number: 1, color: .white)` is returned by `MoveTreeIndex.minimum.next`
    /// which is the first move of the game (played by white).
    public static let minimum = MoveTreeIndex(number: 0, color: .black)

    /// The previous index.
    ///
    /// This assumes `variation` is constant.
    /// For the previous index taking into account variations
    /// use `MoveTree.previousIndex(for:)`.
    public var previous: MoveTreeIndex {
        switch color {
        case .white:
            MoveTreeIndex(
                number: number - 1,
                color: .black,
                variation: variation
            )
        case .black:
            MoveTreeIndex(
                number: number,
                color: .white,
                variation: variation
            )
        }
    }

    /// The next index.
    ///
    /// This assumes `variation` is constant.
    /// For the next index taking into account variations
    /// use `MoveTree.nextIndex(for:)`.
    public var next: MoveTreeIndex {
        switch color {
        case .white:
            MoveTreeIndex(
                number: number,
                color: .black,
                variation: variation
            )
        case .black:
            MoveTreeIndex(
                number: number + 1,
                color: .white,
                variation: variation
            )
        }
    }

}
