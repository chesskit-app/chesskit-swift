//
//  MoveTreeIndex.swift
//  ChessKit
//

extension MoveTree {
    /// Object that represents the index of a node in the move tree.
    public struct Index: Hashable {

        public static let mainVariation = 0

        /// The move number.
        public let number: Int
        /// The color of the piece moved on this move.
        public let color: Piece.Color
        /// The variation number of the move.
        ///
        /// If multiple moves occur for the same move number and piece color,
        /// the `variation` is incremented.
        ///
        /// A `variation` equal to `MoveTreeIndex.mainVariation` is assumed to be the
        /// main variation in a move tree.
        public var variation: Int = Self.mainVariation

        /// Creates a `MoveTreeIndex` with a given `number`, `color`,
        /// and `variation` (default is `0`).
        public init(number: Int, color: Piece.Color, variation: Int = Self.mainVariation) {
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
        public static let minimum = Index(number: 0, color: .black)

        /// The previous index.
        ///
        /// This assumes `variation` is constant.
        /// For the previous index taking into account variations
        /// use `MoveTree.index(before:)`.
        public var previous: Index {
            switch color {
            case .white:
                Index(
                    number: number - 1,
                    color: .black,
                    variation: variation
                )
            case .black:
                Index(
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
        /// use `MoveTree.index(after:)`.
        public var next: Index {
            switch color {
            case .white:
                Index(
                    number: number,
                    color: .black,
                    variation: variation
                )
            case .black:
                Index(
                    number: number + 1,
                    color: .white,
                    variation: variation
                )
            }
        }

    }

}

extension MoveTree.Index: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.variation == rhs.variation {
            if lhs.number == rhs.number {
                lhs.color == .white && rhs.color == .black
            } else {
                lhs.number < rhs.number
            }
        } else {
            // prioritize lower variation numbers (since 0 is the main variation)
            lhs.variation > rhs.variation
        }
    }
}
