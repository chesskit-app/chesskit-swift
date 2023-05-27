//
//  Position.swift
//  ChessKit
//

/// Represents the collection of pieces on the chess board.
public struct Position: Equatable {
    
    /// The pieces currently existing on the board in this position.
    public internal(set) var pieces: [Piece]
    
    /// The side that is set to move next.
    public internal(set) var sideToMove: Piece.Color
    
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
        self.pieces = pieces
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
    ///
    public mutating func toggleSideToMove() {
        sideToMove = sideToMove.opposite
    }
    
    /// Provides the chess piece located at the given square.
    ///
    /// - parameter square: The square of the board to query for a piece.
    /// - returns: The piece located at `square`, or `nil` if the square is empty.
    ///
    public func piece(at square: Square) -> Piece? {
        pieces.filter { $0.square == square }.first
    }
    
    /// Moves the given piece to the given square.
    ///
    /// - parameter piece: The piece to move in this position.
    /// - parameter end: The square that `piece` should be moved to.
    /// - returns: The updated piece containing the final square as its location, or `nil` if the given piece was not found in this position.
    ///
    @discardableResult
    mutating func move(_ piece: Piece, to end: Square) -> Piece? {
        guard let index = pieces.firstIndex(where: { $0 == piece }) else { return nil }
        
        legalCastlings.invalidateCastling(for: piece)
        pieces[index].square = end
        
        clock.halfmoves += 1
        
        if piece.color == .black {
            clock.fullmoves += 1
        }
        
        return pieces[index]
    }
    
    /// Moves a piece from one square to another.
    ///
    /// - parameter start: The square where the piece is currently located.
    /// - parameter end: The square that `piece` should be moved to.
    /// - returns: The updated piece containing the final square as its location, or `nil` if the given piece was not found in this position.
    ///
    @discardableResult
    mutating func move(pieceAt start: Square, to end: Square) -> Piece? {
        guard let piece = pieces.filter({ $0.square == start }).first else {
            return nil
        }
        
        return move(piece, to: end)
    }
    
    /// Removes the given piece from the position.
    ///
    /// - parameter piece: The piece to remove from the position.
    ///
    /// If the piece is not currently located in the position, this method has no effect.
    ///
    mutating func remove(_ piece: Piece) {
        pieces.removeAll { $0 == piece }
    }
    
    /// Promotes a pawn at the given square to the given piece type.
    ///
    /// - parameter square: The square on which the pawn should be promoted.
    /// - parameter kind: The type of piece to promote to.
    ///
    /// If a piece is not found at the given square, this method has no effect.
    /// This method contains no logic to determine if the piece can be legally
    /// promoted, and such checks should be done before calling this method.
    ///
    mutating func promote(pieceAt square: Square, to kind: Piece.Kind) {
        guard let index = pieces.firstIndex(where: { $0.square == square }) else { return }
        pieces[index].kind = kind
    }
    
    /// Resets the halfmove counter in the `Clock`.
    ///
    /// This should be used whenenever a pawn is moved or a capture is made.
    mutating func resetHalfmoveClock() {
        clock.halfmoves = 0
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
