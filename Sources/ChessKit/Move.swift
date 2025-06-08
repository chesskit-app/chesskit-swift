//
//  ChessMove.swift
//  ChessKit
//

/// Represents a move on a chess board.
public struct Move: Hashable, Sendable {

  /// The result of the move.
  public enum Result: Hashable, Sendable {
    case move
    case capture(Piece)
    case castle(Castling)
  }

  /// The check state resulting from the move.
  public enum CheckState: String, Sendable {
    case none
    case check
    case checkmate
    case stalemate

    var notation: String {
      switch self {
      case .none, .stalemate: ""
      case .check: "+"
      case .checkmate: "#"
      }
    }
  }

  /// Rank, file, or square disambiguation of moves.
  public enum Disambiguation: Hashable, Sendable {
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
  public internal(set) var disambiguation: Disambiguation?
  /// The check state resulting from the move.
  public internal(set) var checkState: CheckState
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
  public init?(san: String, position: Position) {
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
  /// - note: This is intended for engine communication
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
  public enum Assessment: String, Sendable {
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
      case .null: ""
      case .good: "!"
      case .mistake: "?"
      case .brilliant: "!!"
      case .blunder: "??"
      case .interesting: "!?"
      case .dubious: "?!"
      case .forced: "□"
      case .singular: ""
      case .worst: ""
      }
    }

    public init?(notation: String) {
      switch notation {
      case "": self = .null
      case "!": self = .good
      case "?": self = .mistake
      case "!!": self = .brilliant
      case "??": self = .blunder
      case "!?": self = .interesting
      case "?!": self = .dubious
      case "□": self = .forced
      default: return nil
      }
    }
  }

}

// MARK: - CustomStringConvertible
extension Move: CustomStringConvertible {
  public var description: String {
    san
  }
}
