//
//  Bitboards.swift
//  ChessKit
//

/// Structure that houses the bitboards for all
/// piece types and colors.
class Bitboards {

    /// Bitboard for black king pieces.
    var k: Bitboard = 0
    /// Bitboard for black queen pieces.
    var q: Bitboard = 0
    /// Bitboard for black rook pieces.
    var r: Bitboard = 0
    /// Bitboard for black bishop pieces.
    var b: Bitboard = 0
    /// Bitboard for black knight pieces.
    var n: Bitboard = 0
    /// Bitboard for black pawn pieces.
    var p: Bitboard = 0

    /// Bitboard for white king pieces.
    var K: Bitboard = 0
    /// Bitboard for white queen pieces.
    var Q: Bitboard = 0
    /// Bitboard for white rook pieces.
    var R: Bitboard = 0
    /// Bitboard for white bishop pieces.
    var B: Bitboard = 0
    /// Bitboard for white knight pieces.
    var N: Bitboard = 0
    /// Bitboard for white pawn pieces.
    var P: Bitboard = 0

    /// Bitboard for all the black pieces.
    var blackPieces: Bitboard { k | q | r | b | n | p }
    /// Bitboard for all the white pieces.
    var whitePieces: Bitboard { K | Q | R | B | N | P }
    /// Bitboard for all the pieces.
    var allPieces: Bitboard { blackPieces | whitePieces }

    init(position: Position) {
        position.pieces.forEach { piece in
            switch (piece.color, piece.kind) {
            case (.black, .king  ): k |= piece.square.bb
            case (.black, .queen ): q |= piece.square.bb
            case (.black, .rook  ): r |= piece.square.bb
            case (.black, .bishop): b |= piece.square.bb
            case (.black, .knight): n |= piece.square.bb
            case (.black, .pawn  ): p |= piece.square.bb

            case (.white, .king  ): K |= piece.square.bb
            case (.white, .queen ): Q |= piece.square.bb
            case (.white, .rook  ): R |= piece.square.bb
            case (.white, .bishop): B |= piece.square.bb
            case (.white, .knight): N |= piece.square.bb
            case (.white, .pawn  ): P |= piece.square.bb
            }
        }

        rookMagics = createMagics(for: .rook)
        bishopMagics = createMagics(for: .bishop)
    }

    func piece(at square: Square) -> Piece? {
        if k & square.bb != 0 { return .init(.king, color: .black, square: square) }
        if q & square.bb != 0 { return .init(.queen, color: .black, square: square) }
        if r & square.bb != 0 { return .init(.rook, color: .black, square: square) }
        if b & square.bb != 0 { return .init(.bishop, color: .black, square: square) }
        if n & square.bb != 0 { return .init(.knight, color: .black, square: square) }
        if p & square.bb != 0 { return .init(.pawn, color: .black, square: square) }

        if K & square.bb != 0 { return .init(.king, color: .white, square: square) }
        if Q & square.bb != 0 { return .init(.queen, color: .white, square: square) }
        if R & square.bb != 0 { return .init(.rook, color: .white, square: square) }
        if B & square.bb != 0 { return .init(.bishop, color: .white, square: square) }
        if N & square.bb != 0 { return .init(.knight, color: .white, square: square) }
        if P & square.bb != 0 { return .init(.pawn, color: .white, square: square) }

        return nil
    }

    /// Cached knight attack bitboards by square.
    private var knightAttacks = [Bitboard: Bitboard]()

    private func knightAttacks(from sq: Bitboard) -> Bitboard {
        if let attacks = knightAttacks[sq] {
            return attacks
        } else {
            /// Knight attack bit shifts
            /// ```
            ///       +---+---+---+---+---+---+---+---+
            ///    8  |   |   |   |   |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    7  |   |   |   |   |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    6  |   |   |+15|   |+17|   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    5  |   | +6|   |   |   |+10|   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    4  |   |   |   | 0 |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    3  |   |-10|   |   |   | -6|   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    2  |   |   |-17|   |-15|   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    1  |   |   |   |   |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///         a   b   c   d   e   f   g   h
            /// ```
            let attacks = [17, 15, 10, 6].reduce(Bitboard(0)) {
                $0 | sq << $1 | sq >> $1
            }
            knightAttacks[sq] = attacks
            return attacks
        }
    }

    /// Cached king attack bitboards by square.
    private var kingAttacks = [Bitboard: Bitboard]()

    private func kingAttacks(from sq: Bitboard) -> Bitboard {
        if let attacks = kingAttacks[sq] {
            return attacks
        } else {
            /// King attack bit shifts
            /// ```
            ///       +---+---+---+---+---+---+---+---+
            ///    8  |   |   |   |   |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    7  |   |   |   |   |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    6  |   |   |   |   |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    5  |   |   | +7| +8| +9|   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    4  |   |   | -1|  0| +1|   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    3  |   |   | -7| -8| -9|   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    2  |   |   |   |   |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///    1  |   |   |   |   |   |   |   |   |
            ///       +---+---+---+---+---+---+---+---+
            ///         a   b   c   d   e   f   g   h
            /// ```
            var attacks = sq.east() | sq.west()
            let horizontal = sq | attacks
            attacks |= horizontal.north() | horizontal.south()

            kingAttacks[sq] = attacks
            return attacks
        }
    }

    func legalMoves(for piece: Piece) -> Bitboard {
        let attacks: Bitboard = switch piece.kind {
        case .king:     
            kingAttacks(from: piece.square.bb)
        case .queen:    
            rookMagics[piece.square.rawValue].attacks(for: allPieces) | bishopMagics[piece.square.rawValue].attacks(for: allPieces)
        case .rook:     
            rookMagics[piece.square.rawValue].attacks(for: allPieces)
        case .bishop:   
            bishopMagics[piece.square.rawValue].attacks(for: allPieces)
        case .knight:   
            knightAttacks(from: piece.square.bb)
        case .pawn:
            0
        }

        let sameColorPieces = switch piece.color {
        case .black: blackPieces
        case .white: whitePieces
        }

        return attacks & ~sameColorPieces
    }

    // MARK: - Magic Bitboards

    private var rookMagicNumbers: [Bitboard] = [
        0x0080001020400080, 0x0040001000200040, 0x0080081000200080, 0x0080040800100080,
        0x0080020400080080, 0x0080010200040080, 0x0080008001000200, 0x0080002040800100,
        0x0000800020400080, 0x0000400020005000, 0x0000801000200080, 0x0000800800100080,
        0x0000800400080080, 0x0000800200040080, 0x0000800100020080, 0x0000800040800100,
        0x0000208000400080, 0x0000404000201000, 0x0000808010002000, 0x0000808008001000,
        0x0000808004000800, 0x0000808002000400, 0x0000010100020004, 0x0000020000408104,
        0x0000208080004000, 0x0000200040005000, 0x0000100080200080, 0x0000080080100080,
        0x0000040080080080, 0x0000020080040080, 0x0000010080800200, 0x0000800080004100,
        0x0000204000800080, 0x0000200040401000, 0x0000100080802000, 0x0000080080801000,
        0x0000040080800800, 0x0000020080800400, 0x0000020001010004, 0x0000800040800100,
        0x0000204000808000, 0x0000200040008080, 0x0000100020008080, 0x0000080010008080,
        0x0000040008008080, 0x0000020004008080, 0x0000010002008080, 0x0000004081020004,
        0x0000204000800080, 0x0000200040008080, 0x0000100020008080, 0x0000080010008080,
        0x0000040008008080, 0x0000020004008080, 0x0000800100020080, 0x0000800041000080,
        0x00FFFCDDFCED714A, 0x007FFCDDFCED714A, 0x003FFFCDFFD88096, 0x0000040810002101,
        0x0001000204080011, 0x0001000204000801, 0x0001000082000401, 0x0001FFFAABFAD1A2
    ]

    private var bishopMagicNumbers: [Bitboard] = [
        0x0002020202020200, 0x0002020202020000, 0x0004010202000000, 0x0004040080000000,
        0x0001104000000000, 0x0000821040000000, 0x0000410410400000, 0x0000104104104000,
        0x0000040404040400, 0x0000020202020200, 0x0000040102020000, 0x0000040400800000,
        0x0000011040000000, 0x0000008210400000, 0x0000004104104000, 0x0000002082082000,
        0x0004000808080800, 0x0002000404040400, 0x0001000202020200, 0x0000800802004000,
        0x0000800400A00000, 0x0000200100884000, 0x0000400082082000, 0x0000200041041000,
        0x0002080010101000, 0x0001040008080800, 0x0000208004010400, 0x0000404004010200,
        0x0000840000802000, 0x0000404002011000, 0x0000808001041000, 0x0000404000820800,
        0x0001041000202000, 0x0000820800101000, 0x0000104400080800, 0x0000020080080080,
        0x0000404040040100, 0x0000808100020100, 0x0001010100020800, 0x0000808080010400,
        0x0000820820004000, 0x0000410410002000, 0x0000082088001000, 0x0000002011000800,
        0x0000080100400400, 0x0001010101000200, 0x0002020202000400, 0x0001010101000200,
        0x0000410410400000, 0x0000208208200000, 0x0000002084100000, 0x0000000020880000,
        0x0000001002020000, 0x0000040408020000, 0x0004040404040000, 0x0002020202020000,
        0x0000104104104000, 0x0000002082082000, 0x0000000020841000, 0x0000000000208800,
        0x0000000010020200, 0x0000000404080200, 0x0000040404040400, 0x0002020202020200
    ]

    private struct Magic {
        var mask: Bitboard = 0
        var magic: Bitboard = 0
        var shift: Int = 0
        var attacks: [Bitboard: Bitboard] = [:]

        func attacks(for occupancy: Bitboard) -> Bitboard {
            attacks[index(for: occupancy)] ?? 0
        }

        func index(for occupancy: Bitboard) -> Bitboard {
            ((occupancy & mask) &* magic) >> shift
        }
    }

    private var rookMagics = [Magic]()
    private var bishopMagics = [Magic]()

    private func createMagics(for kind: Piece.Kind) -> [Magic] {
        guard [.rook, .bishop].contains(kind) else { return [] }

        return Square.allCases.map { sq in
            let edges: Bitboard = ((.rank1 | .rank8) & ~sq.rank.bb) | ((.aFile | .hFile) & ~sq.file.bb)

            var m = Magic()
            m.magic = kind == .rook ? rookMagicNumbers[sq.rawValue] : bishopMagicNumbers[sq.rawValue]
            m.mask = slidingAttacks(for: kind, from: sq, occupancy: 0) & ~edges
            m.shift = Bitboard.bitWidth - m.mask.nonzeroBitCount

            var subset = Bitboard(0)

            repeat {
                let index = (subset &* m.magic) >> m.shift
                m.attacks[index] = slidingAttacks(
                    for: kind,
                    from: sq,
                    occupancy: subset
                )
                subset = (subset &- m.mask) & m.mask
            } while subset != 0

            return m
        }
    }

    private func slidingAttacks(
        for kind: Piece.Kind,
        from square: Square,
        occupancy: Bitboard
    ) -> Bitboard {
        var attacks = Bitboard(0)

        /// Single square directional moves for given piece.
        let directions: [(Bitboard) -> Bitboard] = switch kind {
        case .rook:
            [{ $0.north() },
             { $0.south() },
             { $0.east() },
             { $0.west() }]
        case .bishop:
            [{ $0.northEast() },
             { $0.northWest() },
             { $0.southEast() },
             { $0.southWest() }]
        default:
            []
        }
        
        for direction in directions {
            var nextSquare = square.bb

            repeat {
                nextSquare = direction(nextSquare)
                attacks |= nextSquare
            } while nextSquare != 0 && (occupancy & nextSquare) == 0
        }
        
        return attacks
    }

}

extension Square {
    var bb: Bitboard { 1 << rawValue }
}

extension Square.File {
    var bb: Bitboard { .aFile.east(number - 1) }
}

extension Square.Rank {
    var bb: Bitboard { .rank1.north(value - 1) }
}

// MARK: - Utilities

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

extension Bitboard {

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

public struct BBBoard {

    public weak var delegate: BoardDelegate?

    //    public var position: Position

    private var bb: Bitboards

    public init(position: Position = .standard) {
        //        self.position = position
        bb = .init(position: position)
    }

    @discardableResult
    public mutating func move(pieceAt start: Square, to end: Square) -> Move? {
        guard canMove(pieceAt: start, to: end) else {
            return nil
        }

        return nil
    }

    public func canMove(pieceAt square: Square, to newSquare: Square) -> Bool {
        guard let piece = bb.piece(at: square) else { return false }
        return bb.legalMoves(for: piece) & newSquare.bb != 0
    }

    public func legalMoves(forPieceAt square: Square) -> [Square] {
        guard let piece = bb.piece(at: square) else { return [] }
        return squares(from: bb.legalMoves(for: piece))
    }

    @discardableResult
    public mutating func completePromotion(of move: Move, to kind: Piece.Kind) -> Move {
        move
    }

    private func squares(from bitboard: Bitboard) -> [Square] {
        Square.allCases.filter { bitboard & $0.bb != 0 }
    }

}
