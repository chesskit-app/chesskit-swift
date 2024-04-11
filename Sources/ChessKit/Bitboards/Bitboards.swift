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

        rookMagics = MagicBitboard.create(for: .rook)
        bishopMagics = MagicBitboard.create(for: .bishop)
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

    func legalMoves(for piece: Piece) -> Bitboard {
        let attacks = switch piece.kind {
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
            Bitboard(0)
        }

        let sameColorPieces = switch piece.color {
        case .black: blackPieces
        case .white: whitePieces
        }

        return attacks & ~sameColorPieces
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

    /// Cached rook moves using magic bitboards.
    private var rookMagics = [Magic]()
    /// Cached bishop moves using magic bitboards.
    private var bishopMagics = [Magic]()

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
