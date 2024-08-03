//
//  SamplePositions.swift
//  ChessKit
//

@testable import struct ChessKit.Position

extension Position {
    static let complex = Position(fen: "r1b1k1nr/p2p1pNp/n2B4/1p1NP2P/6P1/3P1Q2/P1P1K3/q5b1 b kq - 0 20")!

    static let ep = Position(fen: "rnbqkbnr/ppppp1pp/8/8/4Pp2/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")!

    static let castling = Position(fen: "4k2r/6r1/8/8/8/8/3R4/R3K3 w Qk - 0 1")!

    static let fiftyMove = Position(fen: "8/5k2/3p4/1p1Pp2p/pP2Pp1P/P4P1K/8/8 b - - 99 50")!
}
