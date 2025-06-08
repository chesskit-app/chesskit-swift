//
//  LANParser.swift
//  ChessKit
//

/// Parses and converts the Long Algebraic Notation (LAN)
/// of a chess move used by chess engines.
///
/// This notation omits the piece type and any indication
/// for special move types such as captures, castling, checks, etc.
///
/// Examples:
/// - e2e4
/// - e7e5
/// - e1g1 (white short castling)
/// - e7e8q (for promotion)
///
/// See [UCI protocol documentation](https://backscattering.de/chess/uci/2006-04.txt)
/// for more information.
public enum EngineLANParser {

  // MARK: Public

  /// Parses a LAN string and returns a move.
  ///
  /// - parameter lan: The (engine) LAN string of a move.
  /// - parameter color: The color of the piece being moved.
  /// - parameter position: The current chess position to make the move from.
  /// - returns: A Swift representation of a move, or `nil` if the
  ///     LAN is invalid.
  ///
  /// This parser does not look for checks or checkmates,
  /// i.e. the move's `checkState` will always be `.none`.
  public static func parse(
    move lan: String,
    for color: Piece.Color,
    in position: Position
  ) -> Move? {
    guard isValid(lan: lan) else { return nil }

    let startSquareIndex = lan.index(lan.startIndex, offsetBy: 2)
    let startSquareString = String(lan[..<startSquareIndex])
    let start = Square(startSquareString)

    let endSquareIndex = lan.index(startSquareIndex, offsetBy: 2)
    let endSquareString = String(lan[startSquareIndex..<endSquareIndex])
    let end = Square(endSquareString)

    var promotedPiece: Piece?

    if lan.count == 5,
      let pieceString = lan.last?.uppercased(),
      let pieceKind = Piece.Kind(rawValue: pieceString)
    {
      promotedPiece = .init(pieceKind, color: color, square: end)
    }

    let board = Board(position: position)

    guard
      board.canMove(pieceAt: start, to: end),
      let piece = position.piece(at: start)
    else {
      return nil
    }

    var moveResult: Move.Result

    if let capturedPiece = position.piece(at: end) {
      moveResult = .capture(capturedPiece)
    } else if let castling = Castling(engineLAN: lan) {
      moveResult = .castle(castling)
    } else {
      moveResult = .move
    }

    var move = Move(
      result: moveResult,
      piece: piece,
      start: start,
      end: end,
      checkState: .none
    )

    move.promotedPiece = promotedPiece
    return move
  }

  /// Converts a ``Move`` object into an engine LAN string.
  ///
  /// - parameter move: The chess move to convert.
  /// - returns: A string containing the engine LAN of `move`.
  ///
  public static func convert(move: Move) -> String {
    move.start.notation + move.end.notation + (move.promotedPiece?.fen.lowercased() ?? "")
  }

  // MARK: Private

  /// Returns whether the provided engine LAN is valid.
  ///
  /// - parameter lan: The LAN string to check.
  /// - returns: Whether the LAN is valid.
  ///
  private static func isValid(lan: String) -> Bool {
    lan.range(of: EngineLANParser.Pattern.move, options: .regularExpression) != nil
  }

}

private extension Castling {

  init?(engineLAN: String) {
    switch engineLAN {
    case "e1g1": self = .wK
    case "e1c1": self = .wQ
    case "e8g8": self = .bK
    case "e8c8": self = .bQ
    default: return nil
    }
  }

}
