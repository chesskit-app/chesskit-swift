//
//  SANParser.swift
//  ChessKit
//

/// Parses and converts the Standard Algebraic Notation (SAN)
/// of a chess move.
public class SANParser {
    
    private init() {}
    
    /// Parses a SAN string and returns a move.
    ///
    /// - parameter san: The SAN string of a move.
    /// - parameter position: The current chess position to make the move from.
    /// - returns: A Swift representation of a move, or `nil` if the
    ///     SAN is invalid.
    ///
    /// Make sure the provided `position` has the correct `sideToMove`
    /// set or the parsing may fail due to invalid moves.
    public static func parse(
        move san: String,
        in position: Position
    ) -> Move? {
        guard isValid(san: san) else { return nil }
        
        let color = position.sideToMove
        var checkstate = Move.CheckState.none
        
        if san.contains("#") {
            checkstate = .checkmate
        } else if san.contains("+") {
            checkstate = .check
        }
        
        // castling
        var castling: Castling?
        
        if san.range(of: Regex.shortCastle, options: .regularExpression) != nil {
            castling = Castling(side: .king, color: color)
        } else if san.range(of: Regex.longCastle, options: .regularExpression) != nil {
            castling = Castling(side: .queen, color: color)
        }
        
        if let castling {
            return Move(
                result: .castle(castling),
                piece: Piece(.king, color: color, square: castling.kingStart),
                start: castling.kingStart,
                end: castling.kingEnd,
                checkState: checkstate
            )
        }
        
        // pawns
        if let range = san.range(of: Regex.pawnFile, options: .regularExpression), let end = targetSquare(for: san) {
            let startingFile = String(san[range])
            
            let board = Board(position: position)
            let possiblePiece = position.pieces
                .filter {
                    $0.kind == .pawn && $0.color == color && $0.square.file == Square.File(rawValue: startingFile)
                }
                .filter {
                    board.canMove(pieceAt: $0.square, to: end)
                }
                .first
            
            guard var pawn = possiblePiece else {
                return nil
            }
            
            let start = pawn.square
            pawn.square = end
            
            var move: Move
            
            if isCapture(san: san), let capturedPiece = position.piece(at: end) {
                move = Move(result: .capture(capturedPiece), piece: pawn, start: start, end: capturedPiece.square, checkState: checkstate)
            } else {
                move = Move(result: .move, piece: pawn, start: start, end: end, checkState: checkstate)
            }
            
            if let promotionPieceKind = promotionPiece(for: san) {
                move.promotedPiece = Piece(promotionPieceKind, color: color, square: end)
            }
            
            return move
        }
        
        // pieces
        if let range = san.range(of: Regex.pieceKind, options: .regularExpression) {
            if let pieceKind = Piece.Kind(rawValue: String(san[range])),
               let end = targetSquare(for: san) {
                var move: Move?
                let disambiguation = self.disambiguation(for: san)
                
                let board = Board(position: position)
                let possiblePiece = position.pieces
                    .filter { $0.kind == pieceKind && $0.color == color }
                    .filter {
                        board.canMove(pieceAt: $0.square, to: end)
                    }
                    .filter {
                        switch disambiguation {
                        case let .byFile(file):
                            return $0.square.file == file
                        case let .byRank(rank):
                            return $0.square.rank == rank
                        case let .bySquare(square):
                            return $0.square == square
                        case .none:
                            return true
                        }
                    }
                    .first
                
                guard var piece = possiblePiece else {
                    return nil
                }
                
                let start = piece.square
                piece.square = end
                
                if isCapture(san: san), let capturedPiece = position.piece(at: end) {
                    move = Move(result: .capture(capturedPiece), piece: piece, start: start, end: end, checkState: checkstate)
                } else {
                    move = Move(result: .move, piece: piece, start: start, end: end, checkState: checkstate)
                }
                
                move?.disambiguation = disambiguation
                
                return move
            }
        }
        
        return nil
    }
    
    /// Converts a ``Move`` object into a SAN string.
    ///
    /// - parameter move: The chess move to convert.
    /// - returns: A string containing the SAN of `move`.
    ///
    public static func convert(move: Move) -> String {
        switch move.result {
        case let .castle(castling):
            return "\(castling.side.notation)\(move.checkState.notation)"
        default:
            var pieceNotation = move.piece.kind.notation
            
            if move.piece.kind == .pawn, case .capture = move.result {
                pieceNotation = move.start.file.rawValue
            }
            
            var disambiguationNotation = ""
            
            if let disambiguation = move.disambiguation {
                switch disambiguation {
                case let .byFile(file): disambiguationNotation = file.rawValue
                case let .byRank(rank): disambiguationNotation = "\(rank.value)"
                case let .bySquare(square): disambiguationNotation = square.notation
                }
            }
            
            var captureNotation = ""
            
            if case .capture = move.result {
                captureNotation = "x"
            }
            
            var promotionNotation = ""
            
            if let promotedPiece = move.promotedPiece {
                promotionNotation = "=\(promotedPiece.kind.notation)"
            }
            
            return "\(pieceNotation)\(disambiguationNotation)\(captureNotation)\(move.end.notation)\(promotionNotation)\(move.checkState.notation)"
        }
    }
    
    // MARK: - Private
    
    /// Returns whether the provided SAN is valid.
    ///
    /// - parameter san: The SAN string to check.
    /// - returns: Whether the SAN is valid.
    ///
    private static func isValid(san: String) -> Bool {
        san.range(of: SANParser.Regex.full, options: .regularExpression) != nil
    }
    
    /// Returns the target square for a SAN move.
    ///
    /// - parameter san: The SAN represenation of a move.
    /// - returns: The square the move is targeting, or `nil`
    ///     if the SAN is invalid.
    ///
    private static func targetSquare(for san: String) -> Square? {
        if let range = san.range(of: Regex.targetSquare, options: .regularExpression) {
            return Square(String(san[range]))
        } else {
            return nil
        }
    }
    
    /// Checks if a SAN string contains a capture.
    ///
    /// - parameter san: The SAN represenation of a move.
    /// - returns: Whether or not the move represents a capture.
    ///
    private static func isCapture(san: String) -> Bool {
        san.contains("x")
    }
    
    /// Checks if a SAN string contains a promotion.
    ///
    /// - parameter san: The SAN represenation of a move.
    /// - returns: The kind of piece that is being promoted to,
    ///     or `nil` if the SAN does not contain a promotion.
    ///
    private static func promotionPiece(for san: String) -> Piece.Kind? {
        guard let range = san.range(of: Regex.promotion, options: .regularExpression) else {
            return nil
        }
        
        return Piece.Kind(
            rawValue: san[range].replacingOccurrences(of: "=", with: "")
        )
    }
    
    /// Checks if a SAN string contains a disambiguation.
    ///
    /// - parameter san: The SAN represenation of a move.
    /// - returns: The disambiguation contained within the SAN,
    ///     or `nil` if there is none.
    ///
    /// If multiple pieces of the same type can move to the target
    /// square, the SAN contains a disambiguating file, rank, or square
    /// so the piece that is moving can be determined.
    private static func disambiguation(for san: String) -> Move.Disambiguation? {
        guard let range = san.range(of: Regex.disambiguation, options: .regularExpression) else {
            return nil
        }
        
        let value = String(san[range])
        
        if let rankRange = value.range(of: Regex.rank, options: .regularExpression), let rank = Int(String(value[rankRange])) {
            return .byRank(Square.Rank(rank))
        } else if let fileRange = value.range(of: Regex.file, options: .regularExpression), let file = Square.File(rawValue: String(value[fileRange])) {
            return .byFile(file)
        } else if let squareRange = value.range(of: Regex.square, options: .regularExpression) {
            return .bySquare(Square(String(value[squareRange])))
        } else {
            return nil
        }
    }
    
}
