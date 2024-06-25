//
//  Position.swift
//  ChessKit
//

/// Represents the collection of pieces on the chess board.
public struct Position: Equatable {

    /// The pieces currently existing on the board in this position.
    public var pieces: [Piece] {
        pieceSet.pieces
    }

    /// Bitboard-based piece set used to manage piece positions.
    private(set) var pieceSet: PieceSet

    /// The side that is set to move next.
    public private(set) var sideToMove: Piece.Color

    /// Legal castlings based on position only (does not take into account checks, etc.
    ///
    /// This array only contains castlings that are legal based on whether
    /// or not the king(s) and rook(s) have moved.
    var legalCastlings: LegalCastlings

    /// Contains information about a pawn that can be captured by en passant.
    ///
    /// This property is `nil` if there is no pawn capable of being captured by
    /// en passant.
    var enPassant: EnPassant?

    /// Keeps track of the number of moves in a game for the current position.
    public private(set) var clock: Clock

    /// Initialize a position with a given array of pieces and characteristics.
    init(
        pieces: [Piece],
        sideToMove: Piece.Color = .white,
        legalCastlings: LegalCastlings = LegalCastlings(),
        enPassant: EnPassant? = nil,
        clock: Clock = Clock()
    ) {
        self.pieceSet = .init(pieces: pieces)
        self.sideToMove = sideToMove
        self.legalCastlings = legalCastlings
        self.enPassant = enPassant
        self.clock = clock
    }

    /// Initialize a move with a provided FEN string.
    ///
    /// This initializer fails if the provided FEN string is invalid.
    public init?(fen: String) {
        guard let parsed = FENParser.parse(fen: fen) else {
            return nil
        }

        self = parsed
    }

    /// Toggle the current side to move.
    private mutating func _toggleSideToMove() {
        sideToMove.toggle()
    }

    /// Toggle the current side to move.
    @available(*, deprecated, message: "This function no longer has any effect. `sideToMove` is toggled automatically as needed.")
    public mutating func toggleSideToMove() {

    }

    /// Provides the chess piece located at the given square.
    ///
    /// - parameter square: The square of the board to query for a piece.
    /// - returns: The piece located at `square`, or `nil` if the square is empty.
    ///
    public func piece(at square: Square) -> Piece? {
        pieceSet.get(square)
    }

    /// Moves the given piece to the given square.
    ///
    /// - parameter piece: The piece to move in this position.
    /// - parameter end: The square that `piece` should be moved to.
    /// - returns: The updated piece containing the final square as its location, or `nil` if the given piece was not found in this position.
    ///
    /// - warning: Do not use this function to perform castling moves.
    /// To castle a king and rook, call `castle(_:)`.
    ///
    @discardableResult
    mutating func move(_ piece: Piece, to end: Square, updateClockAndSideToMove: Bool = true) -> Piece? {
        guard pieceSet.get(piece.square) != nil else { return nil }

        legalCastlings.invalidateCastling(for: piece)
        pieceSet.move(piece, to: end)

        if updateClockAndSideToMove {
            clock.halfmoves += 1

            if piece.color == .black {
                clock.fullmoves += 1
            }

            _toggleSideToMove()
        }

        return pieceSet.get(end)
    }

    /// Moves the given piece to the given square.
    ///
    /// - parameter castling: The castling object contain associated king and rook square information.
    /// - returns: The updated king piece containing the final square as its location, or `nil` if the given piece was not found in this position.
    ///
    /// This function assumes castling is valid for the provided `castling`. If the the king move is
    /// valid, it will be performed whether or not there is actually a piece on the `rookStart` square.
    ///
    /// - Note: The rook will only be moved if the king move succeeds.
    ///
    @discardableResult
    mutating func castle(_ castling: Castling) -> Piece? {
        let kingMove = move(pieceAt: castling.kingStart, to: castling.kingEnd)

        defer {
            if kingMove != nil {
                move(pieceAt: castling.rookStart, to: castling.rookEnd, updateClockAndSideToMove: false)
            }
        }

        return kingMove
    }

    /// Moves a piece from one square to another.
    ///
    /// - parameter start: The square where the piece is currently located.
    /// - parameter end: The square that `piece` should be moved to.
    /// - returns: The updated piece containing the final square as its location, or `nil` if the given piece was not found in this position.
    ///
    @discardableResult
    mutating func move(pieceAt start: Square, to end: Square, updateClockAndSideToMove: Bool = true) -> Piece? {
        guard let piece = pieceSet.get(start) else {
            return nil
        }

        return move(piece, to: end, updateClockAndSideToMove: updateClockAndSideToMove)
    }

    /// Removes the given piece from the position.
    ///
    /// - parameter piece: The piece to remove from the position.
    ///
    /// If the piece is not currently located in the position, this method has no effect.
    mutating func remove(_ piece: Piece) {
        pieceSet.remove(piece)
    }

    /// Promotes a pawn at the given square to the given piece type.
    ///
    /// - parameter square: The square on which the pawn should be promoted.
    /// - parameter kind: The type of piece to promote to.
    ///
    /// If a piece is not found at the given square, this method has no effect.
    /// This method contains no logic to determine if the piece can be legally
    /// promoted, and such checks should be done before calling this method.
    mutating func promote(pieceAt square: Square, to kind: Piece.Kind) {
        guard let piece = pieceSet.get(square) else { return }
        pieceSet.replace(kind, for: piece)
    }

    /// Resets the halfmove counter in the `Clock`.
    ///
    /// This should be used whenenever a pawn is moved or a capture is made.
    mutating func resetHalfmoveClock() {
        clock.halfmoves = 0
    }

    /// Indicates whether the current position has insufficient material.
    public var hasInsufficientMaterial: Bool {
        let set = pieceSet
        let pawnsRooksQueens = set.pawns | set.rooks | set.queens

        if pawnsRooksQueens == 0 {
            if set.all.nonzeroBitCount <= 3 {
                // 3 pieces in this scenario means two kings and either
                // 1 bishop or 1 knight, i.e. insufficient material
                return true
            } else {
                // check if no knights and all bishops
                // are on the same color square, i.e. insufficient material
                let allBLight = set.bishops & .dark == 0 // all bishops on light squares
                let allBDark = set.bishops & .light == 0 // all bishops on dark squares

                return set.knights == 0 && (allBLight || allBDark)
            }
        } else {
            // not insufficient material if pawns, rooks, or queens
            // are on the board
            return false
        }
    }
    
    /// Checks if a position already occurred N times
    ///
    ///   - parameter times: the times the position occurred
    ///   - parameter positions: all the positions occurred during the game
    /// - Returns: a bool stating if the position already occurred N times
    public func occurred(times: Int, in positions: [Int:Int]) -> Bool {
        if positions[hashed] == times {
            return true
        }
        
        return false
    }
    
    /// The FEN represenation of the position.
    public var fen: String {
        FENParser.convert(position: self)
    }

}

extension Position {
    /// A random chess position that can be used for testing.
    public static let test = Position(pieces: [
        Piece(.pawn,   color: .black, square: .c3),
        Piece(.bishop, color: .black, square: .f4),
        Piece(.rook,   color: .black, square: .a6),
        Piece(.knight, color: .black, square: .e6),
        Piece(.king,   color: .black, square: .h8),
        Piece(.pawn,   color: .white, square: .b2),
        Piece(.queen,  color: .white, square: .d5),
        Piece(.king,   color: .white, square: .g3)
    ])

    /// The standard starting chess position.
    public static let standard = Position(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")!
}

extension Position: CustomStringConvertible {

    public var description: String {
        String(describing: pieceSet)
    }

}
