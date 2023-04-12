//
//  ChessBoard.swift
//  ChessKit
//

public protocol BoardDelegate: AnyObject {
    func didPromote(with move: Move)
    func didEnd(with result: Board.EndResult)
}

/// Manages the state of the chess board and validates
/// legal moves and game rules.
///
public struct Board {
    
    // MARK: - Properties
    
    public weak var delegate: BoardDelegate?
    
    public var position: Position
    
    /// Specifies whether this board object is temporary.
    ///
    /// This should only be used internally to `Board` to
    /// create a temporary `Board` object to calculate alternate possible moves,
    /// e.g. when evaluating checks and checkmates or disambiguating moves.
    ///
    private var isTemporary: Bool
    
    // MARK: - Initializer
    
    public init(position: Position = .standard) {
        self.position = position
        isTemporary = false
    }
    
    private init(position: Position, isTemporary: Bool) {
        self.position = position
        self.isTemporary = isTemporary
    }
    
    // MARK: - Moves
    
    @discardableResult
    public mutating func move(pieceAt start: Square, to end: Square) -> Move? {
        guard let piece = position.piece(at: start), canMove(piece: piece, to: end) else {
            return nil
        }
        
        // en passant
        
        if piece.kind == .pawn, let enPassant = position.enPassant,
           enPassant.pawn.color == piece.color.opposite,
           end == enPassant.captureSquare {
            position.remove(enPassant.pawn)
            position.move(piece, to: end)
            return process(move: Move(result: .capture(enPassant.pawn), piece: piece, start: start, end: end))
        } else {
            position.enPassant = nil     // prevent en passant on next turn
        }
        
        // castling
        
        if piece.kind == .king {
            let castles = Castling.Side.allCases
                .map { Castling(side: $0, color: piece.color) }
                .compactMap {
                    (castling: Castling) -> Move? in
                    
                    if canCastle(piece, castling: castling) && end == castling.kingEnd {
                        if let rook = position.piece(at: castling.rookStart) {
                            position.move(rook, to: castling.rookEnd)
                        }
                        
                        position.move(piece, to: end)
                        return Move(result: .castle(castling), piece: piece, start: start, end: end)
                    } else {
                        return nil
                    }
                }
            
            if let castle = castles.first {
                return process(move: castle)
            }
        }
        
        // captures & moves
        
        if let endPiece = position.piece(at: end), endPiece.color == piece.color.opposite {
            let move = disambiguate(move: Move(result: .capture(endPiece), piece: piece, start: start, end: end), in: position)
            
            position.remove(endPiece)
            position.move(piece, to: end)
            position.resetHalfmoveClock()
            
            return process(move: move)
        } else {
            let previousPosition = position
            
            guard let updatedPiece = position.move(piece, to: end) else {
                return nil
            }
            
            let move = disambiguate(move: Move(result: .move, piece: updatedPiece, start: start, end: end), in: previousPosition)
            
            if updatedPiece.kind == .pawn {
                position.resetHalfmoveClock()
                
                if abs(start.rank.value - end.rank.value) == 2 {
                    position.enPassant = EnPassant(pawn: updatedPiece)
                }
            }
            
            return process(move: move)
        }
    }
    
    // MARK: - Move legality checking
    
    public func canMove(pieceAt square: Square, to newSquare: Square) -> Bool {
        if let piece = position.piece(at: square) {
            return canMove(piece: piece, to: newSquare)
        } else {
            return false
        }
    }
    
    private func canMove(piece: Piece, to square: Square) -> Bool {
        legalMoves(for: piece).contains(square)
    }
    
    private func legalMoves(for piece: Piece) -> [Square] {
        var moves: [Square]
        
        switch piece.kind {
        case .pawn:     moves = legalPawnMoves(for: piece)
        case .bishop:   moves = legalBishopMoves(for: piece)
        case .knight:   moves = legalKnightMoves(for: piece)
        case .rook:     moves = legalRookMoves(for: piece)
        case .queen:    moves = legalQueenMoves(for: piece)
        case .king:     moves = legalKingMoves(for: piece, ignoringCastling: isTemporary)
        }
        
        if !isTemporary {
            moves = moves.filter {
                !willBeInCheck(kingColor: piece.color, moving: piece, to: $0)
            }
        }
        
        return moves.filter {
            piece.color != position.piece(at: $0)?.color
        }
    }
    
    public func legalMoves(forPieceAt square: Square) -> [Square] {
        if let piece = position.piece(at: square) {
            return legalMoves(for: piece)
        } else {
            return []
        }
    }
    
    // MARK: - Board calculations
    
    /// - returns: Distance from `square` to the edge of the board in `direction`.
    private func boardEdgeDistance(from square: Square, direction op: BoardOperation) -> Int {
        ((Square.Rank.range.lowerBound...(Square.Rank.range.upperBound - 1))
            .first { op(square, $0) == op(square, $0 - 1) }
            ?? Square.Rank.range.upperBound
        ) - 1
    }
    
    /// - returns: Spaces away from `square` in `direction` until a piece occupies space
    /// or edge of board is reached (up to maximum distance of 7).
    private func seek(from square: Square, direction op: BoardOperation) -> Int {
        let boardEdge = boardEdgeDistance(from: square, direction: op)
        guard boardEdge >= 1 else { return 0 }
        
        return (1...boardEdge).first {
            position.piece(at: op(square, $0)) != nil
        } ?? boardEdge
    }
    
    enum PieceVision {
        case one
        case unlimited
    }
    
    private func legalMoves(for piece: Piece, in directions: [BoardOperation], vision: PieceVision) -> [Square] {
        directions
            .flatMap { (d: BoardOperation) -> [Square] in
                switch vision {
                case .one:
                    return [d(piece.square, 1)]
                case .unlimited:
                    let s = seek(from: piece.square, direction: d)
                    return s >= 1 ? (1...s).map { d(piece.square, $0) } : []
                }
            }
    }
    
    // MARK: - Legal moves by piece
    
    private func legalPawnMoves(for piece: Piece) -> [Square] {
        var startingRank: Square.Rank
        var movementOp: (Square, Int) -> Square
        var captureOps: [(Square, Int) -> Square]
        
        switch piece.color {
        case .white:
            startingRank = 2
            movementOp = (↑)
            captureOps = [(↖), (↗)]
        case .black:
            startingRank = 7
            movementOp = (↓)
            captureOps = [(↙), (↘)]
        }
        
        let pawnMove = movementOp(piece.square, 1)
        var extraPawnMove: Square?
        var captures: [Square] = []
        
        let seekAhead = seek(from: piece.square, direction: movementOp)
        
        if piece.square.rank == startingRank && seekAhead > 1 {
            extraPawnMove = movementOp(pawnMove, 1)
        }
        
        captures = captureOps
            .map { $0(piece.square, 1) }
            .filter { position.piece(at: $0) != nil && position.piece(at: $0)?.color != piece.color }
        
        var enPassantMove: Square?
        
        if let enPassant = position.enPassant, enPassant.canBeCaptured(by: piece) {
            enPassantMove = enPassant.captureSquare
        }
        
        return [pawnMove, extraPawnMove, enPassantMove]
            .compactMap { $0 }
            .filter { position.piece(at: $0) == nil }
            + captures
    }
    
    private func legalKnightMoves(for piece: Piece) -> [Square] {
        [kNNE, kENE, kESE, kSSE, kSSW, kWSW, kWNW, kNNW]
            .compactMap { $0(piece.square) }
    }
    
    private func legalBishopMoves(for piece: Piece) -> [Square] {
        legalMoves(for: piece, in: [(↗), (↖), (↘), (↙)], vision: .unlimited)
    }
    
    private func legalRookMoves(for piece: Piece) -> [Square] {
        legalMoves(for: piece, in: [(↑), (↓), (←), (→)], vision: .unlimited)
    }
    
    private func legalQueenMoves(for piece: Piece) -> [Square] {
        legalBishopMoves(for: piece) + legalRookMoves(for: piece)
    }
    
    private func legalKingMoves(for piece: Piece, ignoringCastling: Bool = false) -> [Square] {
        let standardMoves = legalMoves(
            for: piece, in: [(↗),(↖),(↙),(↘),(↑),(↓),(←),(→)],
            vision: .one
        )
        
        guard !ignoringCastling else { return standardMoves }
        
        var castleMoves = [Square]()
        
        let kingSide = Castling(side: .king, color: piece.color)
        if canCastle(piece, castling: kingSide) {
            castleMoves.append(kingSide.kingEnd)
        }
        
        let queenSide = Castling(side: .queen, color: piece.color)
        if canCastle(piece, castling: queenSide) {
            castleMoves.append(queenSide.kingEnd)
        }
        
        return castleMoves + standardMoves
    }
    
    // MARK: - Castling
    
    private func canCastle(_ king: Piece, castling: Castling) -> Bool {
        guard king.kind == .king,
              king.square == castling.kingStart,
              castling.squares.allSatisfy({ position.piece(at: $0) == nil && !isInCheck(kingColor: king.color, at: $0) }),
              let rook = position.piece(at: castling.rookStart),
              rook.kind == .rook else {
            return false
        }
        
        return position.legalCastlings.contains(castling) &&
            !isInCheck(kingColor: king.color)
    }
    
    // MARK: - Checks
    
    private func willBeInCheck(
        kingColor: Piece.Color,
        moving piece: Piece,
        to end: Square
    ) -> Bool {
        var temporaryBoard = Board(position: position, isTemporary: true)
        temporaryBoard.move(pieceAt: piece.square, to: end)
        return temporaryBoard.isInCheck(kingColor: kingColor)
    }
    
    private func isInCheck(
        kingColor: Piece.Color,
        at square: Square? = nil
    ) -> Bool {
        let squareToCheck: Square?
        
        if let square {
            squareToCheck = square
        } else {
            squareToCheck = position.pieces.filter { $0.kind == .king && $0.color == kingColor }.first?.square
        }
        
        guard let unwrappedSquare = squareToCheck else { return false }
        let temporaryBoard = Board(position: position, isTemporary: true)
        
        return position.pieces
            .filter { $0.color == kingColor.opposite }
            .map {
                temporaryBoard.legalMoves(for: $0).contains(unwrappedSquare)
            }
            .contains(true)
    }
    
    // MARK: - Process moves
    
    private func process(move: Move) -> Move {
        var processedMove = move
        
        // checks & mates
        if !isTemporary {
            let checkState = self.checkState(for: move.piece.color.opposite)
            processedMove.checkState = checkState
            
            if checkState == .checkmate {
                delegate?.didEnd(with: .win(move.piece.color))
            } else if checkState == .stalemate {
                delegate?.didEnd(with: .draw(.stalemate))
            } else if position.clock.halfmoves >= Clock.halfMoveMaximum {
                delegate?.didEnd(with: .draw(.fiftyMoves))
            }
            
            // pawn promotion
            if move.piece.kind == .pawn {
                if (move.end.rank == 8 && move.piece.color == .white) ||
                    (move.end.rank == 1 && move.piece.color == .black) {
                    delegate?.didPromote(with: move)
                }
            }
        }
        
        return processedMove
    }
    
    private func disambiguate(move: Move, in position: Position) -> Move {
        guard !isTemporary else { return move }
        let piece = move.piece
        let temporaryBoard = Board(position: position, isTemporary: true)
        
        let ambiguousPieces = position.pieces
            .filter { ![.pawn, .king].contains($0.kind) }
            .filter { $0.kind == piece.kind && $0.color == piece.color }
            .filter { temporaryBoard.canMove(piece: $0, to: move.end) }
            .filter { $0.square != move.start } // filter piece making the move
        
        if ambiguousPieces.isEmpty {
            return move
        } else {
            var newMove = move
            
            if ambiguousPieces.allSatisfy({ $0.square.file != move.start.file }) {
                newMove.disambiguation = .byFile(move.start.file)
            } else if ambiguousPieces.allSatisfy({ $0.square.rank != move.start.rank }) {
                newMove.disambiguation = .byRank(move.start.rank)
            } else {
                newMove.disambiguation = .bySquare(move.start)
            }
            
            return newMove
        }
    }
    
    @discardableResult
    public mutating func completePromotion(of move: Move, to kind: Piece.Kind) -> Move {
        let promotedPiece = Piece(kind, color: move.piece.color, square: move.end)
        
        var updatedMove = move
        updatedMove.promotedPiece = promotedPiece
        
        position.promote(pieceAt: move.end, to: kind)
        
        return process(move: updatedMove)
    }
    
    private func checkState(for color: Piece.Color) -> Move.CheckState {
        let legalMoves = position.pieces
            .filter { $0.color == color }
            .flatMap { self.legalMoves(for: $0) }
        
        if isInCheck(kingColor: color) {
            return legalMoves.isEmpty ? .checkmate : .check
        } else {
            return legalMoves.isEmpty ? .stalemate : .none
        }
    }
    
    public enum EndResult: Equatable {
        case win(Piece.Color), draw(DrawType)
        
        public enum DrawType: String {
            case agreement
            case insufficientMaterial
            case fiftyMoves
            case repitition
            case stalemate
        }
    }
    
}
