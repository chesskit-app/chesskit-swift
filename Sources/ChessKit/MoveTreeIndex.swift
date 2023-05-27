//
//  MoveTreeIndex.swift
//  ChessKit
//

extension MoveTree {
    
    /// Object that represents the index of a node in the move tree.
    public struct Index: Comparable, CustomStringConvertible, Hashable {
        
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
        
        /// Creates a `MoveTree.Index` with a given `number`, `color`,
        /// and `variation` (default is `0`).
        public init(number: Int, color: Piece.Color, variation: Int = 0) {
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
        public static let minimum = Index(number: 0, color: .black)
        
        /// The previous index.
        ///
        /// This assumes `variation` is constant.
        /// For the previous index taking into account variations
        /// use `MoveTree.previousIndex(for:)`.
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
        /// For the next index taking into account variations
        /// use `MoveTree.nextIndex(for:)`.
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
        
        // MARK: Comparable
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
        
        // MARK: CustomStringConvertible
        public var description: String {
            "[\(number), \(color), #\(variation)]"
        }
        
    }
    
}
