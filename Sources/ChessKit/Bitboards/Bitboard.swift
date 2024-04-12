//
//  Bitboard.swift
//  ChessKit
//

/// Contains `UInt64`-based utilities for manipulating
/// chess bitboards.
typealias Bitboard = UInt64

extension Bitboard {

    /// Bitboard representing all the squares on the A file.
    static let aFile: Bitboard = 0x0101010101010101
    /// Bitboard representing all the squares on the H file.
    static let hFile: Bitboard = aFile << 7

    /// Bitboard representing all the squares on the 1st rank.
    static let rank1: Bitboard = 0xFF
    /// Bitboard representing all the squares on the 8th rank.
    static let rank8: Bitboard = rank1 << (8 * 7)

    /// Translates the receiver `n` column "east" on an 8x8 grid.
    ///
    /// `n` should be in the range `[1, 7]`.
    func east(_ n: Int = 1) -> Bitboard {
        (self & ~Self.hFile) << n
    }

    /// Translates the receiver `n` columns "west" on an 8x8 grid.
    ///
    /// `n` should be in the range `[1, 7]`.
    func west(_ n: Int = 1) -> Bitboard {
        (self & ~Self.aFile) >> n
    }

    /// Translates the receiver `n` rows "north" on an 8x8 grid.
    ///
    /// `n` should be in the range `[1, 7]`.
    func north(_ n: Int = 1) -> Bitboard {
        self << (8 * n)
    }

    /// Translates the receiver `n` rows "south" on an 8x8 grid.
    ///
    /// `n` should be in the range `[1, 7]`.
    func south(_ n: Int = 1) -> Bitboard {
        self >> (8 * n)
    }

    /// Translates the receiver `n` rows "north" and `n` columns "east" on an 8x8 grid.
    ///
    /// `n` should be in the range `[1, 7]`.
    func northEast(_ n: Int = 1) -> Bitboard {
        (self & ~Self.hFile) << (9 * n)
    }

    /// Translates the receiver `n` rows "north" and `n` columns "west" on an 8x8 grid.
    ///
    /// `n` should be in the range `[1, 7]`.
    func northWest(_ n: Int = 1) -> Bitboard {
        (self & ~Self.aFile) << (7 * n)
    }

    /// Translates the receiver `n` rows "south" and `n` columns "east" on an 8x8 grid.
    ///
    /// `n` should be in the range `[1, 7]`.
    func southEast(_ n: Int = 1) -> Bitboard {
        (self & ~Self.hFile) >> (7 * n)
    }

    /// Translates the receiver `n` rows "south" and `n` columns "west" on an 8x8 grid.
    ///
    /// `n` should be in the range `[1, 7]`.
    func southWest(_ n: Int = 1) -> Bitboard {
        (self & ~Self.aFile) >> (9 * n)
    }

}

extension Bitboard: CustomDebugStringConvertible {

    public var debugDescription: String {
        chessString()
    }

    /// Converts the `Bitboard` to an 8x8 board representation string.
    ///
    /// - parameter occupied: The character with which to represent occupied squares.
    /// - parameter empty: The character with which to represent unoccupied squares.
    /// - parameter labelRanks: Whether or not to label ranks (i.e. 1, 2, 3, ...).
    /// - parameter labelFiles: Whether or not to label ranks (i.e. a, b, c, ...).
    /// - returns: A string representing an 8x8 chess board.
    func chessString(
        _ occupied: Character = "X",
        _ empty: Character = ".",
        labelRanks: Bool = true,
        labelFiles: Bool = true
    ) -> String {
        var s = ""

        for rank in Square.Rank.range.reversed() {
            s += labelRanks ? "\(rank)" : ""

            for file in Square.File.allCases {
                let sq = Square(file, .init(rank)).bb
                s += (self & sq != 0) ? " \(occupied)" : " \(empty)"
            }

            s += "\n"
        }

        return s + (labelFiles ? "  a b c d e f g h" : "")
    }

}

extension Bitboard {
    var squares: [Square] {
        var indices: [Int] = []
        var bb = self

        while bb != 0 {
            let index = bb.trailingZeroBitCount
            indices.append(index)
            bb &= bb &- 1
        }

        return indices.compactMap(Square.init)
    }
}

extension [Bitboard: Bitboard] {
    /// Allows non-nil indexing of the dictionary.
    ///
    /// If a value is not found for the provided
    /// key, an empty bitboard is returned.
    subscript(safe bb: Bitboard) -> Bitboard {
        self[bb] ?? 0
    }
}
