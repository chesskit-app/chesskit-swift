//
//  Square+BB.swift
//  ChessKit
//

extension Square {
    var bb: Bitboard { 1 << rawValue }
}

extension Square.File {
    var bb: Bitboard { .aFile.east(number - 1) }
}

extension Square.Rank {
    var bb: Bitboard { .rank1.north(value - 1) }
}
