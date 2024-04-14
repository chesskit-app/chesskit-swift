//
//  Square+BB.swift
//  ChessKit
//

extension Square {
    var bb: Bitboard { 1 << rawValue }

    init?(_ bb: Bitboard) {
        self.init(rawValue: bb.trailingZeroBitCount)
    }
}

extension [Square] {
    var bb: Bitboard {
        var bb = Bitboard(0)

        self.forEach {
            bb |= $0.bb
        }

        return bb
    }
}

extension Square.File {
    var bb: Bitboard { .aFile.east(number - 1) }
}

extension Square.Rank {
    var bb: Bitboard { .rank1.north(value - 1) }
}
