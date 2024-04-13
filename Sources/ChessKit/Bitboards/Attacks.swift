//
//  Attacks.swift
//  ChessKit
//

/// Stores pre-generated pseudo-legal attack bitboards
/// for non-pawn piece types.
///
struct Attacks {

    /// Cached king attacks, the dictionary key
    /// corresponds to `Square.bb`.
    static var kings = [Bitboard: Bitboard]()
    /// Cached rook attacks, the array index corresponds
    /// to `Square.rawValue`.
    static var rooks = [Magic]()
    /// Cached bishop attacks, the array index corresponds
    /// to `Square.rawValue`.
    static var bishops = [Magic]()
    /// Cached king attacks, the dictionary key
    /// corresponds to `Square.bb`.
    static var knights = [Bitboard: Bitboard]()

    /// Generates and caches attack bitboards for all piece kinds.
    static func create() {
        Piece.Kind.allCases.forEach(create)
    }

    private static func create(for kind: Piece.Kind) {
        switch kind {
        case .king:
            createKingAttacks()
        case .queen:
            break   // uses (rooks | bishops)
        case .rook:
            createMagics(for: .rook)
        case .bishop:
            createMagics(for: .bishop)
        case .knight:
            createKnightAttacks()
        case .pawn:
            break
        }
    }

    private static func createKingAttacks() {
        // ensure attacks are only initialized once
        guard kings.isEmpty else { return }

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
        Square.allCases.forEach { square in
            let sq = square.bb

            var attacks = sq.east() | sq.west()
            let horizontal = sq | attacks
            attacks |= horizontal.north() | horizontal.south()

            kings[sq] = attacks
        }
    }

    private static func createKnightAttacks() {
        // ensure attacks are only initialized once
        guard knights.isEmpty else { return }

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
        Square.allCases.forEach { square in
            let sq = square.bb
            knights[sq] = [17, 15, 10, 6].reduce(Bitboard(0)) {
                var result = $0

                let up = sq << $1
                if distance(sq, up) <= 2 {
                    result |= up
                }

                let down = sq >> $1
                if distance(sq, down) <= 2 {
                    result |= down
                }

                return result
            }
        }
    }

    /// Computes the Chebyshev Distance between two bitboard squares.
    private static func distance(_ sq1: Bitboard, _ sq2: Bitboard) -> Int {
        guard let s1 = Square(sq1), let s2 = Square(sq2) else {
            return .max
        }

        return max(
            abs(s1.file.number - s2.file.number),
            abs(s1.rank.value - s2.rank.value)
        )
    }

    /// Generates array containing a `Magic` object for each
    /// square on the chess board.
    ///
    /// Uses a similar techique as Stockfish (see [`Stockfish/init_magics`](https://github.com/official-stockfish/Stockfish/blob/0716b845fdef8a20102b07eaec074b8da8162523/src/bitboard.cpp#L139)) except with hardcoded magics rather than
    /// seeded random generation.
    ///
    private static func createMagics(for kind: Piece.Kind) {
        guard let magicNumbers = magicNumbers[kind] else { return }

        // ensure magics are only initialized once
        switch kind {
        case .bishop:   guard bishops.isEmpty else { return }
        case .rook:     guard rooks.isEmpty else { return }
        default:        break
        }

        let magics = Square.allCases.map { sq in
            // determine board edges not including current square
            let edges: Bitboard = ((.rank1 | .rank8) & ~sq.rank.bb) | ((.aFile | .hFile) & ~sq.file.bb)

            // calculate magic bitboard factors
            var m = Magic(
                magic: magicNumbers[sq.rawValue],
                mask: slidingAttacks(for: kind, from: sq, occupancy: 0) & ~edges
            )

            // use Carry-Rippler technique to generate
            // all possible subsets of current "mask"
            //
            // "mask" contains the possible moves on an empty board,
            // "subset" is a subset of those moves that accounts for
            // any possible blocking piece
            var subset = Bitboard(0)

            repeat {
                // calculate magic index
                let key = m.key(for: subset)
                // store subset in attacks dictionary
                m.attacks[key] = slidingAttacks(
                    for: kind,
                    from: sq,
                    occupancy: subset
                )
                // generate new subset
                subset = (subset &- m.mask) & m.mask
            } while subset != 0

            return m
        }

        switch kind {
        case .rook:     rooks = magics
        case .bishop:   bishops = magics
        default:        break
        }
    }

    /// Returns the possible moves for a sliding piece (bishop or rook)
    /// accounting for blocking pieces.
    ///
    /// - Note: The first blocking piece encountered in each direction
    /// is included in the returned bitboard. It is up to the caller to handle
    /// captures or non-capturable pieces (i.e. same color pieces).
    private static func slidingAttacks(
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

        directions.forEach { d in
            var nextSquare = square.bb

            repeat {
                nextSquare = d(nextSquare)
                attacks |= nextSquare
            } while nextSquare != 0 && (occupancy & nextSquare) == 0
        }

        return attacks
    }

    /// Magic numbers for calculating bishop and rook magic bitboards.
    ///
    /// Derived by [Pradyumna Kannan](http://pradu.us/old/Nov27_2008/Buzz/research/magic/Bitboards.pdf).
    private static var magicNumbers: [Piece.Kind: [Bitboard]] = [
        .bishop: [
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
        ],
        .rook: [
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
    ]

}

/// Stores the magic factors and attacks for a given piece
/// type (bishop or rook) and square (a1-h8).
///
struct Magic {
    /// The magic number used to compute the hash key.
    fileprivate var magic: Bitboard
    /// The bitmask representing the possible moves on an empty board
    /// excluding edges.
    fileprivate var mask: Bitboard

    /// The number of zero bits in the mask, used to calculate the hash key.
    fileprivate var shift: Int {
        Bitboard.bitWidth - mask.nonzeroBitCount
    }

    /// The dictionary of attack bitboards, keyed by the hash key.
    fileprivate var attacks: [Bitboard: Bitboard] = [:]

    /// Returns the hash key for a given `subset` of possible moves.
    fileprivate func key(for subset: Bitboard) -> Bitboard {
        (subset &* magic) >> shift
    }

    /// Returns the attack bitboard for the piece represented
    /// by the receiver for the given `occupancy`.
    fileprivate func attacks(for occupancy: Bitboard) -> Bitboard {
        attacks[key(for: occupancy & mask)] ?? 0
    }
}

extension [Magic] {
    func attacks(from square: Square, for occupancy: Bitboard) -> Bitboard {
        self[square.rawValue].attacks(for: occupancy)
    }
}
