//
//  BBBoard.swift
//  ChessKit
//

struct BBBoard {

    // MARK: - Properties

    public weak var delegate: BoardDelegate?

    public var position: Position

    private var set: PieceSet {
        position.pieceSet
    }

    // MARK: - Initializer

    init(position: Position) {
        Attacks.create()
        self.position = position
    }

    // MARK: - Public

    @discardableResult
    public mutating func move(pieceAt start: Square, to end: Square) -> Move? {
        guard canMove(pieceAt: start, to: end) else {
            return nil
        }

        return nil
    }

    public func canMove(pieceAt square: Square, to newSquare: Square) -> Bool {
        guard let piece = set.get(square) else { return false }
        return legalMoves(for: piece, in: set) & newSquare.bb != 0
    }

    public func legalMoves(forPieceAt square: Square) -> [Square] {
        guard let piece = set.get(square) else { return [] }
        return legalMoves(for: piece, in: set).squares
    }

    @discardableResult
    public mutating func completePromotion(of move: Move, to kind: Piece.Kind) -> Move {
        move
    }

    // MARK: - Move Validation

    private func legalMoves(for piece: Piece, in set: PieceSet) -> Bitboard {
        let attacks = switch piece.kind {
        case .king:
            kingAttacks[safe: piece.square.bb]
        case .queen:
            queenAttacks(from: piece.square, occupancy: set.all)
        case .rook:
            rookAttacks(from: piece.square, occupancy: set.all)
        case .bishop:
            bishopAttacks(from: piece.square, occupancy: set.all)
        case .knight:
            knightAttacks[safe: piece.square.bb]
        case .pawn:
            pawnAttacks(piece.color, from: piece.square.bb, set: set)
        }

        let us = set.get(piece.color)
        let pseudoLegalMoves = attacks & ~us

        let legalMoves = pseudoLegalMoves.squares.filter {
            validate(moveFor: piece, to: $0)
        }

        return legalMoves.bb
    }

    /// Determines if a pseudo-legal move for a piece to a given square
    /// is valid.
    ///
    /// - parameter piece: The piece to move.
    /// - parameter square: The square to move the piece to.
    /// - returns: Whether the move is valid.
    /// 
    private func validate(moveFor piece: Piece, to square: Square) -> Bool {
        // attempt move in test set
        //
        // to-do: prune pseudo legal moves for sliding pieces
        // based on diagonals, lines, etc if pinned
        var testSet = set
        testSet.remove(piece)

        var movedPiece = piece
        movedPiece.square = square
        testSet.add(movedPiece)

        return !isKingInCheck(piece.color, set: testSet)
    }

    /// Determines the positions of pieces that attack a given square.
    ///
    /// - parameter sq: A bitboard corresponding to the square of interest.
    /// - parameter set: The piece set for which to calculate attackers.
    /// - returns: A bitboard with the locations of the pieces in `set`
    /// that attack `sq`.
    ///
    private func attackers(
        to sq: Bitboard,
        set: PieceSet
    ) -> Bitboard {
        guard let square = Square(sq) else { return 0 }

        return kingAttacks[safe: sq] & set.kings
        | rookAttacks(from: square, occupancy: set.all) & set.lines
        | bishopAttacks(from: square, occupancy: set.all) & set.diagonals
        | knightAttacks[safe: sq] & set.knights
        | pawnCaptures(.white, from: sq, set: set) & set.P
        | pawnCaptures(.black, from: sq, set: set) & set.p
    }

    /// Determines if the king of the given piece color is in check.
    ///
    /// - parameter color: The color of the king.
    /// - parameter set: The set of pieces on the board.
    /// - returns: Whether or not the king with `color` is in check.
    ///
    private func isKingInCheck(_ color: Piece.Color, set: PieceSet) -> Bool {
        let us = set.get(color)
        let attacks = attackers(to: set.kings & us, set: set)

        return attacks & ~us != 0
    }

    // MARK: - Piece Attacks

    /// Non-capturing pawn moves.
    ///
    /// - parameter color: The color of the pawn.
    /// - parameter sq: A bitboard representing the square the pawn is currently on.
    /// - parameter set: The set of pieces active on the board.
    /// - returns: A bitboard of the possible non-capturing pawn moves.
    ///
    /// For the purposes of `Board`, en-passant is considered a non-capturing move.
    ///
    private func pawnMoves(
        _ color: Piece.Color,
        from sq: Bitboard,
        set: PieceSet
    ) -> Bitboard {
        let movement: (Int) -> Bitboard
        let isOnStartingRank: Bool

        switch color {
        case .white:
            movement = sq.north
            isOnStartingRank = sq & .rank1.north() != 0
        case .black:
            movement = sq.south
            isOnStartingRank = sq & .rank8.south() != 0
        }

        let singleMove = movement(1)

        var extraMove = Bitboard(0)
        if isOnStartingRank {
            extraMove = movement(2)
        }

        // to-do: implement en passant
        let enPassant = Bitboard(0)

        return singleMove | extraMove | enPassant
    }

    /// Capturing pawn moves.
    ///
    /// - parameter color: The color of the pawn.
    /// - parameter sq: A bitboard representing the square the pawn is currently on.
    /// - parameter set: The set of pieces active on the board.
    /// - returns: A bitboard of the possible capturing pawn moves.
    ///
    /// For the purposes of `Board`, en-passant is not considered a capturing move.
    ///
    private func pawnCaptures(
        _ color: Piece.Color,
        from sq: Bitboard,
        set: PieceSet
    ) -> Bitboard {
        switch color {
        case .white: (sq.northWest() | sq.northEast()) & set.black
        case .black: (sq.southWest() | sq.southEast()) & set.white
        }
    }

    /// The complete set of pawn moves, including capturing and non-capturing moves.
    ///
    /// - parameter color: The color of the pawn.
    /// - parameter sq: A bitboard representing the square the pawn is currently on.
    /// - parameter set: The set of pieces active on the board.
    /// - returns: A bitboard of the possible pawn moves.
    ///
    private func pawnAttacks(
        _ color: Piece.Color,
        from sq: Bitboard,
        set: PieceSet
    ) -> Bitboard {
        pawnMoves(color, from: sq, set: set) | pawnCaptures(color, from: sq, set: set)
    }

    /// Cached knight attack bitboards by square.
    private var knightAttacks: [Bitboard: Bitboard] { Attacks.knights }

    /// Returns cached bishop attack bitboards by square and occupancy.
    private func bishopAttacks(
        from square: Square,
        occupancy: Bitboard
    ) -> Bitboard {
        Attacks.bishops.attacks(from: square, for: occupancy)
    }

    /// Returns cached rook attack bitboards by square and occupancy.
    private func rookAttacks(
        from square: Square,
        occupancy: Bitboard
    ) -> Bitboard {
        Attacks.rooks.attacks(from: square, for: occupancy)
    }

    /// Returns cached queen attack bitboards by square and occupancy.
    private func queenAttacks(
        from square: Square,
        occupancy: Bitboard
    ) -> Bitboard {
        rookAttacks(from: square, occupancy: occupancy)
        | bishopAttacks(from: square, occupancy: occupancy)
    }

    /// Cached king attack bitboards by square.
    private var kingAttacks: [Bitboard: Bitboard] { Attacks.kings }

}
