//
//  ChessMove.swift
//  ChessKit
//

public struct Move: Equatable, Hashable {
    
    /// The result of the move.
    public enum Result: Equatable, Hashable {
        case move
        case capture(Piece)
        case castle(Castling)
    }
    
    /// The check state resulting from the move.
    public enum CheckState: String {
        case none
        case check
        case checkmate
        case stalemate
        
        var notation: String {
            switch self {
            case .none, .stalemate: return ""
            case .check:            return "+"
            case .checkmate:        return "#"
            }
        }
    }
    
    /// Rank, file, or square disambiguation of moves.
    public enum Disambiguation: Equatable, Hashable {
        case byFile(Square.File)
        case byRank(Square.Rank)
        case bySquare(Square)
    }
    
    /// The result of the move.
    public internal(set) var result: Result
    /// The piece that made the move.
    public internal(set) var piece: Piece
    /// The starting square of the move.
    public internal(set) var start: Square
    /// The ending square of the move.
    public internal(set) var end: Square
    /// The piece that was promoted to, if applicable.
    public internal(set) var promotedPiece: Piece?
    /// The move disambiguation, if applicable.
    var disambiguation: Disambiguation?
    /// The check state resulting from the move.
    var checkState: CheckState
    /// The move assessment annotation.
    public var assessment: Assessment
    /// The comment associated with a move.
    public var comment: String
    
    /// Initialize a move with the given characteristics.
    public init(
        result: Result,
        piece: Piece,
        start: Square,
        end: Square,
        checkState: CheckState = .none,
        assessment: Assessment = .null,
        comment: String = ""
    ) {
        self.result = result
        self.piece = piece
        self.start = start
        self.end = end
        self.checkState = checkState
        self.assessment = assessment
        self.comment = comment
    }
    
    /// Initialize a move with a given SAN string.
    ///
    /// This initializer fails if the provided SAN string is invalid.
    public init?(san: String, color: Piece.Color, position: Position) {
        guard let move = SANParser.parse(move: san, in: position) else {
            return nil
        }
        
        self = move
    }
    
    /// The SAN represenation of the move.
    public var san: String {
        SANParser.convert(move: self)
    }
    
    /// The engine LAN represenation of the move.
    ///
    /// NOTE: This is intended for engine communication
    /// so piece names, capture/check indicators, etc. are not included.
    public var lan: String {
        EngineLANParser.convert(move: self)
    }
    
}

extension Move {
    
    /// Single move assessments.
    ///
    /// The raw String value corresponds to what is displayed
    /// in a PGN string.
    public enum Assessment: String {
        case null = "$0"
        case good = "$1"
        case mistake = "$2"
        case brilliant = "$3"
        case blunder = "$4"
        case interesting = "$5"
        case dubious = "$6"
        case forced = "$7"
        case singular = "$8"
        case worst = "$9"
        
        /// The human-readable move assessment notation.
        public var notation: String {
            switch self {
            case .null:         return ""
            case .good:         return "!"
            case .mistake:      return "?"
            case .brilliant:    return "!!"
            case .blunder:      return "??"
            case .interesting:  return "!?"
            case .dubious:      return "?!"
            case .forced:       return "□"
            case .singular:     return ""
            case .worst:        return ""
            }
        }
    }
    
}
